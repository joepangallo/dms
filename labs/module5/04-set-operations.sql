-- ======================================================================
-- Module 5 · Set Operations
-- ======================================================================
--
-- Sections: 5-3
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 5-3  Set Operations
-- ----------------------------------------------------------------------


-- Example 5-3.1
-- GOAL: one combined list - every customer served by rep 20, together with every
-- customer that has an invoice, each appearing only once.
-- SELECT: the first of two complete SELECT statements. Its two columns fix the
--   shape of the answer, and its headings are the headings of the whole result.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: the first statement reads CUSTOMER.
FROM CUSTOMER

-- WHERE: first set - the customers of rep 20. That is 1120 and 1310.
WHERE REP_NUM = '20'

-- UNION: folds the two results into one and removes duplicate rows. Both sides
--   must be union compatible: same number of columns, same order, compatible
--   types. The names do not have to match.
UNION

-- SELECT: the second complete statement begins here. Two columns again.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: it happens to read the same table, but it does not have to.
FROM CUSTOMER

-- WHERE: second set - the customers that appear in INVOICE. That is 1120, 1225
--   and 1420. Customer 1120 is on both lists, and UNION keeps one copy of it,
--   so the combined answer is four rows rather than five.
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)

-- ORDER BY: a set operation is ONE statement, so it gets ONE ORDER BY, and it
--   belongs after the last SELECT. Sorting the first half on its own is an error.
ORDER BY CUSTOMER_NUM;

-- Example 5-3.2
-- GOAL: every city named in either table, with nothing removed.
-- SELECT / FROM: the first list - the four city values stored in CUSTOMER.
SELECT CITY FROM CUSTOMER

-- UNION ALL: stacks the two lists and stops there. Nothing is compared and
--   nothing is discarded, so a city held by several rows is listed several times.
UNION ALL

-- SELECT / FROM: the second list - the three city values stored in REP. Seven
--   rows come back in all: Maple Grove, Northfield, Maple Grove, Brookville,
--   then Maple Grove, Maple Grove, Brookville.
SELECT CITY FROM REP;

-- Example 5-3.3
-- GOAL: the same two lists, with the one keyword changed, to see what duplicate
-- removal costs and buys.
-- SELECT / FROM: the first list - the cities in CUSTOMER.
SELECT CITY FROM CUSTOMER

-- UNION: same stacking as UNION ALL, plus a duplicate check. Seven rows shrink
--   to the three distinct cities. That check is real work, which is the reason
--   UNION ALL exists at all.
UNION

-- SELECT / FROM: the second list - the cities in REP.
SELECT CITY FROM REP

-- ORDER BY: sorts the combined three-row result. It sits at the very end of the
--   whole statement, never inside either half.
ORDER BY CITY;

-- Example 5-3.4
-- GOAL: the overlap - customers who are served by rep 20 AND have an invoice.
-- SELECT: the first statement, two columns.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: it reads CUSTOMER.
FROM CUSTOMER

-- WHERE: first set - rep 20's customers, 1120 and 1310.
WHERE REP_NUM = '20'

-- INTERSECT: keeps only rows produced by BOTH sides, and removes duplicates.
--   Order does not matter here: swapping the two halves asks the same question.
INTERSECT

-- SELECT: the second statement, the same two columns in the same order.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: it reads CUSTOMER too.
FROM CUSTOMER

-- WHERE: second set - the invoiced customers, 1120, 1225 and 1420. Only 1120 is
--   on both lists, so one row comes back. 1310 belongs to rep 20 but has never
--   been billed, and 1225 and 1420 have invoices but belong to other reps.
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE);

-- Example 5-3.5
-- GOAL: the subtraction - rep 20's customers who have never been billed.
-- SELECT: the first statement, two columns.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: it reads CUSTOMER.
FROM CUSTOMER

-- WHERE: first set - rep 20's customers, 1120 and 1310.
WHERE REP_NUM = '20'

-- EXCEPT: keeps the rows the first statement produced that the second did not
--   also produce. Order matters here in a way it never does for UNION or
--   INTERSECT: reverse the halves and you are asking which invoiced customers do
--   not belong to rep 20, which answers 1225 and 1420 instead. Oracle spells
--   this operation MINUS.
EXCEPT

-- SELECT: the second statement, matching shape.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: it reads CUSTOMER as well.
FROM CUSTOMER

-- WHERE: second set - the invoiced customers. Removing them from the first set
--   leaves one row, 1310 Companion Care Clinic.
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE);

-- Example 5-3.6
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- GOAL: a deliberate error - the mistake you are most likely to make with a set
-- operation, so that you recognise the message instead of guessing at it.
-- SELECT: the first statement returns TWO columns.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: it reads CUSTOMER.
FROM CUSTOMER

-- UNION: the two halves are not union compatible, and the engine rejects the
--   statement here without executing anything. SQLite says "SELECTs to the left
--   and right of UNION do not have the same number of result columns".
UNION

-- SELECT: the second statement returns ONE column, and that is the whole problem.
--   The fix is always the same - add or remove a column until the counts agree.
SELECT REP_NUM

-- FROM: it reads REP.
FROM REP;

-- Example 5-3.7
-- GOAL: a single Brookville contact list, drawn from two different tables. The
-- halves of a union do not have to read the same table - only to match in shape.
-- SELECT: two columns, each renamed with AS. Headings always come from the FIRST
--   SELECT, which is why it is worth putting the aliases here.
SELECT CUSTOMER_NUM AS ID_NUM, CUSTOMER_NAME AS NAME

-- FROM: the first half reads CUSTOMER.
FROM CUSTOMER

-- WHERE: restricts the first half to Brookville - customer 1420.
WHERE CITY = 'Brookville'

-- UNION: stacks the two lists and drops duplicates. Two columns on each side,
--   and a number lines up with a number, text with text, so the two are
--   union compatible.
UNION

-- SELECT: the second half returns a rep number and a last name. It never mentions
--   ID_NUM or NAME, and does not need to - only the count, order and types matter.
SELECT REP_NUM, LAST_NAME

-- FROM: the second half reads REP.
FROM REP

-- WHERE: restricts the second half to Brookville - rep 65, Perez.
WHERE CITY = 'Brookville'

-- ORDER BY: sorts the combined result, and must use the heading the first SELECT
--   established. ORDER BY CUSTOMER_NUM would be an error here.
ORDER BY ID_NUM;

-- >>> EXERCISE 17  (section 5-3, seed: kimtay_full)
-- Hint: CF21 is the only item that appears on both invoices, so it is the only row UNION collapses. Four rows becomes three: CF21, DG04, GR15.
-- Invoice 50710 lists CF21 and DG04. Invoice 50711 lists CF21 and GR15.
-- Step 1: run this and count the rows.
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710'
UNION ALL
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50711';

-- Step 2: change UNION ALL to UNION, run it again, and explain the difference.

-- >>> EXERCISE 18  (section 5-3, seed: kimtay_full)
-- Hint: INTERSECT returns Access Pet Center (1120) on its own. Swap in EXCEPT and you get Companion Care Clinic (1310) on its own, because 1310 belongs to rep 20 and has no invoice.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- List 1 (already written): customers served by rep 20.
-- -- List 2: customers that have at least one invoice.
-- -- Finish this as an INTERSECT to find customers on BOTH lists,
-- -- then change INTERSECT to EXCEPT and run it again.
--
-- SELECT CUSTOMER_NUM, CUSTOMER_NAME
-- FROM CUSTOMER
-- WHERE REP_NUM = '20'

-- >>> EXERCISE 19  (section 5-3, seed: staywell_full)
-- Hint: UNION gives S001, S003 and S004. INTERSECT gives S004 alone, the one student who is from Ohio and leases at P200. EXCEPT gives S001 alone, from Ohio but leasing at P100.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- StayWell wants to compare two lists of students:
-- --   A: students whose HOME_STATE is 'OH'
-- --   B: students who lease a room at property P200
-- -- Write all three: A UNION B, A INTERSECT B, and A EXCEPT B.
-- -- List A is started for you, with no semicolon yet, so you can add
-- -- the keyword and List B straight onto the end of it.
--
-- SELECT STUDENT_ID, LAST_NAME
-- FROM STUDENT
-- WHERE HOME_STATE = 'OH'
