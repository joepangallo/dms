-- ======================================================================
-- Module 5 · Module summary, key terms, review questions, case exercises
-- ======================================================================
--
-- Sections: Summary, Key Terms, Review, Case Exercises
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Module Summary
-- ----------------------------------------------------------------------


-- >>> EXERCISE 27  (section Summary, seed: kimtay_full)
-- Hint: Companion Care Clinic has no invoice, so an inner join drops it and a LEFT JOIN keeps it. Count I.INVOICE_NUM rather than *: the padded row is still a row, so COUNT(*) would report 1 for the clinic instead of 0.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- List every KimTay customer with the number of invoices they have,
-- -- including the customer who has never been invoiced.
-- -- Four rows come back, and one of the counts is 0.

-- ----------------------------------------------------------------------
-- Key Terms
-- ----------------------------------------------------------------------


-- >>> EXERCISE 28  (section Key Terms, seed: kimtay_full)
-- Hint: The self-join returns one row, Access Pet Center paired with Companion Care Clinic in Maple Grove. The union returns three cities. The correlated EXISTS returns the three customers that have an invoice, leaving out Companion Care Clinic.
-- Alias plus self-join: two KimTay customers that share a city.
SELECT F.CUSTOMER_NAME AS FIRST_ONE, S.CUSTOMER_NAME AS SECOND_ONE, F.CITY
FROM CUSTOMER F, CUSTOMER S
WHERE F.CITY = S.CITY
  AND F.CUSTOMER_NUM < S.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Review Questions
-- ----------------------------------------------------------------------


-- >>> EXERCISE 29  (section Review, seed: both_full)
-- Hint: KimTay: 3 reps, 4 customers, 3 invoices, 6 invoice lines, 5 items. StayWell: 2 managers, 2 properties, 5 rooms, 4 students, 4 leases, 4 payments. Those eleven numbers let you predict most row counts in your head.
-- Scratch pad. Predict the answer, then check it here.
-- Start with the row counts you should be able to state from memory:
SELECT 'REP' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM REP
UNION ALL SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER
UNION ALL SELECT 'INVOICE', COUNT(*) FROM INVOICE
UNION ALL SELECT 'INVOICE_LINE', COUNT(*) FROM INVOICE_LINE
UNION ALL SELECT 'ITEM', COUNT(*) FROM ITEM;

-- ----------------------------------------------------------------------
-- Case Exercises
-- ----------------------------------------------------------------------


-- >>> EXERCISE 30  (section Case Exercises, seed: both_full)
-- Hint: Expected counts: 3 rows, 2 rows, 4 rows, 1 row, 1 row. Rep 20 has one invoiced customer and therefore one invoice, so exercise 2 returns two descriptions with or without DISTINCT; more than two means the rep 20 filter is missing or a linking condition is. In exercise 3 every student already has a lease, so the join that can drop Jason Park is the one to PAYMENT: if you get three rows, make that join LEFT.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- Both databases are loaded. Write each answer under its comment,
-- -- run it, then compare the row count with the one you predicted.
--
-- -- 1. Every invoice with its date, customer name and rep last name.
--
--
-- -- 2. The distinct items on invoices belonging to rep 20's customers.
--
--
-- -- 3. Every student and the total paid so far, including one who has paid nothing.
--
--
-- -- 4. Rooms that have never appeared on a lease.
--
--
-- -- 5. Cities where KimTay has a customer but no rep.
