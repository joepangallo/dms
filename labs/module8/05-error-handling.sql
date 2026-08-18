-- ======================================================================
-- Module 8 · Error Handling
-- ======================================================================
--
-- Sections: 8-5
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-5  Error Handling
-- ----------------------------------------------------------------------


-- Example 8-5.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE: makes the script re-runnable. Without it, the second run
--   fails because the procedure already exists.
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE_UNSAFE //

-- CREATE PROCEDURE: written the obvious way, with no error handling at all -
--   which is exactly what makes it unsafe.
CREATE PROCEDURE GET_CUST_BALANCE_UNSAFE(
    IN  i_customer_num CHAR(4),
    OUT o_balance      DECIMAL(9,2))
BEGIN

    -- SELECT ... INTO: fine when the customer exists. When it does not, the
    --   SELECT finds no row, MySQL raises a NOT FOUND warning rather than an
    --   error, and o_balance is left holding whatever it held before. The caller
    --   is never told that anything went wrong.
    SELECT BALANCE
    INTO   o_balance
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;
END //

DELIMITER ;

-- Example 8-5.2
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SET: clear the variable so the next result is unambiguous.
SET @bal = 0;

-- CALL: a customer that exists. The balance comes back correctly.
CALL GET_CUST_BALANCE_UNSAFE('1120', @bal);

-- SELECT: reads back @bal, the correct balance for a customer that exists.
SELECT @bal AS BALANCE_FOUND;

-- CALL: a customer that does NOT exist. No error is raised.
CALL GET_CUST_BALANCE_UNSAFE('9999', @bal);

-- SHOW WARNINGS: the only evidence that anything happened - a NOT FOUND warning
--   that a program would have to go looking for.
SHOW WARNINGS;

-- SELECT: the variable still holds the PREVIOUS customer's balance, now being
--   reported as if it belonged to customer 9999. A wrong answer, silently.
SELECT @bal AS BALANCE_FOUND;

-- Example 8-5.3
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE: same reason as before - without it, re-running the script
--   fails because the procedure already exists.
DROP PROCEDURE IF EXISTS STALE_DEMO //

-- CREATE PROCEDURE: the same trap, made even easier to fall into by using INOUT.
CREATE PROCEDURE STALE_DEMO(
    IN    i_customer_num CHAR(4),

    -- INOUT means the parameter arrives holding the caller's old value, so a
    --   failed lookup leaves that stale value sitting in place.
    INOUT io_balance     DECIMAL(9,2))
BEGIN

    -- No handler, so a miss changes nothing and says nothing.
    SELECT BALANCE
    INTO   io_balance
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;
END //

DELIMITER ;

-- Example 8-5.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SET: reset @bal so a leftover value from the previous demo can't be
--   mistaken for real output.
SET @bal = 0;

-- CALL: a real customer, so the variable is filled correctly.
CALL STALE_DEMO('1120', @bal);

-- SELECT: reads back @bal, filled in correctly for a customer that exists.
SELECT @bal AS BALANCE_FOUND;

-- CALL: a customer that does not exist.
CALL STALE_DEMO('9999', @bal);

-- SELECT: the previous customer's balance is still there, and nothing in the
--   output distinguishes a real answer from a leftover one. This is why a
--   procedure must report what happened, not just what it found.
SELECT @bal AS BALANCE_FOUND;

-- Example 8-5.5
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE: clears out any earlier version so the script can run again.
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE //

-- CREATE PROCEDURE: the safe version of the lookup.
CREATE PROCEDURE GET_CUST_BALANCE(
    IN  i_customer_num CHAR(4),
    OUT o_balance      DECIMAL(9,2),

    -- A second OUT parameter carrying a plain-language status, so the caller
    --   learns what happened as well as what was found.
    OUT o_status       VARCHAR(60))
BEGIN

    -- DECLARE ... HANDLER: registers what to do when a condition arises. CONTINUE
    --   means "run this, then carry on with the next statement"; NOT FOUND is the
    --   condition raised when a SELECT ... INTO matches no row.
    DECLARE CONTINUE HANDLER FOR NOT FOUND

        -- CONCAT builds a message that names the customer that was missing.
        SET o_status = CONCAT('No customer numbered ', i_customer_num);

    -- Set the OUT parameters to known values BEFORE the lookup, so nothing stale
    --   can survive. This line is what kills the previous example's bug.
    SET o_balance = NULL;

    -- The optimistic default, overwritten by the handler if the lookup misses.
    SET o_status  = 'OK';

    -- The lookup itself. If it finds nothing, the handler fires and o_status
    --   changes; if it succeeds, o_status stays 'OK'.
    SELECT BALANCE
    INTO   o_balance
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;
END //

DELIMITER ;

-- Example 8-5.6
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: a customer that exists - balance filled in, status 'OK'.
CALL GET_CUST_BALANCE('1120', @bal, @status);

-- SELECT: reads @bal and @status back through the session variables the
--   CALL wrote to.
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;

-- CALL: a customer that does not - balance NULL, status explaining why. The
--   caller can now tell the two cases apart without guessing.
CALL GET_CUST_BALANCE('9999', @bal, @status);

-- SELECT: same read-back, now showing the NULL balance and the handler's
--   status message.
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;

-- Example 8-5.7
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE: re-runnable script, same reasoning as the earlier examples.
DROP PROCEDURE IF EXISTS GET_BALANCE_BY_CITY //

-- CREATE PROCEDURE: this one looks up on a NON-key column, which is where the
--   other failure mode lives - too many rows rather than none.
CREATE PROCEDURE GET_BALANCE_BY_CITY(
    IN  i_city    VARCHAR(20),
    OUT o_balance DECIMAL(9,2),
    OUT o_status  VARCHAR(60))
BEGIN

    -- DECLARE EXIT HANDLER: EXIT means "run this, then STOP the procedure" -
    --   unlike CONTINUE, nothing after the failing statement runs. SQLEXCEPTION
    --   catches any error, including a SELECT ... INTO that matched several rows.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION

        -- CONCAT builds a message that names the city where the lookup failed.
        SET o_status = CONCAT('Lookup failed for ', i_city, ' - check the city');

    -- Known starting values again.
    SET o_balance = NULL;

    -- The optimistic default, overwritten by the EXIT handler if SQLEXCEPTION
    --   fires.
    SET o_status  = 'OK';

    -- One city holds one customer and works; another holds two, the INTO cannot
    --   choose between them, and the EXIT handler takes over.
    SELECT BALANCE
    INTO   o_balance
    FROM   CUSTOMER
    WHERE  CITY = i_city;
END //

DELIMITER ;

-- Example 8-5.8
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: Northfield has exactly one customer, so the lookup succeeds.
CALL GET_BALANCE_BY_CITY('Northfield', @bal, @status);

-- SELECT: reads back @bal and @status - the balance found, and status 'OK'.
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;

-- CALL: Maple Grove has two, so SELECT ... INTO fails and the EXIT handler
--   reports it instead of returning one of the two at random.
CALL GET_BALANCE_BY_CITY('Maple Grove', @bal, @status);

-- SELECT: reads back @bal and @status - NULL balance, and the message the
--   EXIT handler set.
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;
