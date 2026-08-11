-- ======================================================================
-- Module 4 · Using Functions
-- ======================================================================
--
-- Sections: 4-3
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 4-3  Using Functions
-- ----------------------------------------------------------------------


-- Example 4-3.1
-- SELECT: COUNT(*) is an aggregate - it collapses many rows into one number.
--   The * means "count rows", not "count values", so nothing can be skipped.
SELECT COUNT(*)

-- FROM: the table whose rows are being counted. One row of output comes back,
--   whatever the size of the table.
FROM ITEM;

-- Example 4-3.2
-- SELECT: the same row count, given a readable heading with AS.
SELECT COUNT(*) AS ITEM_COUNT

-- FROM: the table being counted.
FROM ITEM

-- WHERE: the filter runs FIRST, and the count is taken over whatever survives.
--   That ordering is the whole trick to aggregates: filter, then aggregate.
WHERE CATEGORY = 'Habitat';

-- Example 4-3.3
-- SELECT: two counts side by side, and they answer different questions.
--   COUNT(*) counts ROWS. COUNT(REP_NUM) counts VALUES in that column, skipping
--   any row where it is null. Equal numbers mean no nulls; a gap between them is
--   how you discover nulls you did not know about.
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP

-- FROM: the table being counted. Every shipped row is filled in, so both read 4.
FROM CUSTOMER;

-- >>> EXERCISE 9  (section 4-3, seed: kimtay_full)
-- Hint: Both statements run together, and only the SELECT prints a result. Press Reset when you are done -- it reloads the original KimTay data with the rep number back in place.
-- Step 1: run this as it stands. Both counts come back as 4.
-- Step 2: delete the two dashes in front of the UPDATE line, run it again,
--         and watch WITH_A_REP drop to 3 while ALL_ROWS stays at 4.
-- UPDATE CUSTOMER SET REP_NUM = NULL WHERE CUSTOMER_NUM = '1310';
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
FROM CUSTOMER;

-- Example 4-3.5
-- SELECT: SUM adds up the values in one column across every row it is given.
--   It only makes sense on numbers - there is nothing to add in a city name.
SELECT SUM(BALANCE) AS TOTAL_OWED

-- FROM: the table supplying the rows. One number comes back.
FROM CUSTOMER;

-- Example 4-3.6
-- SELECT: the same total, over a smaller set of rows.
SELECT SUM(BALANCE) AS OWED_TO_REP_20

-- FROM: the table being read.
FROM CUSTOMER

-- WHERE: applied before the SUM, so only rep 20's customers are added together.
--   Change the WHERE and the single number changes with it.
WHERE REP_NUM = '20';

-- Example 4-3.7
-- SELECT: three aggregates in one statement, each over the same column.
--   AVG is the mean of the values.
SELECT AVG(PRICE) AS AVG_PRICE,

--   MAX is the largest value present - not a calculation, just a pick.
       MAX(PRICE) AS HIGHEST,

--   MIN is the smallest. All three collapse the whole table to one row, so the
--   output is one row with three columns.
       MIN(PRICE) AS LOWEST

-- FROM: the table all three are computed over.
FROM ITEM;

-- Example 4-3.8
-- SELECT: MIN and MAX are not restricted to numbers. On a DATE column they give
--   the earliest date...
SELECT MIN(INVOICE_DATE) AS FIRST_INVOICE,

--   ...and the latest one. This works because the column is a real DATE type; on
--   dates stored as text it would only work by luck of the format.
       MAX(INVOICE_DATE) AS LAST_INVOICE

-- FROM: the table being read.
FROM INVOICE;

-- Example 4-3.9
-- SELECT: one column, with no filtering and no de-duplication.
SELECT CITY

-- FROM: the table being read. One row comes back per CUSTOMER row, so a city
--   used by two customers is printed twice. That repetition is the problem the
--   next query solves.
FROM CUSTOMER;

-- Example 4-3.10
-- SELECT: DISTINCT removes duplicate ROWS from the result - it is not a function
--   attached to the column, but a keyword applied to the whole SELECT list.
SELECT DISTINCT CITY

-- FROM: the table being read.
FROM CUSTOMER

-- ORDER BY: sorts what is left. De-duplication happens first, sorting afterwards.
ORDER BY CITY;

-- Example 4-3.11
-- SELECT: DISTINCT applies to the COMBINATION of every listed column, not to
--   each column separately. Two rows are duplicates only when the city and the
--   state both match, so this returns distinct city-and-state pairs.
SELECT DISTINCT CITY, STATE

-- FROM: the table being read.
FROM CUSTOMER

-- ORDER BY: sorts the surviving pairs by city.
ORDER BY CITY;

-- Example 4-3.12
-- SELECT: three counts that answer three different questions.
--   COUNT(*) counts rows, regardless of what is in them.
SELECT COUNT(*) AS ALL_ROWS,

--   COUNT(CITY) counts non-null values in that column - rows with no city are
--     skipped entirely.
       COUNT(CITY) AS CITY_VALUES,

--   COUNT(DISTINCT CITY) counts how many DIFFERENT cities appear. Reading the
--     three side by side tells you about nulls and about repetition at once.
       COUNT(DISTINCT CITY) AS DIFFERENT_CITIES

-- FROM: the table all three are computed over.
FROM CUSTOMER;

-- Example 4-3.13
-- SELECT: the same three shapes of count, pointed at the line-item table.
--   How many invoice lines exist in total.
SELECT COUNT(*) AS LINE_COUNT,

--   How many different invoices those lines belong to.
       COUNT(DISTINCT INVOICE_NUM) AS INVOICES,

--   How many different items were ordered. Six lines can cover three invoices and
--     five items at the same time, which is exactly what these numbers show.
       COUNT(DISTINCT ITEM_ID) AS ITEMS

-- FROM: the table being read.
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
