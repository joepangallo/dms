-- ======================================================================
-- Module 4 · Grouping
-- ======================================================================
--
-- Sections: 4-5
-- Load first: 00-setup-both.sql   (has every table this file touches)
--             individual seeds used here: kimtay_full, staywell_full
--
-- Examples are the statements shown in the lesson. Exercises are the
-- starter queries from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Section 4-5 -- Grouping
-- ----------------------------------------------------------------------

-- Example 4-5.1
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVG_PRICE
FROM ITEM
GROUP BY CATEGORY;

-- Example 4-5.2
SELECT INVOICE_NUM, SUM(NUM_ORDERED * QUOTED_PRICE) AS INVOICE_TOTAL
FROM INVOICE_LINE
GROUP BY INVOICE_NUM
ORDER BY INVOICE_TOTAL DESC;

-- >>> EXERCISE 13  (section 4-5, seed: kimtay_full)
-- Hint: MIN and MAX group the same way COUNT does. Expect Habitat first with 2, 27.75 and 64.99, then the three single-item categories, where the lowest and the highest are the same price.
-- One row per category, with a count:
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY;

-- Your turn: keep the count, add the cheapest and the dearest price
-- in each category, and sort so the biggest category comes first.

-- Example 4-5.3
SELECT CATEGORY, DESCRIPTION, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY;

-- Example 4-5.4
SELECT CATEGORY, DESCRIPTION, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY, DESCRIPTION
ORDER BY CATEGORY, DESCRIPTION;

-- Example 4-5.5
SELECT REP_NUM, CITY, COUNT(*) AS CUSTOMER_COUNT
FROM CUSTOMER
GROUP BY REP_NUM, CITY
ORDER BY REP_NUM, CITY;

-- Example 4-5.6
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY
HAVING COUNT(*) > 1;

-- Example 4-5.7
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT
FROM CUSTOMER
WHERE BALANCE > 1000.00
GROUP BY REP_NUM
ORDER BY REP_NUM;

-- Example 4-5.8
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT
FROM CUSTOMER
GROUP BY REP_NUM
HAVING SUM(BALANCE) > 1000.00
ORDER BY REP_NUM;

-- Example 4-5.9
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT, SUM(BALANCE) AS TOTAL_OWED
FROM CUSTOMER
WHERE BALANCE > 1000.00
GROUP BY REP_NUM
HAVING SUM(BALANCE) > 2000.00
ORDER BY TOTAL_OWED DESC;

-- >>> EXERCISE 14  (section 4-5, seed: staywell_full)
-- Hint: The rent test is about one room row, the count test is about a finished group. The starter gives P100 with 2 rooms at 522.5 and P200 with 3 at 600; the finished query gives one row, P200 with 2 rooms at 667.5.
-- Every property, every room:
SELECT PROPERTY_ID, COUNT(*) AS ROOM_COUNT, AVG(MONTHLY_RENT) AS AVG_RENT
FROM ROOM
GROUP BY PROPERTY_ID
ORDER BY PROPERTY_ID;

-- Your turn, one clause at a time:
--   1. count only rooms renting for more than 500.00
--   2. keep only the properties that still have more than one such room
--   3. sort by average rent, highest first
