-- ======================================================================
-- Module 4 · Summary of SQL Clauses, Functions, and Operators
-- ======================================================================
--
-- Sections: 4-7
-- Load first: 00-setup-both.sql   (has every table this file touches)
--             individual seeds used here: kimtay_full
--
-- Examples are the statements shown in the lesson. Exercises are the
-- starter queries from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Section 4-7 -- Summary of SQL Clauses, Functions, and Operators
-- ----------------------------------------------------------------------

-- Example 4-7.1
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVERAGE_PRICE
FROM ITEM
WHERE ON_HAND > 10
GROUP BY CATEGORY
HAVING COUNT(*) > 1
ORDER BY CATEGORY;

-- >>> EXERCISE 16  (section 4-7, seed: kimtay_full)
-- Hint: As written you get one row, Habitat. Delete the HAVING line and run it again to see the three single-item groups it was holding back, for four rows in total.
-- All six clauses, in the order you write them.
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVERAGE_PRICE
FROM ITEM
WHERE ON_HAND > 10
GROUP BY CATEGORY
HAVING COUNT(*) > 1
ORDER BY CATEGORY;
