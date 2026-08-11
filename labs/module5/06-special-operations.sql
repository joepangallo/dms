-- ======================================================================
-- Module 5 · Special Operations
-- ======================================================================
--
-- Sections: 5-5
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 5-5  Special Operations
-- ----------------------------------------------------------------------


-- Example 5-5.1
-- GOAL: the very first join of this module, rewritten in the modern INNER JOIN
-- ... ON form. Same four rows, different words.
-- SELECT: the three output columns, qualified as always.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME

-- FROM: the two tables and the matching condition now sit on one line. INNER JOIN
--   names the second table and ON carries the condition, so the WHERE clause is
--   left free for real business filters. Forgetting ON is a syntax error you
--   cannot miss, which is why this form is worth preferring.
FROM CUSTOMER INNER JOIN REP ON CUSTOMER.REP_NUM = REP.REP_NUM

-- ORDER BY: sorts the four rows by customer number.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Example 5-5.2
-- GOAL: put a description on every invoice line by walking INVOICE to
-- INVOICE_LINE to ITEM. Inner joins chain - one JOIN ... ON per hop.
-- SELECT: one column from each of the three tables.
SELECT INVOICE.INVOICE_NUM, ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED

-- FROM: link 1 - each invoice is joined to its own line items. Everything to the
--   left of the next INNER JOIN behaves as a single combined table.
FROM INVOICE INNER JOIN INVOICE_LINE ON INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM

-- Link 2 - that combined result is then joined to ITEM. Three tables need two
-- JOIN ... ON clauses, the same count as the two matching conditions the older
-- comma-and-WHERE form would have needed. Six rows come back.
INNER JOIN ITEM ON INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID

-- ORDER BY: by invoice, then by description within each invoice.
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Example 5-5.3
-- GOAL: ask an inner join for every customer and its invoices, and watch what
-- silently goes missing.
-- SELECT: two customer columns and the invoice number.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM

-- FROM: INNER JOIN keeps only the pairs that match on both sides. Customer 1310
--   has no row in INVOICE, so it has no partner and is dropped - with no warning
--   of any kind. Four customers go in, three rows come out.
FROM CUSTOMER INNER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- ORDER BY: sorts the three surviving rows by customer number.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Example 5-5.4
-- GOAL: the same question, with the unmatched customer kept in the answer.
-- SELECT: the same three columns as the inner join above.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM

-- FROM: LEFT JOIN keeps every row of the table written on the LEFT of the
--   keyword, matched or not. CUSTOMER is on the left, so CUSTOMER is the table
--   being protected. Where a customer has no invoice, SQL invents one row's
--   worth of NULLs for the columns that came from the right-hand table, so 1310
--   comes back with a null invoice number. Four rows this time.
FROM CUSTOMER LEFT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- ORDER BY: sorts all four rows by customer number.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Example 5-5.5
-- GOAL: find the gaps - the rows that have no match at all - in two steps.
-- SELECT: only the customer columns. The invoice column is used for testing and
--   would be null on every row that survives anyway.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME

-- FROM: step 1 - LEFT JOIN keeps all four customers, filling the INVOICE columns
--   with NULL wherever no invoice matched.
FROM CUSTOMER LEFT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- WHERE: step 2 - keep only the rows the join had to fill in. IS NULL is the only
--   way to test for a null; = NULL never matches anything, not even another null.
--   Here the test can be true only for a customer the join failed to match, so
--   the whole query reads as "customers with no invoice". One row: 1310.
WHERE INVOICE.INVOICE_NUM IS NULL;

-- Example 5-5.6
-- GOAL: see the product - what SQL does when you never say how two tables relate.
-- SELECT: one identifying column from each table, so the pattern is easy to read.
SELECT CUSTOMER.CUSTOMER_NUM, REP.REP_NUM

-- FROM: two tables listed with a comma and nothing else. There is no WHERE clause
--   anywhere, so nothing restricts the pairings and every customer is paired with
--   every rep: 4 x 3 = 12 rows, eight of them nonsense. This is the accident you
--   cause by adding a table to FROM and forgetting its matching condition.
FROM CUSTOMER, REP

-- ORDER BY: sorting by both columns makes the regular repeating pattern - the
--   symptom of an accidental product - obvious on sight.
ORDER BY CUSTOMER.CUSTOMER_NUM, REP.REP_NUM;

-- Example 5-5.7
-- GOAL: supply the missing condition and watch the product collapse back into an
-- inner join. This is the first query of the lesson wearing different clothes.
-- SELECT: two customer columns and the rep's last name.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME

-- FROM: the same comma-separated pair of tables that produced the 12-row product.
FROM CUSTOMER, REP

-- WHERE: this single line is the entire difference. It throws away the eight
--   pairings where the customer's rep number does not equal the rep's, leaving
--   the same four rows the INNER JOIN ... ON version returned.
WHERE CUSTOMER.REP_NUM = REP.REP_NUM

-- ORDER BY: sorts the four rows by customer number.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- >>> EXERCISE 23  (section 5-5, seed: kimtay_full)
-- Hint: The inner join returns three rows and hides Companion Care Clinic. The LEFT JOIN returns four, with an empty INVOICE_NUM on row 1310. Adding WHERE INVOICE.INVOICE_NUM IS NULL narrows it to that one row. WHERE always goes before ORDER BY.
-- Run these three one at a time and compare the row counts.
-- 1. Inner join: which customers drop out, and why?
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER INNER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- 2. Now change INNER JOIN to LEFT JOIN and run it again.
-- 3. Then put this line just before the ORDER BY and run it a third time:
--      WHERE INVOICE.INVOICE_NUM IS NULL

-- >>> EXERCISE 24  (section 5-5, seed: kimtay_full)
-- Hint: Five rows. One has an empty customer and invoice 50713, the orphan invoice. One has Companion Care Clinic and an empty invoice. Both unmatched sides survive, which is what makes the join full. Without the DELETE on the first line, a second run would fail on the primary key.
-- FULL OUTER JOIN keeps unmatched rows from BOTH sides. The shipped data
-- has no orphan invoice, so this INSERT makes one first: invoice 50713
-- points at customer 9999, which does not exist.
-- The DELETE on the first line clears any 50713 left over from a previous
-- run, so you can run the whole box as many times as you like.
-- Press Reset when you are done to restore the shipped data.

DELETE FROM INVOICE WHERE INVOICE_NUM = '50713';

INSERT INTO INVOICE (INVOICE_NUM, CUSTOMER_NUM, INVOICE_DATE)
VALUES ('50713', '9999', '2026-06-16');

SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER FULL OUTER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM, INVOICE.INVOICE_NUM;

-- >>> EXERCISE 25  (section 5-5, seed: kimtay_full)
-- Hint: The product is twelve rows, 4 times 3. Adding the WHERE condition cuts it to the four rows that are true, one per customer. FROM CUSTOMER CROSS JOIN REP also returns twelve and states the intent openly.
-- No join condition anywhere. Predict the row count before you run it:
-- CUSTOMER has 4 rows, REP has 3.
SELECT COUNT(*) AS ROW_COUNT FROM CUSTOMER, REP;

-- Then run the rows themselves, and finally add the missing condition
--      WHERE CUSTOMER.REP_NUM = REP.REP_NUM
-- to collapse the product into the inner join you actually wanted.

-- >>> EXERCISE 26  (section 5-5, seed: staywell_full)
-- Hint: Part (a) gives five rows and P200 room 101 has an empty LEASE_ID, so it is the vacant one. Part (b) also gives five rows, but for the opposite reason: L001 appears twice because it has two payments, and L004 appears once with an empty payment.
-- The starter below is deliberately unfinished -- it has a blank to fill in,
-- or stops mid-statement. It is commented out so this file still runs
-- straight through. Uncomment it, complete it, then run it.
-- -- Two gap-finding questions for StayWell. Use LEFT JOIN for both.
-- -- a) Every room, with its lease id, including rooms nobody leases.
-- -- b) Every lease, with its payments, including leases with no payment.
-- -- Part (a) is started for you: ROOM's key is two columns, so the ON
-- -- clause needs both, joined with AND.
--
-- SELECT ROOM.PROPERTY_ID, ROOM.ROOM_NUM, LEASE.LEASE_ID
-- FROM ROOM LEFT JOIN LEASE ON
