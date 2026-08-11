-- ======================================================================
-- Module 4 · Grouping
-- ======================================================================
--
-- Sections: 4-5
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 4-5  Grouping
-- ----------------------------------------------------------------------


-- Example 4-5.1
-- SELECT: the grouping column, then two aggregates. Each aggregate is now
--   computed once PER GROUP rather than once over the whole table.
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVG_PRICE

-- FROM: the table being read.
FROM ITEM

-- GROUP BY: sorts the rows into piles, one pile per distinct CATEGORY value, and
--   returns one output row per pile. Four distinct categories means four rows.
GROUP BY CATEGORY;

-- Example 4-5.2
-- SELECT: the grouping column, then an aggregate over a calculation. The
--   multiplication happens per line, and SUM adds those line values within the
--   group - so the arithmetic runs before the aggregation, as you would expect.
SELECT INVOICE_NUM, SUM(NUM_ORDERED * QUOTED_PRICE) AS INVOICE_TOTAL

-- FROM: the line-item table - six rows, before grouping.
FROM INVOICE_LINE

-- GROUP BY: one pile per invoice number, so six lines become three totals.
GROUP BY INVOICE_NUM

-- ORDER BY: sorts the summary rows, largest total first. Sorting by the alias is
--   allowed because ORDER BY runs last of all.
ORDER BY INVOICE_TOTAL DESC;

-- >>> EXERCISE 13  (section 4-5, seed: kimtay_full)
-- Hint: MIN and MAX group the same way COUNT does. Expect Habitat first with 2, 27.75 and 64.99, then the three single-item categories, where the lowest and the highest are the same price.
-- One row per category, with a count:
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY;

-- Your turn: keep the count, add the cheapest and the dearest price
-- in each category, and sort so the biggest category comes first.

-- Example 4-5.4
-- GOAL: a deliberate error, and the rule that catches everybody.
-- SELECT: BROKEN. Every column here must either appear in GROUP BY or sit inside
--   an aggregate. CATEGORY is grouped and COUNT(*) is aggregated, but DESCRIPTION
--   is neither. The Habitat pile holds two rows with two different descriptions,
--   and the query has asked for one - there is no correct answer to give.
SELECT CATEGORY, DESCRIPTION, COUNT(*) AS ITEM_COUNT

-- FROM: the table being read.
FROM ITEM

-- GROUP BY: one pile per category. MySQL rejects the whole statement because of
--   its ONLY_FULL_GROUP_BY setting; SQLite runs it and picks a description at
--   random from the pile, which is worse - a wrong answer with no warning.
GROUP BY CATEGORY;

-- Example 4-5.5
-- SELECT: the same three columns, now legal, because of the line below.
SELECT CATEGORY, DESCRIPTION, COUNT(*) AS ITEM_COUNT

-- FROM: the table being read.
FROM ITEM

-- GROUP BY: adding DESCRIPTION makes a pile out of each distinct CATEGORY and
--   DESCRIPTION combination, so every column in SELECT is now either grouped or
--   aggregated. This is the "finer grouping" fix; the other fix is to drop
--   DESCRIPTION from the SELECT list and keep the coarse summary.
GROUP BY CATEGORY, DESCRIPTION

-- ORDER BY: sorts the groups for reading.
ORDER BY CATEGORY, DESCRIPTION;

-- Example 4-5.6
-- SELECT: two grouping columns plus a count.
SELECT REP_NUM, CITY, COUNT(*) AS CUSTOMER_COUNT

-- FROM: the table being read.
FROM CUSTOMER

-- GROUP BY: listing two columns makes one pile per distinct COMBINATION of the
--   two - not two separate sets of piles. This answers "which rep covers which
--   city, and how many customers there", a question neither column answers alone.
GROUP BY REP_NUM, CITY

-- ORDER BY: sorts the summary rows by rep, then by city.
ORDER BY REP_NUM, CITY;

-- Example 4-5.7
-- SELECT: the grouping column and a count.
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT

-- FROM: the table being read.
FROM ITEM

-- GROUP BY: one pile per category.
GROUP BY CATEGORY

-- HAVING: filters the GROUPS, after they have been formed and counted. This is
--   the one place an aggregate may appear in a condition, and it is exactly what
--   WHERE cannot do - WHERE runs before the piles exist. Only the category
--   holding more than one item survives.
HAVING COUNT(*) > 1;

-- Example 4-5.8
-- SELECT: the grouping column and a count.
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT

-- FROM: the table being read.
FROM CUSTOMER

-- WHERE: filters ROWS, before any grouping happens. Customers owing 1000.00 or
--   less are removed here and never reach a pile at all.
WHERE BALANCE > 1000.00

-- GROUP BY: piles up whatever rows survived the WHERE, one pile per rep.
GROUP BY REP_NUM

-- ORDER BY: sorts the summary rows.
ORDER BY REP_NUM;

-- Example 4-5.9
-- SELECT: the grouping column and a count.
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT

-- FROM: the table being read - every row this time, with no WHERE.
FROM CUSTOMER

-- GROUP BY: one pile per rep, containing all of that rep's customers.
GROUP BY REP_NUM

-- HAVING: filters the finished piles on a total computed from every row in the
--   pile. Note the difference from the previous query: there a customer owing
--   nothing was thrown out before counting, here it is still counted and simply
--   contributes 0.00 to its rep's total.
HAVING SUM(BALANCE) > 1000.00

-- ORDER BY: sorts the summary rows.
ORDER BY REP_NUM;

-- Example 4-5.10
-- SELECT: the grouping column and two aggregates.
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT, SUM(BALANCE) AS TOTAL_OWED

-- FROM: the table being read.
FROM CUSTOMER

-- WHERE: step 1 - throw out individual rows. Only balances above 1000.00 go on.
WHERE BALANCE > 1000.00

-- GROUP BY: step 2 - pile up what is left, one pile per rep.
GROUP BY REP_NUM

-- HAVING: step 3 - throw out whole piles whose total is too small. WHERE and
--   HAVING are doing different jobs in the same statement, which is the point of
--   this example: rows first, groups second.
HAVING SUM(BALANCE) > 2000.00

-- ORDER BY: step 4 - sort what survived, largest total first.
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
