-- ======================================================================
-- Module 4 · Summary of SQL Clauses, Functions, and Operators
-- ======================================================================
--
-- Sections: 4-7
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 4-7  Summary of SQL Clauses, Functions, and Operators
-- ----------------------------------------------------------------------


-- Example 4-7.1
-- SELECT: the grouping column and two aggregates - every column here is either
--   grouped or aggregated, as the rule requires.
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVERAGE_PRICE

-- FROM: the table being read. This is the clause order the engine follows:
FROM ITEM

-- WHERE: 1st - discard individual rows before anything is grouped.
WHERE ON_HAND > 10

-- GROUP BY: 2nd - pile up the survivors, one pile per category.
GROUP BY CATEGORY

-- HAVING: 3rd - discard whole piles, using a condition on an aggregate.
HAVING COUNT(*) > 1

-- ORDER BY: 4th and last - sort what is left for reading.
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
