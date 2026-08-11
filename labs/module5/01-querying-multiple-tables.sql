-- ======================================================================
-- Module 5 · Querying Multiple Tables
-- ======================================================================
--
-- Sections: 5-1
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 5-1  Querying Multiple Tables
-- ----------------------------------------------------------------------


-- Example 5-1.1
-- GOAL: list every customer next to the name of the rep who serves that account.
-- SELECT: the four columns the answer will contain. Each one is written as
--   TABLE.COLUMN, so it is plain that two values are read out of CUSTOMER and
--   two out of REP.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME, REP.FIRST_NAME

-- FROM: puts both tables in play. On its own this line pairs every customer with
--   every rep - 4 customers x 3 reps = 12 pairings, most of them nonsense.
FROM CUSTOMER, REP

-- WHERE: the matching condition, and the line that turns those 12 pairings into
--   a join. A pairing survives only when the rep number stored on the customer
--   row equals the rep number on the rep row, which leaves 4 real rows.
WHERE CUSTOMER.REP_NUM = REP.REP_NUM

-- ORDER BY: sorts the surviving rows by customer number. It decides the order
--   rows are printed in, never which rows match.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- >>> EXERCISE 1  (section 5-1, seed: kimtay_full)
-- Hint: The starter already joins the two tables correctly - it is only selecting from one of them. Add REP.LAST_NAME and REP.FIRST_NAME to the column list. The row count does not change; the rows just get wider.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Example 5-1.3
-- GOAL: the same join, narrowed to customers with a credit limit of 7500 or more.
-- SELECT: three output columns - two read from CUSTOMER, one read from REP.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME

-- FROM: the two tables being joined.
FROM CUSTOMER, REP

-- WHERE: the matching condition - which customer row belongs with which rep row.
WHERE CUSTOMER.REP_NUM = REP.REP_NUM

-- AND: an ordinary business restriction, exactly like the ones in Module 4.
--   Nothing about it is join-specific. Both conditions have to be true, so the
--   4 joined rows become the 2 whose credit limit clears 7500.
  AND CUSTOMER.CREDIT_LIMIT >= 7500

-- ORDER BY: sorts those two rows by customer number.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- >>> EXERCISE 2  (section 5-1, seed: kimtay_full)
-- Hint: Add one more line with AND under the matching condition, restricting CUSTOMER.CREDIT_LIMIT. Four rows should become two.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Example 5-1.5
-- GOAL: show what the row count does when the matching condition is left out.
-- SELECT: COUNT(*) counts the rows this query produces, and AS gives that single
--   number the heading COMBINATIONS.
SELECT COUNT(*) AS COMBINATIONS

-- FROM: two tables and no WHERE clause anywhere, so nothing restricts the
--   pairings. Each of the 4 customers is paired with each of the 3 reps, and the
--   answer comes back 12 - eight rows more than the real join returned.
FROM CUSTOMER, REP;

-- Example 5-1.6
-- GOAL: one summary line per rep - how many customers, and their total balance.
-- SELECT: the grouping column first, then two aggregates. COUNT(*) counts the
--   rows inside each group, SUM adds up the balances inside each group, and AS
--   gives each computed value a readable heading.
SELECT REP.LAST_NAME, COUNT(*) AS NUM_CUSTOMERS, SUM(CUSTOMER.BALANCE) AS TOTAL_BALANCE

-- FROM: the two tables. Naming REP before CUSTOMER changes nothing - the order
--   of tables in FROM is cosmetic.
FROM REP, CUSTOMER

-- WHERE: the matching condition. It is applied BEFORE the grouping, so the
--   aggregates are computed over joined rows and never over the raw tables.
WHERE REP.REP_NUM = CUSTOMER.REP_NUM

-- GROUP BY: collapses the joined rows into one output row per rep last name.
--   Kaiser's two customers become a single line reading 2.
GROUP BY REP.LAST_NAME

-- ORDER BY: sorts those summary lines alphabetically by last name.
ORDER BY REP.LAST_NAME;

-- >>> EXERCISE 3  (section 5-1, seed: kimtay_full)
-- Hint: Start from the four detail rows, then collapse them: replace the customer columns with COUNT(*) and SUM(CUSTOMER.BALANCE), and add GROUP BY REP.LAST_NAME. Four rows become three.
SELECT REP.LAST_NAME, CUSTOMER.CUSTOMER_NAME, CUSTOMER.BALANCE
FROM REP, CUSTOMER
WHERE REP.REP_NUM = CUSTOMER.REP_NUM
ORDER BY REP.LAST_NAME, CUSTOMER.CUSTOMER_NAME;
