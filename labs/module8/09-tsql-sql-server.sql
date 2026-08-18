-- ======================================================================
-- Module 8 · Using T-SQL in SQL Server
-- ======================================================================
--
-- Sections: 8-9
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-9  Using T-SQL in SQL Server
-- ----------------------------------------------------------------------


-- Example 8-9.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SQL Server T-SQL. CREATE PROCEDURE with no parentheses around the parameter
--   list, and every parameter and variable name starting with @.
CREATE PROCEDURE GET_CUSTOMER
    @I_CUSTOMER_NUM CHAR(4)

-- AS: opens the body. T-SQL does not require BEGIN ... END around it.
AS

-- DECLARE: the @ prefix is part of the name here, not a marker for something
--   special as it is in MySQL.
DECLARE @L_NAME    VARCHAR(35);
DECLARE @L_BALANCE DECIMAL(9,2);
DECLARE @L_ROWS    INT;

-- SELECT @variable = column: T-SQL's way of loading variables from a query -
--   assignments inside the SELECT list, with no INTO clause at all.
SELECT @L_NAME    = CUSTOMER_NAME,
       @L_BALANCE = BALANCE
-- FROM: the customer table this lookup reads.
FROM   CUSTOMER
-- WHERE: the parameter value passed in as @I_CUSTOMER_NUM. Nothing here
--   guarantees exactly one match - that is what @L_ROWS checks below.
WHERE  CUSTOMER_NUM = @I_CUSTOMER_NUM;

-- @@ROWCOUNT: how many rows the previous statement touched. Capture it
--   immediately - the very next statement overwrites it.
SET @L_ROWS = @@ROWCOUNT;

-- T-SQL raises nothing when this SELECT matches no row, so the procedure has to
--   test the count itself. Zero rows means no such customer.
IF @L_ROWS = 0

    -- PRINT: T-SQL's print statement. + joins strings here, where Oracle used ||.
    PRINT 'No customer numbered ' + @I_CUSTOMER_NUM;

-- More than one row means the variables hold the LAST row read, silently.
ELSE IF @L_ROWS > 1

    -- No CAST needed here - the message is plain text, unlike the ELSE branch
    --   below.
    PRINT 'That condition matched more than one customer.';

-- Exactly one row: the normal path.
ELSE

    -- CAST is required, because T-SQL will not join a number to a string.
    PRINT @L_NAME + '  ' + CAST(@L_BALANCE AS VARCHAR(20));

-- GO: not SQL at all, but a batch separator the client uses to decide where one
--   piece of work ends. It plays the same role as MySQL's DELIMITER and Oracle's /.
GO

-- Example 8-9.2
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- EXEC: SQL Server's way of running a procedure - MySQL says CALL, Oracle uses
--   the procedure name on its own. Arguments follow with no parentheses.
EXEC GET_CUSTOMER '1420';

-- >>> EXERCISE 31  (section 8-9, seed: kimtay_full)
-- Hint: This is the query the T-SQL procedure runs; the procedure adds a parameter and two variables around it. One row comes back: Whiskers & Wags Boutique with a balance of 4820.75. Change 1420 to 1999 and the box shows an empty result, which is the case the @@ROWCOUNT test is there to catch.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1420';

-- Example 8-9.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SQL Server T-SQL: a data change wrapped in a transaction with structured
--   error handling.
CREATE PROCEDURE ADD_TO_BALANCE
    @I_CUSTOMER_NUM CHAR(4),
    @I_AMOUNT       DECIMAL(9,2)
AS

-- BEGIN TRY: everything up to END TRY is protected. If any statement inside
--   fails, control jumps straight to the CATCH block.
BEGIN TRY

    -- Open the transaction so a failure can be undone.
    BEGIN TRANSACTION;

    -- The change itself.
    UPDATE CUSTOMER
    -- SET: adds the amount to the existing balance rather than replacing it.
    SET    BALANCE = BALANCE + @I_AMOUNT
    -- WHERE: the customer number passed in - the one row this call is allowed
    --   to touch.
    WHERE  CUSTOMER_NUM = @I_CUSTOMER_NUM;

    -- An UPDATE that matched nothing is not an error, so check the count and
    --   turn it into one deliberately.
    IF @@ROWCOUNT = 0

        -- THROW: raise an error with your own number and message. Anything from
        --   50000 up is yours to use. This sends control to CATCH.
        THROW 50001, 'No customer with that number. Nothing was changed.', 1;

    -- Reached only when the update touched a row.
    COMMIT TRANSACTION;
-- END TRY: marks the end of the protected block. If nothing failed, execution
--   continues after END CATCH, skipping the CATCH block entirely.
END TRY

-- BEGIN CATCH: runs only when something in the TRY block failed.
BEGIN CATCH

    -- @@TRANCOUNT: how many transactions are open. Test it before rolling back -
    --   a ROLLBACK with no open transaction is itself an error.
    IF @@TRANCOUNT > 0

        -- Undoes the update - reached only when TRY's error triggered CATCH
        --   with a transaction still open.
        ROLLBACK TRANSACTION;

    -- ERROR_MESSAGE(): the text of whatever went wrong, available only inside a
    --   CATCH block.
    PRINT 'ADD_TO_BALANCE failed: ' + ERROR_MESSAGE();
-- END CATCH: closes the error-handling block that BEGIN CATCH opened.
END CATCH;
GO

-- Example 8-9.5
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- EXEC: two arguments, separated by a comma, in the order the procedure declares
--   them. A customer that exists, so the update commits.
EXEC ADD_TO_BALANCE '1225', 350.00;

-- >>> EXERCISE 32  (section 8-9, seed: kimtay_full)
-- Hint: Downtown Aquarium & Pets ends at 1550.00 against a credit limit of 5000.00. The first UPDATE exists so that pressing Run a second time gives the same answer rather than 1900.00. The stored procedure adds the parameter, the transaction, and the @@ROWCOUNT test around the middle statement.
-- Put the balance back to its seeded value so this box can be run again.
UPDATE CUSTOMER
SET BALANCE = 1200.00
WHERE CUSTOMER_NUM = '1225';

-- The one statement the stored procedure wraps.
UPDATE CUSTOMER
SET BALANCE = BALANCE + 350.00
WHERE CUSTOMER_NUM = '1225';

SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1225';

-- Example 8-9.7
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SQL Server T-SQL: a delete that reports all three of its possible outcomes.
CREATE PROCEDURE DELETE_ITEM
    @I_ITEM_ID CHAR(4)
AS

-- BEGIN TRY: same protected-block pattern as ADD_TO_BALANCE - a failure
--   inside jumps straight to CATCH below.
BEGIN TRY

    -- The delete, with its WHERE clause built into the procedure.
    DELETE FROM ITEM
    -- WHERE: the one item number the caller passed in.
    WHERE  ITEM_ID = @I_ITEM_ID;

    -- Outcome 1: nothing matched. Not an error, so it is detected by the count.
    IF @@ROWCOUNT = 0

        -- No CAST needed here - @I_ITEM_ID is already a string, unlike
        --   @L_BALANCE back in GET_CUSTOMER.
        PRINT 'No item numbered ' + @I_ITEM_ID + '. Nothing was deleted.';

    -- Outcome 2: the row was removed.
    ELSE

        -- Confirms the delete succeeded - the mirror image of Outcome 1's
        --   message.
        PRINT 'Item ' + @I_ITEM_ID + ' deleted.';
-- END TRY: closes the protected block. Getting here means neither outcome
--   above threw, so CATCH below is skipped entirely.
END TRY
-- BEGIN CATCH: reached only if the DELETE above raised an error - a normal
--   "no rows matched" is not one.
BEGIN CATCH

    -- Outcome 3: the delete was refused - typically by a foreign key, because
    --   invoice lines still point at the item. ERROR_MESSAGE() reports which.
    PRINT 'Could not delete ' + @I_ITEM_ID + ': ' + ERROR_MESSAGE();
-- END CATCH: closes the error-handling block; GO ends the batch right after it.
END CATCH;
GO

-- Example 8-9.8
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- EXEC: DG04 appears on an invoice line, so the foreign key refuses the delete
--   and the CATCH block explains why. The item survives.
EXEC DELETE_ITEM 'DG04';

-- Example 8-9.9
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- PRAGMA foreign_keys = ON: SQLite does not enforce foreign keys unless you ask
--   it to, and the setting lasts only for this connection.
PRAGMA foreign_keys = ON;

-- DELETE: the same attempt, in the sandbox on this page. INVOICE_LINE holds rows
--   referring to DG04, so the delete is refused and you see the error the SQL
--   Server CATCH block above was reporting.
DELETE FROM ITEM
WHERE ITEM_ID = 'DG04';

-- >>> EXERCISE 33  (section 8-9, seed: kimtay_full)
-- Hint: The first result shows invoice 50710 ordering two of DG04, which is exactly why the real table refuses the delete. The second result has four rows instead of five: the working copy carried no foreign key over from ITEM, so nothing stopped the delete there. Checking before deleting is the habit worth keeping.
-- Step 1: find out what still points at DG04.
SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED
FROM INVOICE_LINE
WHERE ITEM_ID = 'DG04';

-- Step 2: delete it from a working copy, where no foreign key is watching.
DROP TABLE IF EXISTS ITEM_WORK;
CREATE TABLE ITEM_WORK AS SELECT * FROM ITEM;

DELETE FROM ITEM_WORK
WHERE ITEM_ID = 'DG04';

SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM_WORK
ORDER BY ITEM_ID;

-- Example 8-9.11
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SQL Server T-SQL: the cursor loop, third dialect.
CREATE PROCEDURE REP_CUSTOMER_LIST
    @I_REP_NUM CHAR(2)
AS

-- One variable per cursor column, all declared up front.
DECLARE @L_CUSTOMER_NUM  CHAR(4);
DECLARE @L_CUSTOMER_NAME VARCHAR(35);
DECLARE @L_BALANCE       DECIMAL(9,2);

-- DECLARE ... CURSOR FOR: the query to be walked.
DECLARE CUSTGROUP CURSOR FOR
    -- SELECT: the three columns the loop below will print.
    SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
    -- FROM: the customer table this cursor walks.
    FROM   CUSTOMER
    -- WHERE: limits the cursor to customers belonging to the rep passed in as
    --   @I_REP_NUM.
    WHERE  REP_NUM = @I_REP_NUM
    -- ORDER BY: fixes the order the cursor visits rows in - without it, the
    --   engine could hand rows back in any order it likes.
    ORDER BY CUSTOMER_NUM;

-- Run the query and get ready to read.
OPEN CUSTGROUP;

-- FETCH NEXT FROM ... INTO: T-SQL spells out the direction. The FIRST fetch
--   happens BEFORE the loop - that is what makes a WHILE loop possible here.
FETCH NEXT FROM CUSTGROUP
    INTO @L_CUSTOMER_NUM, @L_CUSTOMER_NAME, @L_BALANCE;

-- @@FETCH_STATUS: 0 means the last fetch worked. Testing it at the TOP of the
--   loop replaces MySQL's flag-and-handler arrangement entirely.
WHILE @@FETCH_STATUS = 0
-- BEGIN: opens the loop body. T-SQL's WHILE, like its IF, needs BEGIN ... END
--   around anything longer than a single statement.
BEGIN

    -- The work for this row.
    PRINT @L_CUSTOMER_NUM + '  ' + @L_CUSTOMER_NAME + '  ' +
          CAST(@L_BALANCE AS VARCHAR(20));

    -- The SECOND fetch, at the bottom of the loop. Forget this line and the
    --   loop repeats the same row forever - the classic T-SQL cursor bug.
    FETCH NEXT FROM CUSTGROUP
        INTO @L_CUSTOMER_NUM, @L_CUSTOMER_NAME, @L_BALANCE;
-- END: closes the loop body. Control returns to the WHILE line above, which
--   re-tests @@FETCH_STATUS against the fetch that just ran.
END

-- CLOSE releases the rows...
CLOSE CUSTGROUP;

-- ...and DEALLOCATE releases the cursor's name. T-SQL needs both; MySQL and
--   Oracle need only the close.
DEALLOCATE CUSTGROUP;
GO

-- >>> EXERCISE 34  (section 8-9, seed: kimtay_full)
-- Hint: Two rows, in the order the cursor would visit them: 1120 first, then 1310. The ORDER BY is what makes a cursor's visiting order predictable. Without it the engine may hand back rows in any order it likes, and a report built on that order becomes unreliable.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- Example 8-9.13
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SQL Server T-SQL: a cursor over a four-table join, keeping a running total as
--   it goes - something a single SELECT cannot do as it walks.
CREATE PROCEDURE REP_INVOICE_LINES
    @I_REP_NUM CHAR(2)
AS

-- One variable per cursor column.
DECLARE @L_INVOICE_NUM   CHAR(5);
DECLARE @L_CUSTOMER_NAME VARCHAR(35);
DECLARE @L_DESCRIPTION   VARCHAR(30);
DECLARE @L_LINE_TOTAL    DECIMAL(9,2);

-- An accumulator, declared WITH a starting value. It must begin at 0 rather than
--   NULL, because NULL + anything is NULL and the total would never build.
DECLARE @L_RUNNING_TOTAL DECIMAL(9,2) = 0;

-- The cursor: three stored columns and one calculated one, across four tables.
DECLARE LINEGROUP CURSOR FOR
    -- SELECT: the calculated column (NUM_ORDERED * QUOTED_PRICE) is what
    --   @L_LINE_TOTAL receives below; the other three columns copy straight
    --   across.
    SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION,
           IL.NUM_ORDERED * IL.QUOTED_PRICE
    -- FROM: CUSTOMER is the base table each hop below joins outward from.
    FROM   CUSTOMER C

           -- Hop 1 - customer to invoice.
           JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM

           -- Hop 2 - invoice to line item.
           JOIN INVOICE_LINE IL ON I.INVOICE_NUM  = IL.INVOICE_NUM

           -- Hop 3 - line item to item.
           JOIN ITEM IT         ON IL.ITEM_ID     = IT.ITEM_ID
    -- WHERE: limits the join to the rep's own customers.
    WHERE  C.REP_NUM = @I_REP_NUM
    -- ORDER BY: invoice first, then description within it - the order the
    --   cursor will print and total rows in.
    ORDER BY I.INVOICE_NUM, IT.DESCRIPTION;

-- OPEN: runs the four-table query above and positions the cursor before the
--   first row.
OPEN LINEGROUP;

-- The priming fetch, before the loop.
FETCH NEXT FROM LINEGROUP
    INTO @L_INVOICE_NUM, @L_CUSTOMER_NAME, @L_DESCRIPTION, @L_LINE_TOTAL;

-- The same fetch-and-test loop as REP_CUSTOMER_LIST, now walking the
--   four-table cursor above.
WHILE @@FETCH_STATUS = 0
BEGIN

    -- Add this row's total to the accumulator. The variable survives from one
    --   pass of the loop to the next, which is how the running total builds.
    SET @L_RUNNING_TOTAL = @L_RUNNING_TOTAL + @L_LINE_TOTAL;

    -- Print the detail line.
    PRINT @L_INVOICE_NUM + '  ' + @L_CUSTOMER_NAME + '  ' +
          @L_DESCRIPTION + '  ' + CAST(@L_LINE_TOTAL AS VARCHAR(20));

    -- Advance to the next row.
    FETCH NEXT FROM LINEGROUP
        INTO @L_INVOICE_NUM, @L_CUSTOMER_NAME, @L_DESCRIPTION, @L_LINE_TOTAL;
END

-- CLOSE: releases the rows this cursor was holding, same as in
--   REP_CUSTOMER_LIST.
CLOSE LINEGROUP;
DEALLOCATE LINEGROUP;

-- The grand total, printed once after the loop - the accumulator's final value.
PRINT 'Total for rep ' + @I_REP_NUM + ': ' +
      CAST(@L_RUNNING_TOTAL AS VARCHAR(20));
GO

-- >>> EXERCISE 35  (section 8-9, seed: kimtay_full)
-- Hint: Two lines on invoice 50710 for Access Pet Center: 127.50 and 23.98. The second query is the same total the cursor builds up in @L_RUNNING_TOTAL, done in one statement instead of a loop. When SUM can answer the question, SUM is the better answer. Companion Care Clinic has no invoice, so it contributes nothing.
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION,
       IL.NUM_ORDERED * IL.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
     JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
     JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
     JOIN ITEM IT         ON IL.ITEM_ID = IT.ITEM_ID
WHERE C.REP_NUM = '20'
ORDER BY I.INVOICE_NUM, IT.DESCRIPTION;

SELECT SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS REP_TOTAL
FROM CUSTOMER C
     JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
     JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
WHERE C.REP_NUM = '20';

-- Example 8-9.15
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SQL Server T-SQL: an UPDATABLE cursor - one that changes the rows it walks.
DECLARE @L_ITEM_ID CHAR(4);
-- @L_ON_HAND: holds the quantity column this cursor is about to update.
DECLARE @L_ON_HAND SMALLINT;

-- DECLARE ITEMGROUP CURSOR FOR: the query to be walked, made updatable by
--   the FOR UPDATE OF clause below.
DECLARE ITEMGROUP CURSOR FOR
    -- SELECT: the item id and the quantity the loop will adjust.
    SELECT ITEM_ID, ON_HAND
    -- FROM: the item table this cursor updates.
    FROM   ITEM
    -- WHERE: limits the cursor to the Habitat category - the two items the
    --   loop below will touch.
    WHERE  CATEGORY = 'Habitat'

-- FOR UPDATE OF: declares which column the loop intends to change, and tells the
--   engine to hold the rows so they can be updated in place.
FOR UPDATE OF ON_HAND;

-- OPEN: runs the query and locks the matching rows for update.
OPEN ITEMGROUP;

-- The priming fetch.
FETCH NEXT FROM ITEMGROUP INTO @L_ITEM_ID, @L_ON_HAND;

-- WHILE @@FETCH_STATUS = 0: the same loop test as the earlier cursors - keep
--   going while the last fetch found a row.
WHILE @@FETCH_STATUS = 0
BEGIN
    -- The update this cursor exists to make - to the row it just fetched.
    UPDATE ITEM
    -- SET: increases ON_HAND by 10 for that row.
    SET    ON_HAND = ON_HAND + 10

    -- WHERE CURRENT OF: "the row this cursor is sitting on" - no key comparison
    --   is needed, because the cursor already knows which row that is. Worth
    --   knowing, and worth avoiding: a single UPDATE ... WHERE CATEGORY =
    --   'Habitat' does the same job in one statement and far more quickly.
    WHERE  CURRENT OF ITEMGROUP;

    -- Advances the cursor - required every pass, or @@FETCH_STATUS never
    --   changes and the loop never ends.
    FETCH NEXT FROM ITEMGROUP INTO @L_ITEM_ID, @L_ON_HAND;
END

-- CLOSE: releases the rows this cursor was holding.
CLOSE ITEMGROUP;
DEALLOCATE ITEMGROUP;
