-- ======================================================================
-- Module 4 · Sorting
-- ======================================================================
--
-- Sections: 4-2
-- Load first: 00-setup-both.sql   (has every table this file touches)
--             individual seeds used here: kimtay_full, staywell_full
--
-- Examples are the statements shown in the lesson. Exercises are the
-- starter queries from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Section 4-2 -- Sorting
-- ----------------------------------------------------------------------

-- Example 4-2.1
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
ORDER BY CUSTOMER_NAME;

-- Example 4-2.2
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
ORDER BY PRICE DESC;

-- Example 4-2.3
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ON_HAND > 20
ORDER BY ON_HAND DESC;

-- >>> EXERCISE 7  (section 4-2, seed: kimtay_full)
-- Hint: Run it as written (1225, 1120, 1420), then add DESC so the largest balance is on top.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > 1000
ORDER BY BALANCE;

-- Example 4-2.4
SELECT CUSTOMER_NAME, CITY, BALANCE
FROM CUSTOMER
ORDER BY CITY, CUSTOMER_NAME;

-- Example 4-2.5
SELECT CUSTOMER_NAME, CITY, BALANCE
FROM CUSTOMER
ORDER BY CITY DESC, BALANCE DESC;

-- Example 4-2.6
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
ORDER BY PROPERTY_ID, MONTHLY_RENT DESC;

-- Example 4-2.7
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
FROM ITEM
ORDER BY ON_HAND_VALUE DESC;

-- Example 4-2.8
SELECT DESCRIPTION, CATEGORY, PRICE
FROM ITEM
ORDER BY 2, 3 DESC;

-- >>> EXERCISE 8  (section 4-2, seed: staywell_full)
-- Hint: A StayWell room is let for a nine-month academic year; re-sort by ACADEMIC_YEAR_RENT descending so P200 201 (6525) leads and P100 102 (4050) trails.
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT * 9 AS ACADEMIC_YEAR_RENT
FROM ROOM
ORDER BY PROPERTY_ID, ROOM_NUM;
