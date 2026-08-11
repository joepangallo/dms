-- ======================================================================
-- Module 5 · Comparing Joins, IN, and EXISTS
-- ======================================================================
--
-- Sections: 5-2
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 5-2  Comparing Joins, IN, and EXISTS
-- ----------------------------------------------------------------------


-- Example 5-2.1
-- GOAL: the customers located in either of two named cities.
-- SELECT: three columns. Only one table is involved, so nothing has to be
--   qualified with a table name.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY

-- FROM: a single table - this query is not a join at all.
FROM CUSTOMER

-- WHERE: IN is true when the row's CITY equals ANY value inside the parentheses.
--   It is shorthand for CITY = 'Maple Grove' OR CITY = 'Brookville', and the
--   longer the list, the more typing it saves.
WHERE CITY IN ('Maple Grove', 'Brookville')

-- ORDER BY: sorts the matching rows by customer number.
ORDER BY CUSTOMER_NUM;

-- Example 5-2.2
-- GOAL: which customers have at least one invoice - answered with a join.
-- SELECT: DISTINCT throws away duplicate output rows. It is here because a join
--   returns one row per matching PAIR, so a customer holding three invoices
--   would otherwise be listed three times.
SELECT DISTINCT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME

-- FROM: the customer table and the invoice table.
FROM CUSTOMER, INVOICE

-- WHERE: the matching condition, written on the customer number the two tables
--   share. A customer with no invoice matches nothing here and disappears from
--   the result - which is exactly what "has at least one invoice" means.
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- ORDER BY: sorts the surviving customers by number.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Example 5-2.3
-- GOAL: the same question - customers with at least one invoice - written with a
-- subquery instead of a join.
-- SELECT: two columns, both from CUSTOMER. No DISTINCT is needed this time.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: one table only. INVOICE is reached by the subquery below, not by FROM.
FROM CUSTOMER

-- WHERE: the inner SELECT runs first, on its own, and returns a one-column list
--   of the customer numbers that appear in INVOICE. IN then tests each customer
--   once against that finished list, which is why no customer can come back
--   twice and why DISTINCT is unnecessary.
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)

-- ORDER BY: sorts the kept customers by number.
ORDER BY CUSTOMER_NUM;

-- Example 5-2.4
-- GOAL: show which invoices ordered each item, so the duplicate rows a join can
-- produce are visible in the shipped data.
-- SELECT: two columns from ITEM and one from INVOICE_LINE. There is deliberately
--   no DISTINCT here, because the repeats are the point of the example.
SELECT ITEM.ITEM_ID, ITEM.DESCRIPTION, INVOICE_LINE.INVOICE_NUM

-- FROM: the item table plus the line-item table that records what was ordered.
FROM ITEM, INVOICE_LINE

-- WHERE: the matching condition on the item id the two tables share. Item CF21
--   was ordered on two different invoices, so CF21 makes two matching pairs -
--   and a join reports one row per pair. Five items, six rows.
WHERE ITEM.ITEM_ID = INVOICE_LINE.ITEM_ID

-- ORDER BY: two sort columns - by item first, then by invoice within each item.
ORDER BY ITEM.ITEM_ID, INVOICE_LINE.INVOICE_NUM;

-- >>> EXERCISE 4  (section 5-2, seed: kimtay_full)
-- Hint: Your task: leave the starter alone and write a second statement below it that lists the ITEM_ID, DESCRIPTION and PRICE of every item ordered on invoice 50710, using the same IN shape. Run the inner query by itself first - SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710'; returns CF21 and DG04. Those two values are the list the outer query checks against, so expect two rows.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
ORDER BY CUSTOMER_NUM;

-- Example 5-2.6
-- GOAL: customers with at least one invoice - the third way, using EXISTS.
-- SELECT: the two columns to print. Nothing from inside the subquery can ever
--   appear in this list.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: the outer query walks CUSTOMER one row at a time.
FROM CUSTOMER

-- WHERE: EXISTS is a yes-or-no test applied to the customer currently being
--   examined - did the inner query find at least one row? It answers true or
--   false and produces no values of its own.
WHERE EXISTS

    -- SELECT *: the column list is irrelevant, since no value from it is used.
    --   The * reads as "anything at all", which is the question EXISTS asks.
    (SELECT *

     -- FROM: the table being searched for a match.
     FROM INVOICE

     -- WHERE: this line names CUSTOMER, a table of the OUTER query, and that
     --   reference is what makes the subquery correlated: it cannot run on its
     --   own, and it is re-executed for each customer with that customer's
     --   number filled in. Customer 1310 finds no invoice, so EXISTS is false
     --   and that row is dropped.
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)

-- ORDER BY: sorts the three kept customers by number.
ORDER BY CUSTOMER_NUM;

-- Example 5-2.7
-- GOAL: the opposite question - which customers have never been invoiced.
-- SELECT: the two columns to print.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: the outer query walks CUSTOMER one row at a time, as before.
FROM CUSTOMER

-- WHERE: NOT EXISTS flips the test. The customer is kept only when the inner
--   query finds NOTHING. This is the standard pattern for finding rows that have
--   no match at all on the other side.
WHERE NOT EXISTS

    -- SELECT *: again the column list does not matter; only whether a row exists.
    (SELECT *

     -- FROM: the table searched for a match.
     FROM INVOICE

     -- WHERE: the correlation back to the outer row. For each customer in turn
     --   the engine asks "is there an invoice carrying this customer number?"
     --   Only 1310 comes back empty, so only 1310 survives NOT EXISTS.
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)

-- ORDER BY: sorts the result, which here is a single row.
ORDER BY CUSTOMER_NUM;

-- >>> EXERCISE 5  (section 5-2, seed: kimtay_full)
-- Hint: Run the EXISTS version as given, then copy it underneath and add NOT in front of EXISTS in the copy. Three rows from the first, one from the second - between them the two statements account for all four customers.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE EXISTS
    (SELECT *
     FROM INVOICE
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)
ORDER BY CUSTOMER_NUM;

-- Example 5-2.9
-- GOAL: which customers ordered item CF21? The path runs INVOICE_LINE to INVOICE
-- to CUSTOMER, so one IN subquery is nested inside another. SQL evaluates them
-- from the inside out, and so should you when reading.
-- SELECT: the two columns printed at the end. Only CUSTOMER columns are output;
--   the subqueries supply values for testing, never for display.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: the outer query reads CUSTOMER.
FROM CUSTOMER

-- WHERE: step 3, the last test to run. Keep a customer whose number appears in
--   the list the middle subquery returns (1120 and 1420).
WHERE CUSTOMER_NUM IN

    -- SELECT: step 2 returns one column, the customer number on each matching
    --   invoice. This is the list the outer IN tests against.
    (SELECT CUSTOMER_NUM

     -- FROM: the middle query reads INVOICE.
     FROM INVOICE

     -- WHERE: keep an invoice whose number is in the list step 1 returns.
     WHERE INVOICE_NUM IN

         -- SELECT: step 1, the innermost query, runs FIRST. It returns the
         --   invoice numbers that contain item CF21: 50710 and 50711.
         (SELECT INVOICE_NUM

          -- FROM: the innermost query reads the line-item table.
          FROM INVOICE_LINE

          -- WHERE: the only literal value in the whole statement. Both closing
          --   parentheses land here, one for each subquery being closed.
          WHERE ITEM_ID = 'CF21'))

-- ORDER BY: sorts the two customers that survive.
ORDER BY CUSTOMER_NUM;

-- >>> EXERCISE 6  (section 5-2, seed: kimtay_full)
-- Hint: The starter is the innermost layer, and it returns 50710 and 50711. Wrap it in the INVOICE query and run that - two customer numbers. Then wrap that in the CUSTOMER query. Two rows at the end.
SELECT INVOICE_NUM
FROM INVOICE_LINE
WHERE ITEM_ID = 'CF21';

-- Example 5-2.11
-- GOAL: stage 1 of the order detail report - put a readable description on every
-- invoice line, instead of the item id the line actually stores.
-- SELECT: the invoice number and quantity come from INVOICE_LINE; the wording of
--   the item comes from ITEM.
SELECT INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED

-- FROM: two tables, so exactly one matching condition will be needed.
FROM INVOICE_LINE, ITEM

-- WHERE: the matching condition on the shared item id. Because every line item
--   points at a real item, the six line items come back as six rows - a join
--   along a foreign key neither invents rows nor loses any.
WHERE INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID

-- ORDER BY: by invoice, then by description within each invoice.
ORDER BY INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Example 5-2.12
-- GOAL: stage 2 - carry the customer and the invoice date onto every line. Four
-- tables in FROM means three matching conditions, one per link in the chain
-- CUSTOMER to INVOICE to INVOICE_LINE to ITEM.
-- SELECT: five columns drawn from four different tables. This is the reason a
--   join is unavoidable here - a subquery could not put them side by side.
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM, INVOICE.INVOICE_DATE,

-- SELECT (continued): the column list simply wraps onto a second line; SQL does
--   not care where the line breaks fall, only where the commas are.
       ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED

-- FROM: all four tables. Count them, then count the conditions below: four
--   tables always need three links, and one link short makes the count explode.
FROM CUSTOMER, INVOICE, INVOICE_LINE, ITEM

-- WHERE: link 1 - ties each customer to the invoices belonging to it.
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- AND: link 2 - ties each invoice to its own line items.
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM

-- AND: link 3 - ties each line item to the item it refers to. Still six rows,
--   because following foreign keys does not change the number of lines.
  AND INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID

-- ORDER BY: by invoice, then by description within each invoice.
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Example 5-2.13
-- GOAL: stage 3 - the same four-table join, with the money worked out per line.
-- SELECT: three plain columns first, one from each of three tables.
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM, ITEM.DESCRIPTION,

-- SELECT (continued): a calculated column. The multiplication is performed once
--   for each row, and AS names the result so the heading reads LINE_TOTAL rather
--   than the arithmetic itself. Nothing is stored - it exists in the output only.
       INVOICE_LINE.NUM_ORDERED * INVOICE_LINE.QUOTED_PRICE AS LINE_TOTAL

-- FROM: the same four tables as before.
FROM CUSTOMER, INVOICE, INVOICE_LINE, ITEM

-- WHERE: link 1 - customer to invoice.
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- AND: link 2 - invoice to line item.
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM

-- AND: link 3 - line item to item.
  AND INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID

-- ORDER BY: by invoice, then by description.
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Example 5-2.14
-- GOAL: stage 4 - the finished report, restricted to the customers whose rep
-- works out of Maple Grove. Note that the restriction is about reps, yet no rep
-- column appears in the output: that is the situation a subquery is made for.
-- SELECT: the three display columns.
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM, ITEM.DESCRIPTION,

-- SELECT (continued): the calculated line total, named with AS.
       INVOICE_LINE.NUM_ORDERED * INVOICE_LINE.QUOTED_PRICE AS LINE_TOTAL

-- FROM: the four tables the output columns come from.
FROM CUSTOMER, INVOICE, INVOICE_LINE, ITEM

-- WHERE: link 1 - customer to invoice.
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- AND: link 2 - invoice to line item.
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM

-- AND: link 3 - line item to item.
  AND INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID

-- AND: NOT a link - this is the business restriction. The subquery returns the
--   numbers of the reps based in Maple Grove (20 and 35), and IN keeps only the
--   customers whose REP_NUM appears in that list. Six rows become four.
  AND CUSTOMER.REP_NUM IN

-- The subquery reads CITY from REP, not from CUSTOMER. Downtown Aquarium is in
-- Northfield and still qualifies, because its rep is in Maple Grove.
      (SELECT REP_NUM FROM REP WHERE CITY = 'Maple Grove')

-- ORDER BY: by invoice, then by description.
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- >>> EXERCISE 7  (section 5-2, seed: kimtay_full)
-- Hint: Work up one stage at a time and run after each. Six rows through stage 3, four rows once the IN restriction goes on.
SELECT INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED
FROM INVOICE_LINE, ITEM
WHERE INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
ORDER BY INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Example 5-2.16
-- GOAL: turn the detail report into a summary - one total per invoice. Only three
-- tables are needed now, because no item description appears in the output, so
-- there are two matching conditions rather than three.
-- SELECT: the two columns that identify each group.
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM,

-- SELECT (continued): the same multiplication as before, wrapped in SUM so the
--   line totals inside one group are added into a single invoice total.
       SUM(INVOICE_LINE.NUM_ORDERED * INVOICE_LINE.QUOTED_PRICE) AS INVOICE_TOTAL

-- FROM: three tables, so two links.
FROM CUSTOMER, INVOICE, INVOICE_LINE

-- WHERE: link 1 - customer to invoice.
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM

-- AND: link 2 - invoice to line item. Both links are applied before grouping.
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM

-- GROUP BY: collapses the six joined rows into one row per invoice. Every column
--   in SELECT that is not inside an aggregate has to be listed here, which is
--   why CUSTOMER_NAME appears as well as INVOICE_NUM.
GROUP BY CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM

-- ORDER BY: sorts the three summary rows by invoice number.
ORDER BY INVOICE.INVOICE_NUM;
