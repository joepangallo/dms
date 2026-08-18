-- ======================================================================
-- Module 8 · Stored Procedures Using MySQL
-- ======================================================================
--
-- Sections: 8-4
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-4  Stored Procedures Using MySQL
-- ----------------------------------------------------------------------


-- Example 8-4.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DELIMITER //: switch the statement terminator so the semicolons inside the
--   procedure are not mistaken for the end of it.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: makes the script re-runnable. Without it, the second
--   run fails because the procedure already exists.
DROP PROCEDURE IF EXISTS SHOW_REP_COUNT //

-- CREATE PROCEDURE: the simplest possible one - empty parentheses mean it takes
--   no parameters at all.
CREATE PROCEDURE SHOW_REP_COUNT()

-- BEGIN ... END wrap the body.
BEGIN

    -- One ordinary statement. Its result is returned to the caller.
    SELECT COUNT(*) AS REP_COUNT FROM REP;
END //

-- Restore the normal semicolon.
DELIMITER ;

-- Example 8-4.2
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: runs the procedure. The empty parentheses are still required even though
--   there is nothing to pass, and the SELECT inside sends its result back.
CALL SHOW_REP_COUNT();

-- Example 8-4.3
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DELIMITER //: as always, so inner semicolons are safe.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: clears out any earlier BAD_REP_NAME so this script
--   can be re-run without erroring on a duplicate name.
DROP PROCEDURE IF EXISTS BAD_REP_NAME //

-- CREATE PROCEDURE: this one is broken on purpose - watch the parameter name.
CREATE PROCEDURE BAD_REP_NAME(

    -- IN parameter named REP_NUM, which is ALSO the name of a column in REP.
    --   That collision is the bug.
    IN  REP_NUM     CHAR(2),

    -- OUT parameter: a value the procedure hands back to the caller.
    OUT o_last_name VARCHAR(20))
BEGIN

    -- SELECT ... INTO: instead of returning a result set, the value found is put
    --   into a variable. It expects exactly one row.
    SELECT LAST_NAME
    INTO   o_last_name

    -- FROM: REP, the table whose REP_NUM column collides with the parameter above.
    FROM   REP

    -- BROKEN. Both sides of this comparison are read as the COLUMN REP_NUM, so
    --   the condition says "where the column equals itself" - true for every row.
    --   That is why parameters are conventionally prefixed i_ or p_: the prefix
    --   makes a collision like this impossible.
    WHERE  REP_NUM = REP_NUM;
END //

DELIMITER ;

-- Example 8-4.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: passing the rep number and a session variable to receive the answer.
--   Because of the name collision, the WHERE clause matched every rep, so the
--   procedure returns whichever last name the engine happened to reach - not
--   necessarily rep 35's.
CALL BAD_REP_NAME('35', @last);

-- Example 8-4.5
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: same re-runnability guard as before - drops any
--   earlier DISP_REP_NAME before the CREATE below runs.
DROP PROCEDURE IF EXISTS DISP_REP_NAME //

-- CREATE PROCEDURE: the fixed version of the previous example.
CREATE PROCEDURE DISP_REP_NAME(

    -- The i_ prefix keeps the parameter name distinct from the column name.
    IN  i_rep_num    CHAR(2),

    -- Two OUT parameters: a procedure may hand back as many values as you like.
    OUT o_last_name  VARCHAR(20),
    OUT o_first_name VARCHAR(20))
BEGIN

    -- SELECT ... INTO with two columns and two variables. They are matched by
    --   position, so the order of the two lists has to agree.
    SELECT LAST_NAME, FIRST_NAME
    INTO   o_last_name, o_first_name

    -- FROM: REP, the table this corrected lookup reads.
    FROM   REP

    -- Now the comparison is genuinely column against parameter.
    WHERE  REP_NUM = i_rep_num;
END //

DELIMITER ;

-- Example 8-4.6
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: the two @ variables are session variables, supplied as somewhere for the
--   OUT parameters to land. They need no declaration.
CALL DISP_REP_NAME('35', @last, @first);

-- SELECT: OUT parameters are not displayed automatically - reading the variables
--   back is how you see what the procedure produced.
SELECT @last AS LAST_NAME, @first AS FIRST_NAME;

-- Example 8-4.7
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: drops any earlier GET_CREDIT_AVAILABLE so the CREATE
--   that follows doesn't fail on a name that already exists.
DROP PROCEDURE IF EXISTS GET_CREDIT_AVAILABLE //

-- CREATE PROCEDURE: this one computes something rather than just fetching it.
CREATE PROCEDURE GET_CREDIT_AVAILABLE(
    IN  i_customer_num CHAR(4),
    OUT o_available    DECIMAL(9,2))
BEGIN

    -- DECLARE: a LOCAL variable, visible only inside this procedure and gone the
    --   moment it ends. Every DECLARE must come before the first real statement
    --   of the body. Note there is no @ - that prefix marks session variables.
    DECLARE v_balance      DECIMAL(9,2);

    -- A second local, declared with the same type as the column it will hold.
    DECLARE v_credit_limit DECIMAL(9,2);

    -- SELECT ... INTO: read both values from the row in one statement rather than
    --   querying the table twice.
    SELECT BALANCE, CREDIT_LIMIT
    INTO   v_balance, v_credit_limit

    -- FROM: CUSTOMER, the table holding both BALANCE and CREDIT_LIMIT for this
    --   lookup.
    FROM   CUSTOMER

    -- WHERE: CUSTOMER_NUM is the primary key of CUSTOMER, so this matches exactly
    --   the one customer passed in - required for SELECT ... INTO to work.
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- SET: assigns a value to a variable. The calculation is done in the
    --   procedure, not in SQL, and the answer goes into the OUT parameter.
    SET o_available = v_credit_limit - v_balance;
END //

DELIMITER ;

-- Example 8-4.8
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: a customer that owes money - the available credit is limit minus balance.
CALL GET_CREDIT_AVAILABLE('1420', @avail);

-- SELECT: the CALL alone shows nothing - this reads the OUT value back through
--   @avail.
SELECT @avail AS CREDIT_AVAILABLE;

-- CALL: a customer with a zero balance, so the whole limit is still available.
--   Same procedure, different argument - which is the point of parameters.
CALL GET_CREDIT_AVAILABLE('1310', @avail);

-- SELECT: same read-back, now showing the second call's result.
SELECT @avail AS CREDIT_AVAILABLE;

-- Example 8-4.9
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: the same re-run guard as every script above -
--   removes any earlier ADD_SALE_TO_COMMISSION first.
DROP PROCEDURE IF EXISTS ADD_SALE_TO_COMMISSION //

-- CREATE PROCEDURE: demonstrates the third parameter direction.
CREATE PROCEDURE ADD_SALE_TO_COMMISSION(
    IN    i_rep_num     CHAR(2),
    IN    i_sale_amount DECIMAL(9,2),

    -- INOUT: the caller passes a value IN, the procedure changes it, and the new
    --   value goes back OUT through the same parameter. Use it when the answer
    --   depends on what was there before.
    INOUT io_commission DECIMAL(8,2))
BEGIN

    -- A local to hold the rate looked up from the table.
    DECLARE v_rate DECIMAL(4,2);

    -- SELECT ... INTO: fetch this rep's commission rate.
    SELECT RATE
    INTO   v_rate

    -- FROM: REP, the table that holds each rep's commission RATE.
    FROM   REP

    -- WHERE: matches the one rep passed in; REP_NUM is the primary key of REP,
    --   so SELECT ... INTO gets exactly the one row it needs.
    WHERE  REP_NUM = i_rep_num;

    -- SET: the INOUT parameter appears on BOTH sides - its incoming value is
    --   read on the right, and the updated total is written back on the left.
    SET io_commission = io_commission + (i_sale_amount * v_rate);
END //

DELIMITER ;

-- Example 8-4.10
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SET: give the session variable a starting value. An INOUT parameter must
--   already hold something, because the procedure reads it before writing it.
SET @comm = 39355.00;

-- CALL: the variable goes in holding the old commission and comes out holding
--   the new one.
CALL ADD_SALE_TO_COMMISSION('35', 1200.00, @comm);

-- SELECT: read the changed value back.
SELECT @comm AS NEW_COMMISSION;

-- Example 8-4.11
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SELECT: the catalogue again, this time listing stored routines rather than
--   tables - procedures and functions both appear here.
SELECT ROUTINE_NAME, ROUTINE_TYPE

-- FROM: INFORMATION_SCHEMA.ROUTINES, one row per stored routine on the server.
FROM   INFORMATION_SCHEMA.ROUTINES

-- WHERE: DATABASE() returns the name of the database you are currently connected
--   to, so this narrows the list to your own routines without hard-coding a name.
WHERE  ROUTINE_SCHEMA = DATABASE()
ORDER  BY ROUTINE_NAME;

-- Example 8-4.12
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SHOW CREATE PROCEDURE: prints the full text of a procedure as the server
--   stored it. This is how you read code somebody else wrote, or recover your
--   own when the script that created it has been lost.
SHOW CREATE PROCEDURE DISP_REP_NAME;
