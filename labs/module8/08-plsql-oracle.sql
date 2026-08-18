-- ======================================================================
-- Module 8 · Using PL/SQL in Oracle
-- ======================================================================
--
-- Sections: 8-8
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-8  Using PL/SQL in Oracle
-- ----------------------------------------------------------------------


-- Example 8-8.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- MySQL, for comparison with the Oracle and SQL Server versions below.
DELIMITER //

-- CREATE PROCEDURE: MySQL puts the direction (IN) BEFORE the parameter name.
CREATE PROCEDURE GET_CUSTOMER (IN I_CUSTOMER_NUM CHAR(4))
BEGIN

    -- DECLARE, with the type written out in full.
    DECLARE L_NAME    VARCHAR(35);
    DECLARE L_BALANCE DECIMAL(9,2);

    -- SELECT ... INTO fills the two locals.
    SELECT CUSTOMER_NAME, BALANCE
    INTO   L_NAME, L_BALANCE
    -- FROM: the customer table this lookup reads.
    FROM   CUSTOMER
    -- WHERE: filters to the one row this call targets - the customer number
    --   passed in as I_CUSTOMER_NUM.
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    -- MySQL has no print statement, so output is produced by SELECTing the
    --   variables - the result comes back as a one-row result set.
    SELECT L_NAME AS CUSTOMER_NAME, L_BALANCE AS BALANCE;
END //
DELIMITER ;

-- Example 8-8.2
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- Oracle PL/SQL. CREATE OR REPLACE: no separate DROP is needed - this replaces
--   any existing procedure of the same name in one statement.
CREATE OR REPLACE PROCEDURE GET_CUSTOMER (I_CUSTOMER_NUM IN CHAR) AS

    -- %TYPE: declare the variable as "whatever type that column is". If the
    --   column is widened later, the variable follows automatically. Note there
    --   is no DECLARE keyword here - in Oracle, declarations simply sit between
    --   AS and BEGIN. Oracle also puts the direction AFTER the parameter name.
    L_NAME     CUSTOMER.CUSTOMER_NAME%TYPE;
    L_BALANCE  CUSTOMER.BALANCE%TYPE;
BEGIN

    -- SELECT ... INTO works the same way as in MySQL.
    SELECT CUSTOMER_NAME, BALANCE
    INTO   L_NAME, L_BALANCE
    -- FROM: same customer table as the MySQL version.
    FROM   CUSTOMER
    -- WHERE: filters to the single row identified by the parameter.
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    -- DBMS_OUTPUT.PUT_LINE: Oracle's print. || joins strings, and TO_CHAR formats
    --   the number to a fixed picture so columns line up.
    DBMS_OUTPUT.PUT_LINE(L_NAME || '  ' || TO_CHAR(L_BALANCE, '99999.99'));

-- EXCEPTION: Oracle's error handling is a block at the END of the procedure,
--   rather than handlers declared at the top as in MySQL.
EXCEPTION

    -- NO_DATA_FOUND: the named condition for a SELECT ... INTO that matched
    --   nothing - Oracle's equivalent of MySQL's NOT FOUND.
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No customer numbered ' || I_CUSTOMER_NUM);

    -- TOO_MANY_ROWS: the opposite failure - the INTO matched more than one row.
    --   Oracle gives this its own name; MySQL lumps it under SQLEXCEPTION.
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('That condition matched more than one customer.');

    -- WHEN OTHERS: the catch-all, and it must come last. SQLERRM holds the text
    --   of whatever actually went wrong.
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;

-- The lone / on its own line is what tells SQL*Plus to send the block to the
--   server - Oracle's equivalent of MySQL's DELIMITER dance.
/

-- >>> EXERCISE 29  (section 8-8, seed: kimtay_full)
-- Hint: Three queries, three shapes of answer: one row, no rows, two rows. SQLite reports all three as ordinary results. Oracle gives the last two names and expects you to handle them. Case 2 shows an empty area rather than a table, because no row qualified.
-- Case 1: exactly one row comes back. This is the case the procedure was written for.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1225';

-- Case 2: no row comes back. In PL/SQL this raises NO_DATA_FOUND.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1999';

-- Case 3: two rows come back. In PL/SQL this raises TOO_MANY_ROWS.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20';

-- Example 8-8.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- Oracle PL/SQL: a procedure that changes data and refuses to leave the database
--   in a state it considers invalid.
CREATE OR REPLACE PROCEDURE ADD_TO_BALANCE (
    I_CUSTOMER_NUM  IN CHAR,
    I_AMOUNT        IN NUMBER) AS

    -- Declaring your OWN exception. It is not an error the database raises - it
    --   is a name for a business rule you are about to enforce yourself.
    OVER_LIMIT   EXCEPTION;

    -- Two locals typed from the columns they will hold.
    L_BALANCE    CUSTOMER.BALANCE%TYPE;
    L_LIMIT      CUSTOMER.CREDIT_LIMIT%TYPE;
BEGIN

    -- The change is made first, then checked. Everything is inside a transaction
    --   until COMMIT, so it can still be taken back.
    UPDATE CUSTOMER
    -- SET: adds the signed amount to the current balance - the caller controls
    --   the sign, so this same line handles a charge or a payment.
    SET    BALANCE = BALANCE + I_AMOUNT
    -- WHERE: targets only the customer named by the parameter.
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    -- SQL%ROWCOUNT: how many rows the last statement affected. Zero means the
    --   customer number was wrong - an UPDATE that matches nothing is not an
    --   error, so you have to detect it yourself.
    IF SQL%ROWCOUNT = 0 THEN

        -- RAISE: trigger a condition deliberately, sending control to the
        --   EXCEPTION block below.
        RAISE NO_DATA_FOUND;
    END IF;

    -- Read the row back to see what the update actually produced.
    SELECT BALANCE, CREDIT_LIMIT
    INTO   L_BALANCE, L_LIMIT
    -- FROM: the same customer table the UPDATE just changed.
    FROM   CUSTOMER
    -- WHERE: the same customer the UPDATE targeted, so the values read back are
    --   the ones the change just produced.
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    -- The business rule. Nothing in the database forbids this, so the procedure
    --   enforces it.
    IF L_BALANCE > L_LIMIT THEN
        RAISE OVER_LIMIT;
    END IF;

    -- COMMIT: reached only when both checks passed. Until this line, nothing is
    --   permanent.
    COMMIT;
-- EXCEPTION: catches both the built-in NO_DATA_FOUND case and the OVER_LIMIT
--   rule this procedure raises on itself.
EXCEPTION

    -- Every handler rolls back first, so a rejected change leaves no trace.
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;

        -- RAISE_APPLICATION_ERROR: hands a numbered error and a readable message
        --   back to the calling program. Numbers from -20000 to -20999 are
        --   reserved for your own application errors.
        RAISE_APPLICATION_ERROR(-20001,
            'No customer numbered ' || I_CUSTOMER_NUM);

    -- The custom exception declared at the top is caught by name here.
    WHEN OVER_LIMIT THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002,
            'That charge would push the balance past the credit limit.');

    -- The catch-all for anything unforeseen, still rolling back.
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Unexpected error: ' || SQLERRM);
END;
/

-- >>> EXERCISE 30  (section 8-8, seed: kimtay_full)
-- Hint: Two rows come back: 1120 Access Pet Center and 1310 Companion Care Clinic. A cursor does not change what this query returns. It changes who reads the rows and how many at a time. Try changing '20' to '65' to see a one-row list.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- Example 8-8.6
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- Oracle PL/SQL: the cursor loop, Oracle style.
CREATE OR REPLACE PROCEDURE REP_CUSTOMER_LIST (I_REP_NUM IN CHAR) AS

    -- CURSOR ... IS: Oracle's cursor declaration. Same idea as MySQL's
    --   DECLARE ... CURSOR FOR, different wording.
    CURSOR CUSTGROUP IS
        -- SELECT: the three columns each FETCH below will copy into the loop's
        --   variables, in this order.
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
        -- FROM: the same customer table the sandbox version above queried.
        FROM   CUSTOMER
        -- WHERE: the parameter stands in for the literal '20' used in the
        --   sandbox - one cursor definition serves every rep.
        WHERE  REP_NUM = I_REP_NUM
        -- ORDER BY: keeps the rows in customer-number order as they're fetched.
        ORDER BY CUSTOMER_NUM;

    -- One variable per cursor column, typed from the columns themselves.
    L_CUSTOMER_NUM   CUSTOMER.CUSTOMER_NUM%TYPE;
    L_CUSTOMER_NAME  CUSTOMER.CUSTOMER_NAME%TYPE;
    L_BALANCE        CUSTOMER.BALANCE%TYPE;
BEGIN

    -- Run the query and position before the first row.
    OPEN CUSTGROUP;

    -- A plain LOOP, exited by the test inside.
    LOOP

        -- Read one row into the three variables.
        FETCH CUSTGROUP INTO L_CUSTOMER_NUM, L_CUSTOMER_NAME, L_BALANCE;

        -- EXIT WHEN with %NOTFOUND: Oracle asks the cursor directly whether the
        --   last fetch got anything, so no flag variable and no handler are
        --   needed - simpler than the MySQL equivalent.
        EXIT WHEN CUSTGROUP%NOTFOUND;

        -- The work for this row: print it.
        DBMS_OUTPUT.PUT_LINE(L_CUSTOMER_NUM || '  ' || L_CUSTOMER_NAME ||
                             '  ' || TO_CHAR(L_BALANCE, '99999.99'));
    END LOOP;

    -- Release the cursor on the normal path.
    CLOSE CUSTGROUP;
-- EXCEPTION: a single catch-all for this listing - nothing here raises a
--   business exception of its own, so there is only one failure shape to name.
EXCEPTION
    -- WHEN OTHERS: the only handler; anything that goes wrong during the fetch
    --   loop ends up here.
    WHEN OTHERS THEN

        -- %ISOPEN: if the failure happened mid-loop the cursor is still open, so
        --   check before closing - closing a closed cursor is itself an error.
        IF CUSTGROUP%ISOPEN THEN
            CLOSE CUSTGROUP;
        END IF;
        RAISE_APPLICATION_ERROR(-20004, 'Listing failed: ' || SQLERRM);
END;
/

-- Example 8-8.7
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- Oracle PL/SQL: the same listing, written the way Oracle programmers actually
--   write it.
CREATE OR REPLACE PROCEDURE REP_CUSTOMER_LIST (I_REP_NUM IN CHAR) AS
BEGIN

    -- FOR ... IN (query) LOOP: a cursor FOR loop. Oracle declares the cursor,
    --   opens it, declares a record to hold each row, fetches, tests for the end
    --   and closes it - all implicitly. Compare it with the version above: the
    --   same job, with every place a mistake could hide taken away.
    FOR C IN (SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
              -- FROM, WHERE, ORDER BY: the same query as the CUSTGROUP cursor
              --   above, unchanged - only how it's opened, walked, and closed
              --   is different here.
              FROM   CUSTOMER
              WHERE  REP_NUM = I_REP_NUM
              ORDER BY CUSTOMER_NUM)
    LOOP

        -- C is the loop record, and its fields are named after the query's
        --   columns. Nothing had to be declared for it.
        DBMS_OUTPUT.PUT_LINE(C.CUSTOMER_NUM || '  ' || C.CUSTOMER_NAME);
    END LOOP;
END;
/
