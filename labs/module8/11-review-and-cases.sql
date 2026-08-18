-- ======================================================================
-- Module 8 · Module summary, key terms, review questions, case exercises
-- ======================================================================
--
-- Sections: Summary, Key Terms, Review, Case Exercises
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Review Questions
-- ----------------------------------------------------------------------


-- >>> EXERCISE 41  (section Review, seed: both_full)
-- Hint: Four customers come back, from 1120 to 1420. Every column of every row is filled in; nothing in the shipped data is missing. Companion Care Clinic sits at 1310 with a balance of 0 and no invoice anywhere in the database, which makes it the row to reach for whenever a question is about something that has no match. Replace the query with anything you want to check.
-- Both databases are loaded. Paste a review answer here and press Run.
-- Starter: the SELECT that a cursor over KimTay's customers would drive.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Case Exercises
-- ----------------------------------------------------------------------


-- >>> EXERCISE 42  (section Case Exercises, seed: both_full)
-- Hint: One log row: L004 for 465.00. The INSERT names only PAYMENT, and PAYMENT_LOG filled itself in. Try adding a second INSERT with PAYMENT_ID 98 for lease L003 at 725.00 and predict the result before you press Run. Remember to add a matching DELETE at the top if you want the box to stay re-runnable.
-- StayWell wants a permanent record of every payment as it arrives.
DROP TRIGGER IF EXISTS LOG_PAYMENT;
DROP TABLE IF EXISTS PAYMENT_LOG;
DELETE FROM PAYMENT WHERE PAYMENT_ID = 99;

CREATE TABLE PAYMENT_LOG (
    LOG_ID     INTEGER  PRIMARY KEY,
    LEASE_ID   CHAR(4),
    AMOUNT     DECIMAL(7,2),
    LOGGED_ON  DATE
);

CREATE TRIGGER LOG_PAYMENT
AFTER INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    INSERT INTO PAYMENT_LOG (LEASE_ID, AMOUNT, LOGGED_ON)
    VALUES (NEW.LEASE_ID, NEW.AMOUNT, DATE('now'));
END;

INSERT INTO PAYMENT (PAYMENT_ID, LEASE_ID, PAYMENT_DATE, AMOUNT)
VALUES (99, 'L004', '2026-09-01', 465.00);

SELECT LOG_ID, LEASE_ID, AMOUNT
FROM PAYMENT_LOG;
