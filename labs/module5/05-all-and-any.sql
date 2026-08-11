-- ======================================================================
-- Module 5 · All and Any
-- ======================================================================
--
-- Sections: 5-4
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 5-4  All and Any
-- ----------------------------------------------------------------------


-- Example 5-4.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- GOAL: the customers whose balance beats the balance of EVERY customer rep 20
-- handles. Written the MySQL or Oracle way; this is a syntax error in SQLite.
-- SELECT: three columns, including the balance being tested, so you can check the
--   comparison by eye.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE

-- FROM: one table - the subquery reads the same table again, separately.
FROM CUSTOMER

-- WHERE: the subquery returns rep 20's balances, 3512.50 and 0.00. "Greater than
--   ALL" means the row's balance must beat every value in that list, which is
--   the same as beating the largest one. Read it out loud as "balance greater
--   than all of these".
WHERE BALANCE > ALL (SELECT BALANCE FROM CUSTOMER WHERE REP_NUM = '20');

-- Example 5-4.2
-- GOAL: the same question, rewritten so it runs everywhere, SQLite included.
-- SELECT: the same three columns.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE

-- FROM: the outer query reads CUSTOMER.
FROM CUSTOMER

-- WHERE: because "greater than ALL" only ever tests the top of the list, MAX
--   collapses the subquery to the single number 3512.50, and an ordinary
--   comparison does the rest. One row clears it - 1420, at 4820.75.
WHERE BALANCE > (SELECT MAX(BALANCE) FROM CUSTOMER WHERE REP_NUM = '20')

-- ORDER BY: sorts whatever survives by customer number.
ORDER BY CUSTOMER_NUM;

-- Example 5-4.3
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- GOAL: change one keyword and the bar drops a long way - now a balance need only
-- beat the WEAKEST value in the list. MySQL or Oracle; a syntax error in SQLite.
-- SELECT: the same three columns as the ALL version.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE

-- FROM: the outer query reads CUSTOMER.
FROM CUSTOMER

-- WHERE: the subquery returns the same two balances, 3512.50 and 0.00. "Greater
--   than ANY" means greater than at least one of them, which is the same as
--   greater than the smallest. SOME is an exact synonym for ANY.
WHERE BALANCE > ANY (SELECT BALANCE FROM CUSTOMER WHERE REP_NUM = '20');

-- Example 5-4.4
-- GOAL: the ANY version rewritten to run everywhere.
-- SELECT: the same three columns.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE

-- FROM: the outer query reads CUSTOMER.
FROM CUSTOMER

-- WHERE: "greater than ANY" only ever tests the bottom of the list, so MIN
--   collapses the subquery to 0.00 and the test becomes "balance greater than
--   0.00". Three customers clear it. Companion Care Clinic does not, because
--   0.00 is not greater than 0.00.
WHERE BALANCE > (SELECT MIN(BALANCE) FROM CUSTOMER WHERE REP_NUM = '20')

-- ORDER BY: sorts the three surviving rows by customer number.
ORDER BY CUSTOMER_NUM;

-- >>> EXERCISE 20  (section 5-4, seed: kimtay_full)
-- Hint: There is one Accessory item, the Nylon Dog Leash at 11.99, so MAX is 11.99 and the other four items all clear it: AV07, CF21, FT88 and GR15.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- The MySQL/Oracle version would be:
-- --   WHERE PRICE > ALL (SELECT PRICE FROM ITEM WHERE CATEGORY = 'Accessory')
-- -- Rewrite it with MAX so it runs here: which items cost more than
-- -- every Accessory item?
--
-- SELECT ITEM_ID, DESCRIPTION, PRICE
-- FROM ITEM
-- WHERE PRICE >

-- >>> EXERCISE 21  (section 5-4, seed: kimtay_full)
-- Hint: = ANY is IN and returns the three invoiced customers 1120, 1225 and 1420. <> ALL is NOT IN and returns Companion Care Clinic (1310) on its own.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- Translate these two on sight, then run them.
-- -- 1. WHERE CUSTOMER_NUM = ANY (SELECT CUSTOMER_NUM FROM INVOICE)
-- -- 2. WHERE CUSTOMER_NUM <> ALL (SELECT CUSTOMER_NUM FROM INVOICE)
-- -- Write version 1 first using the keyword that runs in SQLite.
--
-- SELECT CUSTOMER_NUM, CUSTOMER_NAME
-- FROM CUSTOMER

-- >>> EXERCISE 22  (section 5-4, seed: staywell_full)
-- Hint: Part (a) clears the bar at 595.00 and returns two rooms, P200 101 and P200 201. Part (b) drops the bar to 450.00 and returns four rooms: P100 101, P200 101, P200 201 and P200 202.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- StayWell is repricing. Property P100 has rooms at 595.00 and 450.00.
-- -- a) Which rooms rent for more than EVERY room at P100?  (ALL -> MAX)
-- -- b) Which rooms rent for more than ANY room at P100?    (ANY -> MIN)
-- -- Write part (a) here, then edit it into part (b).
--
-- SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
-- FROM ROOM
