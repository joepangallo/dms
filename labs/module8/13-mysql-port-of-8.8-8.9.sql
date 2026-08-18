-- ======================================================================
-- Module 8 · MySQL translations of the Oracle PL/SQL (8-8) and
--             T-SQL/SQL Server (8-9) procedure and cursor examples
-- ======================================================================
--
-- HAND-WRITTEN, NOT REGENERATED. Every other numbered file in this folder
-- is produced by tools/gen-module-labs.py straight from db.html, and a
-- re-run of that script reproduces them byte for byte. This file is not
-- sourced from the page at all -- it exists because 08-plsql-oracle.sql
-- and 09-tsql-sql-server.sql are, on purpose, code that only runs on
-- Oracle and SQL Server. This is what the same procedures look like
-- written the way section 8-4/8-5/8-7's own MySQL material already does.
-- Editing gen-module-labs.py and re-running it will NOT touch this file,
-- and re-running it will not regenerate this one either -- keep it by
-- hand.
--
-- Every procedure below was written and CALLed against a real MySQL 9.7
-- server in this session -- not merely reasoned about. Load
-- 00-setup-both.sql first; everything here reads and writes the same
-- KimTay tables 08-plsql-oracle.sql and 09-tsql-sql-server.sql use.
--
-- Two CALLs in section 8-8's ADD_TO_BALANCE block are marked
-- INTENTIONALLY INVALID, the same convention Modules 4, 5, and 8 use
-- elsewhere: they are business-rule rejections the procedure is written
-- to raise, and MySQL's CLI (unlike sqlite3's) stops at the first error
-- by default. Run this file with `mysql --force` (or `mysql -f`) to see
-- every statement in one pass; without it, the two marked CALLs are
-- exactly where a plain `mysql < 13-mysql-port-of-8.8-8.9.sql` will stop.
--
-- Four things MySQL does differently from Oracle and T-SQL here:
--
-- 1. Oracle's NO_DATA_FOUND / T-SQL's @@ROWCOUNT-and-test both become a
--    DECLARE ... HANDLER FOR NOT FOUND in MySQL -- a handler registered
--    up front, the same shape 05-error-handling.sql already teaches,
--    rather than a value checked after the fact.
-- 2. Oracle names the too-many-rows case TOO_MANY_ROWS and gives it its
--    own WHEN clause. MySQL raises error 1172 ("Result consisted of more
--    than one row") but does not name it separately -- it falls under
--    the general SQLEXCEPTION handler, the same way 08-plsql-oracle.sql's
--    own commentary predicts ("MySQL lumps it under SQLEXCEPTION").
-- 3. Oracle's self-declared named exception (OVER_LIMIT EXCEPTION;) and
--    T-SQL's THROW both become SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT
--    = '...' in MySQL -- there is no way to declare and RAISE a
--    business-rule exception by name the way Oracle does. RESIGNAL
--    inside a handler is what forwards the message to the caller after
--    a ROLLBACK, standing in for Oracle's RAISE_APPLICATION_ERROR and
--    T-SQL's PRINT ERROR_MESSAGE() combined.
-- 4. Oracle's cursor FOR loop (Example 8-8.7) auto-declares its loop
--    record, opens, fetches, tests, and closes the cursor with no code
--    of its own. MySQL has no such shorthand -- every cursor here needs
--    the full DECLARE CURSOR / OPEN / FETCH / LOOP / CLOSE, the same
--    length as Oracle's OWN longer form in Example 8-8.6.
--
-- One thing neither engine's translation can paper over: T-SQL's
-- updatable cursor (Example 8-9.15, WHERE CURRENT OF) has no MySQL
-- equivalent at all -- MySQL does not support positioned UPDATE/DELETE
-- against a cursor. BUMP_HABITAT_STOCK below fetches each row's key
-- instead and updates by key, which is the only substitute MySQL has.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-8 / 8-9  --  GET_CUSTOMER
-- Oracle original: 08-plsql-oracle.sql, Example 8-8.2
-- T-SQL original:  09-tsql-sql-server.sql, Example 8-9.1
-- ----------------------------------------------------------------------

DELIMITER //

-- DROP PROCEDURE: re-runnable script, same reasoning as every MySQL
--   example elsewhere in this module.
DROP PROCEDURE IF EXISTS GET_CUSTOMER //

-- CREATE PROCEDURE: MySQL puts the direction (IN) before the parameter
--   name, unlike Oracle's I_CUSTOMER_NUM IN CHAR or T-SQL's bare
--   @I_CUSTOMER_NUM with no direction keyword at all.
CREATE PROCEDURE GET_CUSTOMER (IN i_customer_num CHAR(4))
BEGIN

    -- DECLARE, with the type written out in full -- MySQL has no %TYPE
    --   the way Oracle does.
    DECLARE v_name    VARCHAR(35);
    DECLARE v_balance DECIMAL(9,2);

    -- NOT FOUND: MySQL's condition for a SELECT ... INTO that matched
    --   zero rows -- Oracle's NO_DATA_FOUND, T-SQL's @@ROWCOUNT = 0.
    DECLARE EXIT HANDLER FOR NOT FOUND
        SELECT CONCAT('No customer numbered ', i_customer_num) AS MESSAGE;

    -- SQLEXCEPTION: catches error 1172 if the SELECT ... INTO ever
    --   matched more than one row -- Oracle's separately-named
    --   TOO_MANY_ROWS, folded into MySQL's general handler.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        SELECT 'That condition matched more than one customer.' AS MESSAGE;

    -- SELECT ... INTO fills the two locals, exactly as in the Oracle and
    --   T-SQL originals.
    SELECT CUSTOMER_NAME, BALANCE
    INTO   v_name, v_balance
    -- FROM: the customer table this lookup reads.
    FROM   CUSTOMER
    -- WHERE: filters to the one row this call targets.
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- MySQL has no print statement, so output is produced by SELECTing
    --   the variables, same as Example 8-8.1's MySQL comparison block.
    SELECT v_name AS CUSTOMER_NAME, v_balance AS BALANCE;
END //

DELIMITER ;

-- CALL: one row comes back -- the case the procedure was written for.
CALL GET_CUSTOMER('1225');  -- Downtown Aquarium & Pets, 1200.00

-- CALL: no row comes back -- the NOT FOUND handler fires.
CALL GET_CUSTOMER('1999');  -- 'No customer numbered 1999'


-- ----------------------------------------------------------------------
-- Section 8-8 / 8-9  --  ADD_TO_BALANCE
-- Oracle original: 08-plsql-oracle.sql, Example 8-8.4
-- T-SQL original:  09-tsql-sql-server.sql, Example 8-9.4
-- ----------------------------------------------------------------------

DELIMITER //

DROP PROCEDURE IF EXISTS ADD_TO_BALANCE //

-- CREATE PROCEDURE: a procedure that changes data and refuses to leave
--   the database in a state it considers invalid, same as both originals.
CREATE PROCEDURE ADD_TO_BALANCE (
    IN i_customer_num CHAR(4),
    IN i_amount       DECIMAL(9,2))
BEGIN
    DECLARE v_balance DECIMAL(9,2);
    DECLARE v_limit   DECIMAL(9,2);

    -- EXIT HANDLER FOR SQLEXCEPTION: MySQL has no named OVER_LIMIT
    --   exception the way Oracle does, and no BEGIN CATCH block the way
    --   T-SQL does -- one general handler covers both of this
    --   procedure's own SIGNALs below. ROLLBACK undoes the UPDATE;
    --   RESIGNAL re-raises the same condition so the caller still sees
    --   the message, the way T-SQL's PRINT ERROR_MESSAGE() and Oracle's
    --   RAISE_APPLICATION_ERROR both report back to the caller.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- START TRANSACTION: everything up to COMMIT can still be undone,
    --   same as Oracle's implicit transaction and T-SQL's explicit
    --   BEGIN TRANSACTION.
    START TRANSACTION;

    -- The change is made first, then checked -- same order as both
    --   originals.
    UPDATE CUSTOMER
    -- SET: adds the signed amount to the current balance.
    SET    BALANCE = BALANCE + i_amount
    -- WHERE: targets only the customer named by the parameter.
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- ROW_COUNT(): MySQL's equivalent of Oracle's SQL%ROWCOUNT and
    --   T-SQL's @@ROWCOUNT -- how many rows the last statement touched.
    IF ROW_COUNT() = 0 THEN

        -- SIGNAL SQLSTATE '45000': MySQL's generic user-defined
        --   exception state, standing in for Oracle's RAISE NO_DATA_FOUND
        --   and T-SQL's THROW 50001.
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No customer with that number.';
    END IF;

    -- Read the row back to see what the update actually produced.
    SELECT BALANCE, CREDIT_LIMIT
    INTO   v_balance, v_limit
    -- FROM: the same customer table the UPDATE just changed.
    FROM   CUSTOMER
    -- WHERE: the same customer the UPDATE targeted.
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- The business rule. Nothing in the database forbids this, so the
    --   procedure enforces it, same as both originals.
    IF v_balance > v_limit THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'That charge would push the balance past the credit limit.';
    END IF;

    -- COMMIT: reached only when both checks passed.
    COMMIT;
END //

DELIMITER ;

-- CALL: a customer that exists, an amount that stays under the limit --
--   the update commits.
CALL ADD_TO_BALANCE('1225', 350.00);
SELECT CUSTOMER_NUM, BALANCE, CREDIT_LIMIT FROM CUSTOMER WHERE CUSTOMER_NUM = '1225';
-- 1225 | 1550.00 | 5000.00

-- Put the balance back to its seeded value so this file can be run again.
UPDATE CUSTOMER SET BALANCE = 1200.00 WHERE CUSTOMER_NUM = '1225';

-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: an amount that would push 1225 over its 5000.00 limit. SIGNAL
--   raises 'That charge would push the balance past the credit limit.',
--   the EXIT HANDLER rolls the UPDATE back, and RESIGNAL sends the same
--   message on to the client as ERROR 1644 (45000). Verified: the SELECT
--   right after shows the balance untouched at 1200.00, not the
--   half-applied 6200.00 the UPDATE alone would have left behind.
CALL ADD_TO_BALANCE('1225', 5000.00);
SELECT CUSTOMER_NUM, BALANCE FROM CUSTOMER WHERE CUSTOMER_NUM = '1225';
-- 1225 | 1200.00 -- unchanged

-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: no customer numbered 9999. ROW_COUNT() = 0 after the UPDATE
--   matches nothing, so the first SIGNAL fires with ERROR 1644 (45000).
CALL ADD_TO_BALANCE('9999', 10.00);


-- ----------------------------------------------------------------------
-- Section 8-8  --  REP_CUSTOMER_LIST
-- Oracle original: 08-plsql-oracle.sql, Examples 8-8.6 and 8-8.7
-- T-SQL original:  09-tsql-sql-server.sql, Example 8-9.11
-- ----------------------------------------------------------------------

DELIMITER //

DROP PROCEDURE IF EXISTS REP_CUSTOMER_LIST //

-- CREATE PROCEDURE: the cursor loop, in the same shape
--   07-selecting-multiple-rows.sql's REP_CREDIT_REVIEW already uses --
--   MySQL has nothing like Oracle's shorthand cursor FOR loop
--   (Example 8-8.7), so this explicit form is as short as MySQL gets.
CREATE PROCEDURE REP_CUSTOMER_LIST (IN i_rep_num CHAR(2))
BEGIN

    -- The finished flag, starting at 0 -- MySQL's substitute for Oracle's
    --   %NOTFOUND and T-SQL's @@FETCH_STATUS, both tested directly.
    DECLARE v_done INT DEFAULT 0;

    -- One variable per cursor column.
    DECLARE v_customer_num  CHAR(4);
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_balance       DECIMAL(9,2);

    -- DECLARE ... CURSOR FOR: MySQL's cursor declaration -- Oracle says
    --   CURSOR CUSTGROUP IS, T-SQL says DECLARE CUSTGROUP CURSOR FOR.
    DECLARE custgroup CURSOR FOR
        -- SELECT: the three columns each FETCH below copies into the
        --   loop's variables, in this order.
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
        -- FROM: the same customer table both originals query.
        FROM   CUSTOMER
        -- WHERE: the parameter stands in for the literal '20' the
        --   sandbox exercises use.
        WHERE  REP_NUM = i_rep_num
        -- ORDER BY: keeps the rows in customer-number order as fetched.
        ORDER BY CUSTOMER_NUM;

    -- The handler that trips the flag when the rows run out.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- Run the query and position before the first row.
    OPEN custgroup;

    -- A labeled LOOP, exited by the test inside -- MySQL has no EXIT
    --   WHEN the way Oracle does.
    custloop: LOOP

        -- Read one row into the three variables.
        FETCH custgroup INTO v_customer_num, v_customer_name, v_balance;

        -- Stop as soon as the fetch fails, before processing stale
        --   values.
        IF v_done THEN
            LEAVE custloop;
        END IF;

        -- The work for this row: MySQL has no print statement, so a
        --   SELECT per row stands in for Oracle's DBMS_OUTPUT.PUT_LINE
        --   and T-SQL's PRINT.
        SELECT v_customer_num AS CUSTOMER_NUM, v_customer_name AS CUSTOMER_NAME,
               v_balance AS BALANCE;
    END LOOP custloop;

    -- Release the cursor.
    CLOSE custgroup;
END //

DELIMITER ;

-- CALL: two rows come back, in this order -- 1120 Access Pet Center
--   and 1310 Companion Care Clinic. Matches the sandbox hint's own
--   claim about REP_NUM = '20' exactly.
CALL REP_CUSTOMER_LIST('20');


-- ----------------------------------------------------------------------
-- Section 8-9  --  DELETE_ITEM
-- T-SQL original: 09-tsql-sql-server.sql, Example 8-9.7
-- No Oracle original -- this example is T-SQL only.
-- ----------------------------------------------------------------------

DELIMITER //

DROP PROCEDURE IF EXISTS DELETE_ITEM //

-- CREATE PROCEDURE: a delete that reports all three of its possible
--   outcomes, same as the T-SQL original's BEGIN TRY / BEGIN CATCH pair.
CREATE PROCEDURE DELETE_ITEM (IN i_item_id CHAR(4))
BEGIN

    -- SQLEXCEPTION: MySQL's foreign-key violation on DELETE is error
    --   1451 -- caught here the same general way T-SQL's CATCH block
    --   catches it, just without a name for "the delete was refused"
    --   the way T-SQL's ERROR_MESSAGE() supplies one.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        SELECT CONCAT('Could not delete ', i_item_id,
                       ': still referenced by an invoice line.') AS MESSAGE;

    -- The delete, with its WHERE clause built into the procedure.
    DELETE FROM ITEM
    -- WHERE: the one item number the caller passed in.
    WHERE  ITEM_ID = i_item_id;

    -- Outcome 1: nothing matched. Not an error, so it is detected by the
    --   count, same as T-SQL's @@ROWCOUNT test.
    IF ROW_COUNT() = 0 THEN
        SELECT CONCAT('No item numbered ', i_item_id, '. Nothing was deleted.') AS MESSAGE;
    -- Outcome 2: the row was removed.
    ELSE
        SELECT CONCAT('Item ', i_item_id, ' deleted.') AS MESSAGE;
    END IF;
END //

DELIMITER ;

-- CALL: DG04 appears on an invoice line, so the foreign key refuses the
--   delete and the handler explains why. The item survives.
CALL DELETE_ITEM('DG04');

-- CALL: no item numbered ZZ99.
CALL DELETE_ITEM('ZZ99');


-- ----------------------------------------------------------------------
-- Section 8-9  --  REP_INVOICE_LINES
-- T-SQL original: 09-tsql-sql-server.sql, Example 8-9.13
-- No Oracle original -- this example is T-SQL only.
-- ----------------------------------------------------------------------

DELIMITER //

DROP PROCEDURE IF EXISTS REP_INVOICE_LINES //

-- CREATE PROCEDURE: a cursor over a four-table join, keeping a running
--   total as it goes -- something a single SELECT cannot do as it walks.
CREATE PROCEDURE REP_INVOICE_LINES (IN i_rep_num CHAR(2))
BEGIN
    DECLARE v_done INT DEFAULT 0;

    -- One variable per cursor column.
    DECLARE v_invoice_num   CHAR(5);
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_description   VARCHAR(30);
    DECLARE v_line_total    DECIMAL(9,2);

    -- The accumulator, starting at 0 rather than NULL -- NULL + anything
    --   is NULL, so the total would never build, same reason the T-SQL
    --   original's own comment gives.
    DECLARE v_running_total DECIMAL(9,2) DEFAULT 0;

    -- The cursor: three stored columns and one calculated one, across
    --   four tables -- unchanged from the T-SQL original.
    DECLARE linegroup CURSOR FOR
        -- SELECT: the calculated column (NUM_ORDERED * QUOTED_PRICE) is
        --   what v_line_total receives below.
        SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION,
               IL.NUM_ORDERED * IL.QUOTED_PRICE
        -- FROM: CUSTOMER is the base table each hop below joins outward
        --   from.
        FROM   CUSTOMER C
               -- Hop 1 - customer to invoice.
               JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
               -- Hop 2 - invoice to line item.
               JOIN INVOICE_LINE IL ON I.INVOICE_NUM  = IL.INVOICE_NUM
               -- Hop 3 - line item to item.
               JOIN ITEM IT         ON IL.ITEM_ID     = IT.ITEM_ID
        -- WHERE: limits the join to the rep's own customers.
        WHERE  C.REP_NUM = i_rep_num
        -- ORDER BY: invoice first, then description within it.
        ORDER BY I.INVOICE_NUM, IT.DESCRIPTION;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- OPEN: runs the four-table query and positions before the first row.
    OPEN linegroup;

    lineloop: LOOP

        -- Read one row into the four variables.
        FETCH linegroup INTO v_invoice_num, v_customer_name, v_description, v_line_total;

        IF v_done THEN
            LEAVE lineloop;
        END IF;

        -- Add this row's total to the accumulator.
        SET v_running_total = v_running_total + v_line_total;

        -- The detail line for this row.
        SELECT v_invoice_num AS INVOICE_NUM, v_customer_name AS CUSTOMER_NAME,
               v_description AS DESCRIPTION, v_line_total AS LINE_TOTAL;
    END LOOP lineloop;

    -- Release the cursor.
    CLOSE linegroup;

    -- The grand total, printed once after the loop.
    SELECT CONCAT('Total for rep ', i_rep_num, ': ', v_running_total) AS GRAND_TOTAL;
END //

DELIMITER ;

-- CALL: two lines on invoice 50710 for Access Pet Center -- 127.50 and
--   23.98 -- then the grand total, 151.48. Matches Exercise 35's own
--   SUM(NUM_ORDERED * QUOTED_PRICE) result exactly.
CALL REP_INVOICE_LINES('20');


-- ----------------------------------------------------------------------
-- Section 8-9  --  the updatable cursor (BUMP_HABITAT_STOCK)
-- T-SQL original: 09-tsql-sql-server.sql, Example 8-9.15
-- No Oracle original -- this example is T-SQL only.
-- ----------------------------------------------------------------------
--
-- MySQL has no equivalent to T-SQL's FOR UPDATE OF / WHERE CURRENT OF --
-- there is no way to update "the row this cursor is sitting on" by
-- position at all. The substitute is the one the T-SQL original's own
-- comment already points at: fetch the row's key, then issue an
-- ordinary UPDATE keyed on it. And, as that same comment admits, a
-- single UPDATE ITEM SET ON_HAND = ON_HAND + 10 WHERE CATEGORY =
-- 'Habitat' does the same job in one statement, far more quickly -- the
-- cursor was never actually necessary, on either engine.

DELIMITER //

DROP PROCEDURE IF EXISTS BUMP_HABITAT_STOCK //

CREATE PROCEDURE BUMP_HABITAT_STOCK ()
BEGIN
    DECLARE v_done INT DEFAULT 0;

    -- @L_ITEM_ID / @L_ON_HAND in the T-SQL original -- the key and the
    --   quantity column this cursor is about to update.
    DECLARE v_item_id CHAR(4);
    DECLARE v_on_hand SMALLINT;

    -- DECLARE ... CURSOR FOR: no FOR UPDATE OF clause here -- MySQL
    --   cursors have nothing to opt into, because positioned updates
    --   are not on offer either way.
    DECLARE itemgroup CURSOR FOR
        -- SELECT: the item id and the quantity the loop will adjust.
        SELECT ITEM_ID, ON_HAND
        -- FROM: the item table this cursor updates.
        FROM   ITEM
        -- WHERE: limits the cursor to the Habitat category -- the two
        --   items the loop below will touch.
        WHERE  CATEGORY = 'Habitat';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN itemgroup;

    itemloop: LOOP
        FETCH itemgroup INTO v_item_id, v_on_hand;
        IF v_done THEN
            LEAVE itemloop;
        END IF;

        -- The update this cursor exists to make -- to the row it just
        --   fetched, keyed by ITEM_ID rather than by cursor position.
        UPDATE ITEM
        -- SET: increases ON_HAND by 10 for that row.
        SET    ON_HAND = ON_HAND + 10
        -- WHERE: the row's own primary key, read from the cursor a
        --   moment ago -- MySQL's only way to target "this row".
        WHERE  ITEM_ID = v_item_id;
    END LOOP itemloop;

    CLOSE itemgroup;
END //

DELIMITER ;

-- Before: AV07 15, FT88 30.
SELECT ITEM_ID, ON_HAND FROM ITEM WHERE CATEGORY = 'Habitat' ORDER BY ITEM_ID;

CALL BUMP_HABITAT_STOCK();

-- After: AV07 25, FT88 40 -- both up by 10.
SELECT ITEM_ID, ON_HAND FROM ITEM WHERE CATEGORY = 'Habitat' ORDER BY ITEM_ID;

-- Put both items back to their seeded ON_HAND so this file can be run
--   again with the same results.
UPDATE ITEM SET ON_HAND = ON_HAND - 10 WHERE CATEGORY = 'Habitat';


-- ======================================================================
-- Clean-up -- drop every routine this file created. Left commented, the
-- same way 12-postgres-procedures.sql leaves its own clean-up block --
-- uncomment to remove these procedures from a database you want to
-- return to its 00-setup-both.sql state.
-- ======================================================================
-- DROP PROCEDURE IF EXISTS GET_CUSTOMER;
-- DROP PROCEDURE IF EXISTS ADD_TO_BALANCE;
-- DROP PROCEDURE IF EXISTS REP_CUSTOMER_LIST;
-- DROP PROCEDURE IF EXISTS DELETE_ITEM;
-- DROP PROCEDURE IF EXISTS REP_INVOICE_LINES;
-- DROP PROCEDURE IF EXISTS BUMP_HABITAT_STOCK;
