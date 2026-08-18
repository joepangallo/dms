-- ======================================================================
-- Module 8 · Using a Trigger
-- ======================================================================
--
-- Sections: 8-10
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-10  Using a Trigger
-- ----------------------------------------------------------------------


-- >>> EXERCISE 36  (section 8-10, seed: kimtay_full)
-- Hint: One row comes back: 50712, GR15, 4, and whatever date you pressed Run. Read statement 3 again and notice it says nothing about INVOICE_LINE_LOG. That is the whole point of a trigger, and also the whole danger. Delete statement 2, press Run again, and the log comes back empty.
-- Housekeeping first, so this whole box can be run more than once.
DROP TRIGGER IF EXISTS LOG_NEW_LINE;
DROP TABLE IF EXISTS INVOICE_LINE_LOG;
DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';

-- 1. The audit table. Nothing writes to it by hand, ever.
CREATE TABLE INVOICE_LINE_LOG (
    LOG_ID       INTEGER  PRIMARY KEY,
    INVOICE_NUM  CHAR(5),
    ITEM_ID      CHAR(4),
    NUM_ORDERED  SMALLINT,
    LOGGED_ON    DATE
);

-- 2. The trigger. It fires after each new INVOICE_LINE row lands.
CREATE TRIGGER LOG_NEW_LINE
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    INSERT INTO INVOICE_LINE_LOG (INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON)
    VALUES (NEW.INVOICE_NUM, NEW.ITEM_ID, NEW.NUM_ORDERED, DATE('now'));
END;

-- 3. One ordinary INSERT. Nothing here mentions the log table.
INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
VALUES ('50712', 'GR15', 4, 15.25);

-- 4. Proof the trigger ran.
SELECT LOG_ID, INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON
FROM INVOICE_LINE_LOG;

-- >>> EXERCISE 37  (section 8-10, seed: kimtay_full)
-- Hint: Exactly one log row: 1120, 3512.5, 3762.5. Two UPDATE statements ran but only one was a real change, and the WHEN clause is what kept the second one out of the log. Delete the WHEN line and press Run again to see the noise it was filtering.
DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE;
DROP TABLE IF EXISTS BALANCE_LOG;
UPDATE CUSTOMER SET BALANCE = 3512.50 WHERE CUSTOMER_NUM = '1120';

CREATE TABLE BALANCE_LOG (
    LOG_ID        INTEGER  PRIMARY KEY,
    CUSTOMER_NUM  CHAR(4),
    OLD_BALANCE   DECIMAL(9,2),
    NEW_BALANCE   DECIMAL(9,2)
);

CREATE TRIGGER LOG_BALANCE_CHANGE
AFTER UPDATE OF BALANCE ON CUSTOMER
FOR EACH ROW
WHEN OLD.BALANCE <> NEW.BALANCE
BEGIN
    INSERT INTO BALANCE_LOG (CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE)
    VALUES (OLD.CUSTOMER_NUM, OLD.BALANCE, NEW.BALANCE);
END;

-- A real change. This one is logged.
UPDATE CUSTOMER
SET BALANCE = BALANCE + 250.00
WHERE CUSTOMER_NUM = '1120';

-- A change that changes nothing. The WHEN clause skips it.
UPDATE CUSTOMER
SET BALANCE = BALANCE
WHERE CUSTOMER_NUM = '1120';

SELECT LOG_ID, CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE
FROM BALANCE_LOG;

-- >>> EXERCISE 38  (section 8-10, seed: kimtay_full)
-- Hint: As written the insert succeeds and Harbor Pet Supply appears with a credit limit of 9000. Now change 9000.00 to 15000.00 and press Run again: the WHEN clause turns true, RAISE(ABORT) cancels the statement, and the box reports the message instead of a table. Nothing was stored, which is what BEFORE buys you.
DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
DELETE FROM CUSTOMER WHERE CUSTOMER_NUM = '1500';

CREATE TRIGGER CHECK_CREDIT_LIMIT
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
WHEN NEW.CREDIT_LIMIT > 10000
BEGIN
    SELECT RAISE(ABORT, 'Credit limit over 10000 needs manager approval');
END;

-- Within the ceiling, so this one is stored.
INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP,
                      BALANCE, CREDIT_LIMIT, REP_NUM)
VALUES ('1500', 'Harbor Pet Supply', '12 Dock St.', 'Northfield', 'OH', '44067',
        0.00, 9000.00, '35');

SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1500';

-- >>> EXERCISE 39  (section 8-10, seed: kimtay_full)
-- Hint: The Small Animal Grooming Kit ends at 18, down from its seeded 22. The INSERT names INVOICE_LINE and only INVOICE_LINE, yet a row in ITEM changed. The UPDATE at the top resets ON_HAND to 22 so the box gives 18 every time rather than 14, then 10, then 6.
DROP TRIGGER IF EXISTS REDUCE_ON_HAND;
DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';
UPDATE ITEM SET ON_HAND = 22 WHERE ITEM_ID = 'GR15';

CREATE TRIGGER REDUCE_ON_HAND
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    UPDATE ITEM
    SET ON_HAND = ON_HAND - NEW.NUM_ORDERED
    WHERE ITEM_ID = NEW.ITEM_ID;
END;

INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
VALUES ('50712', 'GR15', 4, 15.25);

SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ITEM_ID = 'GR15';

-- >>> EXERCISE 40  (section 8-10, seed: kimtay_full)
-- Hint: One row: LOG_NEW_LINE, trigger, INVOICE_LINE. That third column is the one that matters when you are trying to work out why a table keeps changing on its own. To watch the listing empty out, add DROP TRIGGER LOG_NEW_LINE; immediately ABOVE the SELECT and press Run again. Putting it after the SELECT changes nothing you can see, because the catalog is read before the drop happens.
-- Clear anything the earlier boxes on this page may have left behind,
-- so the listing below is exactly what this box created.
DROP TRIGGER IF EXISTS LOG_NEW_LINE;
DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE;
DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
DROP TRIGGER IF EXISTS REDUCE_ON_HAND;

CREATE TRIGGER LOG_NEW_LINE
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    UPDATE ITEM SET ON_HAND = ON_HAND WHERE ITEM_ID = NEW.ITEM_ID;
END;

-- Every trigger this database holds, and the table each one guards.
SELECT name, type, tbl_name
FROM sqlite_master
WHERE type = 'trigger';
