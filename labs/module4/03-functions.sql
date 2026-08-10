-- ======================================================================
-- Module 4 · Using Functions
-- ======================================================================
--
-- Sections: 4-3
-- Load first: 00-setup-both.sql   (has every table this file touches)
--             individual seeds used here: kimtay_full
--
-- Examples are the statements shown in the lesson. Exercises are the
-- starter queries from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Section 4-3 -- Using Functions
-- ----------------------------------------------------------------------

-- Example 4-3.1
SELECT COUNT(*)
FROM ITEM;

-- Example 4-3.2
SELECT COUNT(*) AS ITEM_COUNT
FROM ITEM
WHERE CATEGORY = 'Habitat';

-- Example 4-3.3
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
FROM CUSTOMER;

-- >>> EXERCISE 9  (section 4-3, seed: kimtay_full)
-- Hint: Both statements run together, and only the SELECT prints a result. Press Reset when you are done -- it reloads the original KimTay data with the rep number back in place.
-- Step 1: run this as it stands. Both counts come back as 4.
-- Step 2: delete the two dashes in front of the UPDATE line, run it again,
--         and watch WITH_A_REP drop to 3 while ALL_ROWS stays at 4.
-- UPDATE CUSTOMER SET REP_NUM = NULL WHERE CUSTOMER_NUM = '1310';
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
FROM CUSTOMER;

-- Example 4-3.4
SELECT SUM(BALANCE) AS TOTAL_OWED
FROM CUSTOMER;

-- Example 4-3.5
SELECT SUM(BALANCE) AS OWED_TO_REP_20
FROM CUSTOMER
WHERE REP_NUM = '20';

-- Example 4-3.6
SELECT AVG(PRICE) AS AVG_PRICE,
       MAX(PRICE) AS HIGHEST,
       MIN(PRICE) AS LOWEST
FROM ITEM;

-- Example 4-3.7
SELECT MIN(INVOICE_DATE) AS FIRST_INVOICE,
       MAX(INVOICE_DATE) AS LAST_INVOICE
FROM INVOICE;

-- Example 4-3.8
SELECT CITY
FROM CUSTOMER;

-- Example 4-3.9
SELECT DISTINCT CITY
FROM CUSTOMER
ORDER BY CITY;

-- Example 4-3.10
SELECT DISTINCT CITY, STATE
FROM CUSTOMER
ORDER BY CITY;

-- Example 4-3.11
SELECT COUNT(*) AS ALL_ROWS,
       COUNT(CITY) AS CITY_VALUES,
       COUNT(DISTINCT CITY) AS DIFFERENT_CITIES
FROM CUSTOMER;

-- Example 4-3.12
SELECT COUNT(*) AS LINE_COUNT,
       COUNT(DISTINCT INVOICE_NUM) AS INVOICES,
       COUNT(DISTINCT ITEM_ID) AS ITEMS
FROM INVOICE_LINE;

-- >>> EXERCISE 10  (section 4-3, seed: kimtay_full)
-- Hint: Question 2 needs a WHERE clause; question 3 needs three functions in one SELECT list.
-- ITEM holds 5 rows. Answer three questions, one query at a time.
-- 1. How many different categories are there? (written for you)
-- 2. How many Habitat items are there, and what do they average in price?
-- 3. How many units are on hand across all items, and what are the highest
--    and lowest prices in the catalog?
SELECT COUNT(DISTINCT CATEGORY) AS DIFFERENT_CATEGORIES
FROM ITEM;
