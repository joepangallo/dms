-- ======================================================================
-- Module 8 · Using SQL in a Programming Environment
-- ======================================================================
--
-- Sections: 8-1
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-1  Using SQL in a Programming Environment
-- ----------------------------------------------------------------------


-- >>> EXERCISE 1  (section 8-1, seed: kimtay_full)
-- Hint: Nothing new here. Read the two rows that come back and notice that they are ordinary result rows, not anything special because a program asked for them.
-- The statement a program sends when a clerk picks rep 20.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- Example 8-1.2
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
# Host language (Python-style pseudocode). The SQL is the string in the middle.
# connect(): opens a session with the database server. The account named here is
#   the one whose privileges the SQL will run under - not the end user's.
conn = connect(database="kimtay", user="app_user", password="...")

# The SQL is just a string to the host language. These four lines are one
#   statement, split across lines only for readability.
sql = "SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE " \
      "FROM CUSTOMER " \

#   The ? is a PLACEHOLDER, not a value. Never paste the user's input into the
#   string - a placeholder is what keeps a typed value a value and stops it
#   being read as SQL, which is the whole defence against injection.
      "WHERE REP_NUM = ? " \
      "ORDER BY CUSTOMER_NUM"

# execute(): hands the statement and the values over separately. The database
#   parses the SQL once and then fills the placeholder with the value.
rows = conn.execute(sql, [rep_chosen_on_screen])

# The result comes back as a set of rows, and the host language walks it one row
#   at a time. This loop is the seam between the two languages: SQL thinks in
#   whole tables, the program thinks in single rows.
for row in rows:
    print(row.CUSTOMER_NUM, row.CUSTOMER_NAME, row.BALANCE)

-- Example 8-1.3
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- MySQL only. This sandbox runs SQLite, which has no CREATE PROCEDURE at all.
-- DELIMITER: temporarily changes the character that ends a statement from ; to $.
--   Without this, the client would think the procedure ended at the first
--   semicolon inside it, and send half a procedure to the server.
DELIMITER $

-- CREATE PROCEDURE: names the stored procedure and declares its parameters. IN
--   means the value is passed in and not sent back; CHAR(2) matches the type of
--   the column it will be compared against.
CREATE PROCEDURE CUSTOMERS_OF_REP(IN REP_WANTED CHAR(2))

-- BEGIN: opens the body - everything up to END is what the procedure does.
BEGIN

    -- An ordinary SELECT. Nothing about it changes because it lives in a
    --   procedure; the result goes back to whoever called it.
    SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
    FROM CUSTOMER

    -- The parameter is used exactly where a literal value would go.
    WHERE REP_NUM = REP_WANTED
    ORDER BY CUSTOMER_NUM;

-- END$ closes the body, using the temporary delimiter to end the whole
--   CREATE PROCEDURE statement.
END$

-- DELIMITER ; puts the normal semicolon back for everything that follows.
DELIMITER ;

-- Example 8-1.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- MySQL only. Any program, in any language, can run this one line.
-- CALL: runs a stored procedure by name, passing its arguments in order. The
--   query text now lives in the database rather than in the application, so
--   every program shares one definition and one place to fix it.
CALL CUSTOMERS_OF_REP('20');

-- >>> EXERCISE 2  (section 8-1, seed: kimtay_full)
-- Hint: One row comes back: CF21, 42.5, 44. The UPDATE at the bottom never mentions PRICE_LOG, yet the row is there, because OLD and NEW inside the trigger are the row before and after the change. The reset UPDATE near the top runs before the trigger exists, so it logs nothing and simply guarantees the same answer on a second Run.
DROP TRIGGER IF EXISTS LOG_PRICE_CHANGE;
DROP TABLE IF EXISTS PRICE_LOG;

-- Put CF21 back at its seeded price. The sandbox keeps whatever you did
-- last time until you press Reset, so this line is what makes the box
-- give the same answer on every Run.
UPDATE ITEM SET PRICE = 42.50 WHERE ITEM_ID = 'CF21';

CREATE TABLE PRICE_LOG (
    ITEM_ID    CHAR(4),
    OLD_PRICE  DECIMAL(7,2),
    NEW_PRICE  DECIMAL(7,2),
    CHANGED_ON DATE
);

CREATE TRIGGER LOG_PRICE_CHANGE
AFTER UPDATE OF PRICE ON ITEM
BEGIN
    INSERT INTO PRICE_LOG
    VALUES (OLD.ITEM_ID, OLD.PRICE, NEW.PRICE, DATE('now'));
END;

-- A plain UPDATE. It says nothing about logging.
UPDATE ITEM SET PRICE = 44.00 WHERE ITEM_ID = 'CF21';

SELECT ITEM_ID, OLD_PRICE, NEW_PRICE FROM PRICE_LOG;
