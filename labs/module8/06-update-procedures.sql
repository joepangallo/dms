-- ======================================================================
-- Module 8 · Using Update Procedures
-- ======================================================================
--
-- Sections: 8-6
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-6  Using Update Procedures
-- ----------------------------------------------------------------------


-- Example 8-6.1
-- The accident. Read it, do not run it: every worked example below
-- assumes the shipped balances are still intact.
-- UPDATE: the table.
UPDATE CUSTOMER

-- SET with no WHERE: every customer's balance goes up by 250. The statement is
--   perfectly valid SQL, which is precisely the danger - wrapping this logic in
--   a procedure that always carries its own WHERE clause is how you stop a
--   missing line from reaching production.
SET    BALANCE = BALANCE + 250.00;

-- Example 8-6.2
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: makes the script re-runnable - without it, the
--   second run fails because UPD_CUST_BALANCE already exists.
DROP PROCEDURE IF EXISTS UPD_CUST_BALANCE //

-- CREATE PROCEDURE: an UPDATE wrapped safely, so the WHERE clause can never be
--   forgotten and a missing customer is reported rather than ignored.
CREATE PROCEDURE UPD_CUST_BALANCE(
    IN  i_customer_num CHAR(4),
    IN  i_amount       DECIMAL(9,2),
    OUT o_status       VARCHAR(60))
BEGIN

    -- A local to hold the customer's name, used in the status message.
    DECLARE v_name VARCHAR(35);

    -- EXIT HANDLER FOR NOT FOUND: if the customer does not exist, stop before the
    --   UPDATE ever runs and say so. EXIT rather than CONTINUE is deliberate.
    DECLARE EXIT HANDLER FOR NOT FOUND
        SET o_status = CONCAT('No customer numbered ', i_customer_num, ' - nothing changed');

    -- The lookup does double duty: it fetches the name AND proves the customer
    --   exists. A miss here fires the handler and the procedure ends.
    SELECT CUSTOMER_NAME
    INTO   v_name
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- The change itself, reached only when the customer is known to exist.
    UPDATE CUSTOMER

    -- SET: adds the caller's i_amount to the customer's current balance.
    SET    BALANCE = BALANCE + i_amount

    -- The WHERE clause is written into the procedure once and cannot be left off
    --   by a caller in a hurry.
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- Report exactly what was done, naming the customer and the amount.
    SET o_status = CONCAT('Balance for ', v_name, ' changed by ', i_amount);
END //

DELIMITER ;

-- Example 8-6.3
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: a real customer. The status names them and the amount.
CALL UPD_CUST_BALANCE('1120', 250.00, @status);

-- SELECT: reads back the status message the successful call set.
SELECT @status AS STATUS;

-- SELECT: proof that exactly one row moved and the other three did not.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE FROM CUSTOMER ORDER BY CUSTOMER_NUM;

-- CALL: a customer that does not exist. The handler stops the procedure before
--   the UPDATE, so nothing at all is changed and the caller is told why.
CALL UPD_CUST_BALANCE('9999', 250.00, @status);

-- SELECT: reads back the status message explaining why nothing changed.
SELECT @status AS STATUS;

-- Example 8-6.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: same re-runnability guard, now for SHIP_ITEM.
DROP PROCEDURE IF EXISTS SHIP_ITEM //

-- CREATE PROCEDURE: a procedure that changes data inside a transaction, with two
--   different handlers for two different kinds of failure.
CREATE PROCEDURE SHIP_ITEM(
    IN  i_item_id     CHAR(4),
    IN  i_qty_shipped SMALLINT,
    OUT o_status      VARCHAR(60))
BEGIN
    -- A local to hold the item's description, used in the success message.
    DECLARE v_description VARCHAR(30);

    -- EXIT HANDLER FOR SQLEXCEPTION with a BEGIN ... END block: a handler can run
    --   several statements, not just one, when it is wrapped like this.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN

        -- ROLLBACK first: undo any half-finished change before reporting.
        ROLLBACK;

        -- SET: reports the failure back through the status parameter.
        SET o_status = 'Shipment failed - stock left unchanged';
    END;

    -- A second handler for a different condition. NOT FOUND is not an error, so
    --   it needs its own handler; SQLEXCEPTION would never catch it.
    DECLARE EXIT HANDLER FOR NOT FOUND
        SET o_status = CONCAT('No item numbered ', i_item_id);

    -- Look up the item, which also proves it exists before anything is changed.
    SELECT DESCRIPTION
    INTO   v_description
    FROM   ITEM
    WHERE  ITEM_ID = i_item_id;

    -- START TRANSACTION: open the safety net around the change.
    START TRANSACTION;

    -- The change itself.
    UPDATE ITEM

    -- SET: reduces on-hand stock by the quantity shipped.
    SET    ON_HAND = ON_HAND - i_qty_shipped

    -- WHERE: the same one-row guarantee - only this item's stock changes.
    WHERE  ITEM_ID = i_item_id;

    -- COMMIT: reached only if the UPDATE raised nothing. If it had, the
    --   SQLEXCEPTION handler would have rolled back and ended the procedure
    --   before this line.
    COMMIT;

    -- The success message, built from the description looked up earlier.
    SET o_status = CONCAT('Shipped ', i_qty_shipped, ' of ', v_description);
END //

DELIMITER ;

-- Example 8-6.5
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: a real item. Stock falls by three and the status says so.
CALL SHIP_ITEM('CF21', 3, @status);

-- SELECT: reads back the status message confirming the shipment.
SELECT @status AS STATUS;

-- SELECT: confirm the new stock figure.
SELECT ITEM_ID, DESCRIPTION, ON_HAND FROM ITEM WHERE ITEM_ID = 'CF21';

-- CALL: an item id that does not exist. The NOT FOUND handler stops the
--   procedure before the transaction is even opened.
CALL SHIP_ITEM('ZZ99', 1, @status);

-- SELECT: reads back the status message explaining why nothing shipped.
SELECT @status AS STATUS;

-- Example 8-6.6
-- The accident. Read it, do not run it.
-- DELETE with no WHERE: every customer row is removed in one statement. Nothing
--   warns you, and outside a transaction nothing brings them back. This is the
--   statement the procedure below exists to make impossible.
DELETE FROM CUSTOMER;

-- Example 8-6.7
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: and again for DEL_CUSTOMER, so this script can run
--   more than once.
DROP PROCEDURE IF EXISTS DEL_CUSTOMER //

-- CREATE PROCEDURE: a delete that can only ever remove one named row, and that
--   explains itself whichever way it ends.
CREATE PROCEDURE DEL_CUSTOMER(
    IN  i_customer_num CHAR(4),
    OUT o_status       VARCHAR(70))
BEGIN
    -- A local to hold the customer's name, used later in the status message.
    DECLARE v_name VARCHAR(35);

    -- Handler 1 - an actual error. The likeliest one here is a foreign key
    --   violation: the customer still has invoices pointing at it.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        SET o_status = CONCAT('Could not delete ', i_customer_num, ' - invoices still reference it');

    -- Handler 2 - not an error at all, just nothing found. Two conditions, two
    --   handlers, two different messages.
    DECLARE EXIT HANDLER FOR NOT FOUND
        SET o_status = CONCAT('No customer numbered ', i_customer_num);

    -- Fetch the name, and in doing so confirm the customer exists.
    SELECT CUSTOMER_NAME
    INTO   v_name
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- The delete, with its WHERE clause built in permanently.
    DELETE FROM CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- Reached only when the delete succeeded.
    SET o_status = CONCAT('Deleted ', v_name);
END //

DELIMITER ;

-- Example 8-6.8
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: a customer with no invoices - the delete succeeds.
CALL DEL_CUSTOMER('1310', @status);

-- SELECT: reads back the status message confirming the delete.
SELECT @status AS STATUS;

-- CALL: a customer that DOES have invoices. The foreign key refuses the delete,
--   the SQLEXCEPTION handler catches it, and the row survives.
CALL DEL_CUSTOMER('1120', @status);

-- SELECT: reads back the status message explaining the foreign key refusal.
SELECT @status AS STATUS;

-- CALL: a customer that never existed. The NOT FOUND handler answers this one.
CALL DEL_CUSTOMER('9999', @status);

-- SELECT: reads back the status message for the missing customer.
SELECT @status AS STATUS;

-- SELECT: three outcomes, and the table shows exactly one row gone.
SELECT CUSTOMER_NUM, CUSTOMER_NAME FROM CUSTOMER ORDER BY CUSTOMER_NUM;

-- Example 8-6.9
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- INSERT INTO with no column list: put the deleted customer back, supplying a
--   value for all nine columns in the table's own order. This is the tidy-up
--   step, so the rest of the module works against the shipped data.
INSERT INTO CUSTOMER
VALUES ('1310', 'Companion Care Clinic', '89 River Rd.', 'Maple Grove', 'OH',
        '44601', 0.00, 10000.00, '20');

-- Example 8-6.10
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CREATE USER IF NOT EXISTS: make the account, skipping quietly if it is already
--   there. MySQL identifies accounts as user@host.
CREATE USER IF NOT EXISTS 'billing_clerk'@'localhost' IDENTIFIED BY 'change_me';

-- GRANT EXECUTE ON PROCEDURE: the clerk may RUN the procedure. Notice what is not
--   granted - no DELETE on CUSTOMER at all, so the only way this account can
--   remove a customer is through the procedure, with all its checks in place.
GRANT EXECUTE ON PROCEDURE KIMTAY.DEL_CUSTOMER TO 'billing_clerk'@'localhost';

-- GRANT SELECT: read access to the table, so the clerk can see the list. Reading
--   and deleting are separate privileges, and only one of them is given here.
GRANT SELECT ON KIMTAY.CUSTOMER TO 'billing_clerk'@'localhost';

-- Example 8-6.11
-- UPDATE: restore the balance the worked examples changed, so the shipped data
--   is back where it started.
UPDATE CUSTOMER SET BALANCE = 3512.50 WHERE CUSTOMER_NUM = '1120';

-- UPDATE: and the stock figure the SHIP_ITEM example reduced.
UPDATE ITEM     SET ON_HAND = 48      WHERE ITEM_ID = 'CF21';

-- Example 8-6.12
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DROP PROCEDURE IF EXISTS: clean up every procedure this lesson created. IF
--   EXISTS on each line means the whole script runs to the end even if some of
--   them were never created or have already been dropped.
DROP PROCEDURE IF EXISTS SHOW_REP_COUNT;
DROP PROCEDURE IF EXISTS BAD_REP_NAME;
DROP PROCEDURE IF EXISTS DISP_REP_NAME;
DROP PROCEDURE IF EXISTS GET_CREDIT_AVAILABLE;
DROP PROCEDURE IF EXISTS ADD_SALE_TO_COMMISSION;
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE_UNSAFE;
DROP PROCEDURE IF EXISTS STALE_DEMO;
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE;
DROP PROCEDURE IF EXISTS GET_BALANCE_BY_CITY;
DROP PROCEDURE IF EXISTS UPD_CUST_BALANCE;
DROP PROCEDURE IF EXISTS SHIP_ITEM;
DROP PROCEDURE IF EXISTS DEL_CUSTOMER;
