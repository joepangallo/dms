-- ======================================================================
-- Module 5 · Aliases, Self-Joins, and Joining Several Tables
-- ======================================================================
--
-- Sections: 5-2e-5-2h
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 5-2e to 5-2h  Aliases, Self-Joins, and Joining Several Tables
-- ----------------------------------------------------------------------


-- Example 5-2e-5-2h.1
-- GOAL: show the smallest possible use of an alias - a short, temporary name for
-- a table that lives only as long as this one statement.
-- SELECT: C.CUSTOMER_NAME means exactly what CUSTOMER.CUSTOMER_NAME means. The
--   alias is already usable here even though it is defined on the next line.
SELECT C.CUSTOMER_NAME

-- FROM: this is where the alias is created - table name, then the short name.
--   The word AS is optional and most people leave it out.
FROM CUSTOMER AS C

-- WHERE: an ordinary condition, written through the alias. One row comes back,
--   Whiskers & Wags Boutique, the only customer of rep 65.
WHERE C.REP_NUM = '65';

-- >>> EXERCISE 8  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: Give REP the alias R in the FROM clause, then use R on both sides of the matching condition.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- SELECT C.CUSTOMER_NUM, C.CUSTOMER_NAME, R.LAST_NAME, R.RATE
-- FROM CUSTOMER C, REP ___
-- WHERE C.REP_NUM = ___.REP_NUM
-- ORDER BY C.CUSTOMER_NUM;

-- Example 5-2e-5-2h.3
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- GOAL: a deliberate error. Once a table has an alias, the full table name is no
-- longer available anywhere in that statement.
-- SELECT: WRONG. C is defined below, so CUSTOMER is no longer a usable name and
--   the engine has no table by that name to look the column up in. SQLite says
--   "no such column: CUSTOMER.CUSTOMER_NUM"; MySQL and Oracle raise their own
--   version of the same unknown-table error. The fix is to write C.CUSTOMER_NUM.
SELECT CUSTOMER.CUSTOMER_NUM

-- FROM: two aliases are defined here, C and R. From this point on they are the
--   only names by which the two tables can be reached.
FROM CUSTOMER C, REP R

-- WHERE: this line is correct - it uses the aliases on both sides. It is only
--   the SELECT list above that breaks the statement.
WHERE C.REP_NUM = R.REP_NUM;

-- Example 5-2e-5-2h.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- GOAL: a second deliberate error, the one that makes aliases compulsory in a
-- self-join rather than merely convenient.
-- SELECT: WRONG. With two copies of CUSTOMER in play, a bare CUSTOMER_NUM could
--   mean the one from copy A or the one from copy B, and the engine refuses to
--   guess. SQLite says "ambiguous column name: CUSTOMER_NUM"; MySQL and Oracle
--   report the same ambiguity in their own wording. Write A.CUSTOMER_NUM.
SELECT CUSTOMER_NUM

-- FROM: the same table opened twice, under two different names. This is all a
--   self-join is - an ordinary join whose two sides happen to be one table.
FROM CUSTOMER A, CUSTOMER B

-- WHERE: the matching condition between the two copies, correctly qualified.
WHERE A.REP_NUM = B.REP_NUM;

-- >>> EXERCISE 9  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: Run it as written and count the rows before you read on. Six is more than you wanted.
SELECT A.CUSTOMER_NUM, B.CUSTOMER_NUM, A.REP_NUM
FROM CUSTOMER A, CUSTOMER B
WHERE A.REP_NUM = B.REP_NUM
ORDER BY A.CUSTOMER_NUM, B.CUSTOMER_NUM;

-- >>> EXERCISE 10  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: Put a less-than sign between the two primary key columns, then try <> instead and compare the row counts.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- SELECT A.CUSTOMER_NUM, A.CUSTOMER_NAME, B.CUSTOMER_NUM, B.CUSTOMER_NAME
-- FROM CUSTOMER A, CUSTOMER B
-- WHERE A.REP_NUM = B.REP_NUM
-- AND A.CUSTOMER_NUM ___ B.CUSTOMER_NUM;

-- >>> EXERCISE 11  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: One row comes back, AV07 with FT88, because Habitat is the only category holding two items.
SELECT A.ITEM_ID, B.ITEM_ID, A.CATEGORY
FROM ITEM A, ITEM B
WHERE A.CATEGORY = B.CATEGORY
AND A.ITEM_ID < B.ITEM_ID;

-- >>> EXERCISE 12  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: Three aliases, three conditions: match the copies, attach the rep, restrict the pair.
SELECT R.LAST_NAME, A.CUSTOMER_NAME, B.CUSTOMER_NAME
FROM CUSTOMER A, CUSTOMER B, REP R
WHERE A.REP_NUM = B.REP_NUM
AND A.REP_NUM = R.REP_NUM
AND A.CUSTOMER_NUM < B.CUSTOMER_NUM;

-- >>> EXERCISE 13  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: The last link joins INVOICE_LINE to ITEM, so the missing alias is IT.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION, IL.NUM_ORDERED
-- FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
-- WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
-- AND I.INVOICE_NUM = IL.INVOICE_NUM
-- AND IL.ITEM_ID = ___.ITEM_ID
-- ORDER BY I.INVOICE_NUM, IT.ITEM_ID;

-- >>> EXERCISE 14  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: Put the category in single quotes: 'Habitat'. Two rows come back, both on invoice 50712.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION
-- FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
-- WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
-- AND I.INVOICE_NUM = IL.INVOICE_NUM
-- AND IL.ITEM_ID = IT.ITEM_ID
-- AND IT.CATEGORY = ___
-- ORDER BY IT.ITEM_ID;

-- >>> EXERCISE 15  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: Five tables, four conditions. Kaiser's two lines extend to 127.50 and 23.98.
SELECT R.LAST_NAME, C.CUSTOMER_NAME, IT.DESCRIPTION,
       IL.NUM_ORDERED * IL.QUOTED_PRICE AS EXTENDED
FROM REP R, CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
WHERE R.REP_NUM = C.REP_NUM
AND C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND I.INVOICE_NUM = IL.INVOICE_NUM
AND IL.ITEM_ID = IT.ITEM_ID
ORDER BY R.LAST_NAME, IT.DESCRIPTION;

-- >>> EXERCISE 16  (section 5-2e-5-2h, seed: kimtay_full)
-- Hint: Group by the invoice number, qualified with its alias. Totals are 151.48, 100.25 and 120.49.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS INVOICE_TOTAL
-- FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL
-- WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
-- AND I.INVOICE_NUM = IL.INVOICE_NUM
-- GROUP BY ___, C.CUSTOMER_NAME
-- ORDER BY I.INVOICE_NUM;
