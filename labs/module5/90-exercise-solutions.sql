-- ======================================================================
-- Module 5 · Solutions to the sandbox exercises
-- ======================================================================
--
-- One entry per exercise, in the same order as the numbered lesson files.
-- Each shows the starter the student begins from and the finished query,
-- with the line-by-line commentary the page carries.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Exercise 1  --  section 5-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The starter already joins the two tables correctly - it is only selecting from one of them. Add REP.LAST_NAME and REP.FIRST_NAME to the column list. The row count does not change; the rows just get wider.

-- Starter:
--   SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME
--   FROM CUSTOMER, REP
--   WHERE CUSTOMER.REP_NUM = REP.REP_NUM
--   ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Solution:
-- SELECT: four columns, two from each table, every one qualified as TABLE.COLUMN.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME, REP.FIRST_NAME
-- FROM: both tables in play. On its own this pairs every customer with every rep.
FROM CUSTOMER, REP
-- WHERE: the matching condition, and the line that makes this a join - keep a
-- pairing only when the two rep numbers agree.
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
-- ORDER BY: sorts the result; it never affects which rows match.
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 2  --  section 5-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Add one more line with AND under the matching condition, restricting CUSTOMER.CREDIT_LIMIT. Four rows should become two.

-- Starter:
--   SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
--   FROM CUSTOMER, REP
--   WHERE CUSTOMER.REP_NUM = REP.REP_NUM
--   ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Solution:
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
FROM CUSTOMER, REP
-- The matching condition: which customer row belongs with which rep row.
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
-- An ordinary business restriction on top of it. Both must be true, so the four
-- joined rows become the two whose credit limit clears 7500.
  AND CUSTOMER.CREDIT_LIMIT >= 7500
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 3  --  section 5-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Start from the four detail rows, then collapse them: replace the customer columns with COUNT(*) and SUM(CUSTOMER.BALANCE), and add GROUP BY REP.LAST_NAME. Four rows become three.

-- Starter:
--   SELECT REP.LAST_NAME, CUSTOMER.CUSTOMER_NAME, CUSTOMER.BALANCE
--   FROM REP, CUSTOMER
--   WHERE REP.REP_NUM = CUSTOMER.REP_NUM
--   ORDER BY REP.LAST_NAME, CUSTOMER.CUSTOMER_NAME;

-- Solution:
-- The grouping column, then two aggregates over the joined rows.
SELECT REP.LAST_NAME, COUNT(*) AS NUM_CUSTOMERS, SUM(CUSTOMER.BALANCE) AS TOTAL_BALANCE
FROM REP, CUSTOMER
-- The matching condition is applied BEFORE the grouping, so the aggregates are
-- computed over joined rows rather than over either raw table.
WHERE REP.REP_NUM = CUSTOMER.REP_NUM
-- One output row per rep last name.
GROUP BY REP.LAST_NAME
ORDER BY REP.LAST_NAME;

-- ----------------------------------------------------------------------
-- Exercise 4  --  section 5-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Your task: leave the starter alone and write a second statement below it that lists the ITEM_ID, DESCRIPTION and PRICE of every item ordered on invoice 50710, using the same IN shape. Run the inner query by itself first - SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710'; returns CF21 and DG04. Those two values are the list the outer query checks against, so expect two rows.

-- Starter:
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME
--   FROM CUSTOMER
--   WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
--   ORDER BY CUSTOMER_NUM;

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
-- The inner SELECT runs first and returns a list of customer numbers. IN then
-- tests each customer once against that list, so no duplicate can appear and
-- DISTINCT is unnecessary.
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
ORDER BY CUSTOMER_NUM;

-- The same shape aimed at a different question: which items are on invoice 50710.
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
-- Run the inner query alone first and you get CF21 and DG04 - the list IN tests against.
WHERE ITEM_ID IN
    (SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710')
ORDER BY ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 5  --  section 5-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Run the EXISTS version as given, then copy it underneath and add NOT in front of EXISTS in the copy. Three rows from the first, one from the second - between them the two statements account for all four customers.

-- Starter:
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME
--   FROM CUSTOMER
--   WHERE EXISTS
--       (SELECT *
--        FROM INVOICE
--        WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)
--   ORDER BY CUSTOMER_NUM;

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
-- EXISTS is a yes-or-no test on the customer being examined: did the inner query
-- find at least one row? It returns true or false and no values of its own.
WHERE EXISTS
    -- SELECT * because the column list is irrelevant - only whether a row exists.
    (SELECT *
     FROM INVOICE
     -- Naming CUSTOMER here makes the subquery correlated: it is re-run once per
     -- customer, with that customer's number filled in.
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)
ORDER BY CUSTOMER_NUM;

-- The same query with the test reversed.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
-- NOT EXISTS keeps the customer only when the inner query finds NOTHING. This is
-- the standard pattern for finding rows with no match on the other side.
WHERE NOT EXISTS
    (SELECT *
     FROM INVOICE
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 6  --  section 5-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The starter is the innermost layer, and it returns 50710 and 50711. Wrap it in the INVOICE query and run that - two customer numbers. Then wrap that in the CUSTOMER query. Two rows at the end.

-- Starter:
--   SELECT INVOICE_NUM
--   FROM INVOICE_LINE
--   WHERE ITEM_ID = 'CF21';

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
-- Step 3, the last test to run: keep customers whose number is in the middle list.
WHERE CUSTOMER_NUM IN
    -- Step 2: the customer number on each matching invoice.
    (SELECT CUSTOMER_NUM
     FROM INVOICE
     WHERE INVOICE_NUM IN
         -- Step 1 runs FIRST: the invoices that contain item CF21.
         (SELECT INVOICE_NUM
          FROM INVOICE_LINE
          -- Both closing parentheses land here, one per subquery.
          WHERE ITEM_ID = 'CF21'))
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 7  --  section 5-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Work up one stage at a time and run after each. Six rows through stage 3, four rows once the IN restriction goes on.

-- Starter:
--   SELECT INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED
--   FROM INVOICE_LINE, ITEM
--   WHERE INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
--   ORDER BY INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Solution:
-- Three display columns drawn from three different tables...
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM, ITEM.DESCRIPTION,
-- ...plus a calculated one. The multiplication runs once per row; AS names it.
       INVOICE_LINE.NUM_ORDERED * INVOICE_LINE.QUOTED_PRICE AS LINE_TOTAL
-- Four tables in FROM always need three matching conditions.
FROM CUSTOMER, INVOICE, INVOICE_LINE, ITEM
-- Link 1: customer to invoice.
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
-- Link 2: invoice to line item.
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM
-- Link 3: line item to item.
  AND INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
-- NOT a link - the business restriction. The subquery returns the Maple Grove
-- reps, and IN keeps only the customers those reps serve.
  AND CUSTOMER.REP_NUM IN
      -- Note whose city is tested: the REP's, not the customer's.
      (SELECT REP_NUM FROM REP WHERE CITY = 'Maple Grove')
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- ----------------------------------------------------------------------
-- Exercise 8  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Give REP the alias R in the FROM clause, then use R on both sides of the matching condition.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   SELECT C.CUSTOMER_NUM, C.CUSTOMER_NAME, R.LAST_NAME, R.RATE
--   FROM CUSTOMER C, REP ___
--   WHERE C.REP_NUM = ___.REP_NUM
--   ORDER BY C.CUSTOMER_NUM;

-- Solution:
-- Columns qualified with the SHORT aliases defined below, not the full table names.
SELECT C.CUSTOMER_NUM, C.CUSTOMER_NAME, R.LAST_NAME, R.RATE
-- The aliases are created here: table name, a space, then the short name. Once C
-- and R exist, CUSTOMER and REP are no longer usable names in this statement.
FROM CUSTOMER C, REP R
-- The matching condition, now short enough to read at a glance.
WHERE C.REP_NUM = R.REP_NUM
ORDER BY C.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 9  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Run it as written and count the rows before you read on. Six is more than you wanted.

-- Starter:
--   SELECT A.CUSTOMER_NUM, B.CUSTOMER_NUM, A.REP_NUM
--   FROM CUSTOMER A, CUSTOMER B
--   WHERE A.REP_NUM = B.REP_NUM
--   ORDER BY A.CUSTOMER_NUM, B.CUSTOMER_NUM;

-- Solution:
-- Both copies must be qualified: a bare CUSTOMER_NUM would be ambiguous.
SELECT A.CUSTOMER_NUM, B.CUSTOMER_NUM, A.REP_NUM
-- The same table opened TWICE under two names. That is all a self-join is - an
-- ordinary join whose two sides happen to be one table.
FROM CUSTOMER A, CUSTOMER B
-- Match the copies on the shared rep. With nothing else, this also pairs every
-- row with itself and reports each real pair twice - six rows, not one.
WHERE A.REP_NUM = B.REP_NUM
ORDER BY A.CUSTOMER_NUM, B.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 10  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Put a less-than sign between the two primary key columns, then try <> instead and compare the row counts.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   SELECT A.CUSTOMER_NUM, A.CUSTOMER_NAME, B.CUSTOMER_NUM, B.CUSTOMER_NAME
--   FROM CUSTOMER A, CUSTOMER B
--   WHERE A.REP_NUM = B.REP_NUM
--   AND A.CUSTOMER_NUM ___ B.CUSTOMER_NUM;

-- Solution:
SELECT A.CUSTOMER_NUM, A.CUSTOMER_NAME, B.CUSTOMER_NUM, B.CUSTOMER_NAME
FROM CUSTOMER A, CUSTOMER B
-- The relationship you care about: the two customers share a rep.
WHERE A.REP_NUM = B.REP_NUM
-- The fix, on the PRIMARY KEY. < throws out the self-paired rows (nothing is
-- less than itself) AND picks one direction for each real pair, so each pair is
-- reported exactly once. Six rows collapse to one.
AND A.CUSTOMER_NUM < B.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 11  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: One row comes back, AV07 with FT88, because Habitat is the only category holding two items.

-- Starter:
--   SELECT A.ITEM_ID, B.ITEM_ID, A.CATEGORY
--   FROM ITEM A, ITEM B
--   WHERE A.CATEGORY = B.CATEGORY
--   AND A.ITEM_ID < B.ITEM_ID;

-- Solution:
-- The same pattern pointed at a different shared attribute.
SELECT A.ITEM_ID, B.ITEM_ID, A.CATEGORY
FROM ITEM A, ITEM B
-- Match on the column that describes the relationship - here, the category.
WHERE A.CATEGORY = B.CATEGORY
-- Then restrict on the primary key so each pair appears once.
AND A.ITEM_ID < B.ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 12  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Three aliases, three conditions: match the copies, attach the rep, restrict the pair.

-- Starter:
--   SELECT R.LAST_NAME, A.CUSTOMER_NAME, B.CUSTOMER_NAME
--   FROM CUSTOMER A, CUSTOMER B, REP R
--   WHERE A.REP_NUM = B.REP_NUM
--   AND A.REP_NUM = R.REP_NUM
--   AND A.CUSTOMER_NUM < B.CUSTOMER_NUM;

-- Solution:
-- A self-join can sit alongside other tables: three names, two of them the same table.
SELECT R.LAST_NAME, A.CUSTOMER_NAME, B.CUSTOMER_NAME
FROM CUSTOMER A, CUSTOMER B, REP R
-- The two customer copies share a rep.
WHERE A.REP_NUM = B.REP_NUM
-- REP is linked to either copy - both carry the same rep number, so it does not matter which.
AND A.REP_NUM = R.REP_NUM
-- And the primary key condition still keeps each pair to one row.
AND A.CUSTOMER_NUM < B.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 13  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The last link joins INVOICE_LINE to ITEM, so the missing alias is IT.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION, IL.NUM_ORDERED
--   FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
--   WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
--   AND I.INVOICE_NUM = IL.INVOICE_NUM
--   AND IL.ITEM_ID = ___.ITEM_ID
--   ORDER BY I.INVOICE_NUM, IT.ITEM_ID;

-- Solution:
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION, IL.NUM_ORDERED
-- Four tables, all aliased, so the conditions below stay short.
FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
-- Link 1 of 3: customer to invoice.
WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
-- Link 2: invoice to line item.
AND I.INVOICE_NUM = IL.INVOICE_NUM
-- Link 3: line item to item. Four tables, three links - always one fewer.
AND IL.ITEM_ID = IT.ITEM_ID
ORDER BY I.INVOICE_NUM, IT.ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 14  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Put the category in single quotes: 'Habitat'. Two rows come back, both on invoice 50712.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION
--   FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
--   WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
--   AND I.INVOICE_NUM = IL.INVOICE_NUM
--   AND IL.ITEM_ID = IT.ITEM_ID
--   AND IT.CATEGORY = ___
--   ORDER BY IT.ITEM_ID;

-- Solution:
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION
FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
-- The three links that hold the chain together.
WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND I.INVOICE_NUM = IL.INVOICE_NUM
AND IL.ITEM_ID = IT.ITEM_ID
-- A fourth condition that is NOT a link: an ordinary filter on the joined rows.
AND IT.CATEGORY = 'Habitat'
ORDER BY IT.ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 15  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Five tables, four conditions. Kaiser's two lines extend to 127.50 and 23.98.

-- Starter:
--   SELECT R.LAST_NAME, C.CUSTOMER_NAME, IT.DESCRIPTION,
--          IL.NUM_ORDERED * IL.QUOTED_PRICE AS EXTENDED
--   FROM REP R, CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
--   WHERE R.REP_NUM = C.REP_NUM
--   AND C.CUSTOMER_NUM = I.CUSTOMER_NUM
--   AND I.INVOICE_NUM = IL.INVOICE_NUM
--   AND IL.ITEM_ID = IT.ITEM_ID
--   ORDER BY R.LAST_NAME, IT.DESCRIPTION;

-- Solution:
SELECT R.LAST_NAME, C.CUSTOMER_NAME, IT.DESCRIPTION,
       -- The calculated line value, named with AS.
       IL.NUM_ORDERED * IL.QUOTED_PRICE AS EXTENDED
-- FIVE tables this time, so four links are needed.
FROM REP R, CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
-- Link 1: rep to customer.
WHERE R.REP_NUM = C.REP_NUM
-- Link 2: customer to invoice.
AND C.CUSTOMER_NUM = I.CUSTOMER_NUM
-- Link 3: invoice to line item.
AND I.INVOICE_NUM = IL.INVOICE_NUM
-- Link 4: line item to item. Count them against the tables: five and four.
AND IL.ITEM_ID = IT.ITEM_ID
ORDER BY R.LAST_NAME, IT.DESCRIPTION;

-- ----------------------------------------------------------------------
-- Exercise 16  --  section 5-2e-5-2h  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Group by the invoice number, qualified with its alias. Totals are 151.48, 100.25 and 120.49.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS INVOICE_TOTAL
--   FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL
--   WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
--   AND I.INVOICE_NUM = IL.INVOICE_NUM
--   GROUP BY ___, C.CUSTOMER_NAME
--   ORDER BY I.INVOICE_NUM;

-- Solution:
-- Two grouping columns and one aggregate over the joined rows.
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS INVOICE_TOTAL
-- Only three tables: no item description is displayed, so ITEM is not needed.
FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL
-- Three tables, two links.
WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND I.INVOICE_NUM = IL.INVOICE_NUM
-- One output row per invoice. Every non-aggregated column above is listed here,
-- which is why CUSTOMER_NAME appears as well as INVOICE_NUM.
GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME
ORDER BY I.INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Exercise 17  --  section 5-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: CF21 is the only item that appears on both invoices, so it is the only row UNION collapses. Four rows becomes three: CF21, DG04, GR15.

-- Starter:
--   -- Invoice 50710 lists CF21 and DG04. Invoice 50711 lists CF21 and GR15.
--   -- Step 1: run this and count the rows.
--   SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710'
--   UNION ALL
--   SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50711';
--
--   -- Step 2: change UNION ALL to UNION, run it again, and explain the difference.

-- Solution:
-- First set: the items on invoice 50710.
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710'
-- UNION stacks the two results and removes duplicates. Both sides return one
-- column of the same kind, which is what union compatible means.
UNION
-- Second set: the items on invoice 50711. CF21 is on both and appears once.
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50711';

-- ----------------------------------------------------------------------
-- Exercise 18  --  section 5-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: INTERSECT returns Access Pet Center (1120) on its own. Swap in EXCEPT and you get Companion Care Clinic (1310) on its own, because 1310 belongs to rep 20 and has no invoice.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- List 1 (already written): customers served by rep 20.
--   -- List 2: customers that have at least one invoice.
--   -- Finish this as an INTERSECT to find customers on BOTH lists,
--   -- then change INTERSECT to EXCEPT and run it again.
--
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME
--   FROM CUSTOMER
--   WHERE REP_NUM = '20'

-- Solution:
-- The first of two complete SELECT statements. Its columns fix the shape.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
-- First set: rep 20's customers.
WHERE REP_NUM = '20'
-- INTERSECT keeps only rows produced by BOTH sides. Order does not matter here.
INTERSECT
-- The second statement: same number of columns, same order, same types.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
-- Second set: the customers that have an invoice. Only the overlap survives.
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE);

-- ----------------------------------------------------------------------
-- Exercise 19  --  section 5-3  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: UNION gives S001, S003 and S004. INTERSECT gives S004 alone, the one student who is from Ohio and leases at P200. EXCEPT gives S001 alone, from Ohio but leasing at P100.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- StayWell wants to compare two lists of students:
--   --   A: students whose HOME_STATE is 'OH'
--   --   B: students who lease a room at property P200
--   -- Write all three: A UNION B, A INTERSECT B, and A EXCEPT B.
--   -- List A is started for you, with no semicolon yet, so you can add
--   -- the keyword and List B straight onto the end of it.
--
--   SELECT STUDENT_ID, LAST_NAME
--   FROM STUDENT
--   WHERE HOME_STATE = 'OH'

-- Solution:
-- First set: the Ohio students.
SELECT STUDENT_ID, LAST_NAME
FROM STUDENT
WHERE HOME_STATE = 'OH'
-- UNION combines and drops duplicates, so a student who qualifies on both counts
-- is still listed once.
UNION
SELECT STUDENT_ID, LAST_NAME
FROM STUDENT
-- Second set: the students leasing at property P200.
WHERE STUDENT_ID IN (SELECT STUDENT_ID FROM LEASE WHERE PROPERTY_ID = 'P200')
-- A set operation is ONE statement, so it gets ONE ORDER BY, at the very end.
ORDER BY STUDENT_ID;

-- ----------------------------------------------------------------------
-- Exercise 20  --  section 5-4  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: There is one Accessory item, the Nylon Dog Leash at 11.99, so MAX is 11.99 and the other four items all clear it: AV07, CF21, FT88 and GR15.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- The MySQL/Oracle version would be:
--   --   WHERE PRICE > ALL (SELECT PRICE FROM ITEM WHERE CATEGORY = 'Accessory')
--   -- Rewrite it with MAX so it runs here: which items cost more than
--   -- every Accessory item?
--
--   SELECT ITEM_ID, DESCRIPTION, PRICE
--   FROM ITEM
--   WHERE PRICE >

-- Solution:
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
-- The SQLite-friendly rewrite of > ALL. Beating every accessory price is the same
-- as beating the largest one, and MAX collapses the subquery to a single number
-- so an ordinary comparison works.
WHERE PRICE > (SELECT MAX(PRICE) FROM ITEM WHERE CATEGORY = 'Accessory')
ORDER BY ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 21  --  section 5-4  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: = ANY is IN and returns the three invoiced customers 1120, 1225 and 1420. <> ALL is NOT IN and returns Companion Care Clinic (1310) on its own.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- Translate these two on sight, then run them.
--   -- 1. WHERE CUSTOMER_NUM = ANY (SELECT CUSTOMER_NUM FROM INVOICE)
--   -- 2. WHERE CUSTOMER_NUM <> ALL (SELECT CUSTOMER_NUM FROM INVOICE)
--   -- Write version 1 first using the keyword that runs in SQLite.
--
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME
--   FROM CUSTOMER

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
-- = ANY means the same thing as IN: match any value in the list. IN is the
-- spelling that runs everywhere, SQLite included.
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 22  --  section 5-4  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: Part (a) clears the bar at 595.00 and returns two rooms, P200 101 and P200 201. Part (b) drops the bar to 450.00 and returns four rooms: P100 101, P200 101, P200 201 and P200 202.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- StayWell is repricing. Property P100 has rooms at 595.00 and 450.00.
--   -- a) Which rooms rent for more than EVERY room at P100?  (ALL -> MAX)
--   -- b) Which rooms rent for more than ANY room at P100?    (ANY -> MIN)
--   -- Write part (a) here, then edit it into part (b).
--
--   SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
--   FROM ROOM

-- Solution:
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
-- Beat the dearest room at P100. MAX turns the subquery into one number, which
-- is what makes > legal - a bare subquery returning several rows would not be.
WHERE MONTHLY_RENT > (SELECT MAX(MONTHLY_RENT) FROM ROOM WHERE PROPERTY_ID = 'P100')
ORDER BY PROPERTY_ID, ROOM_NUM;

-- ----------------------------------------------------------------------
-- Exercise 23  --  section 5-5  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The inner join returns three rows and hides Companion Care Clinic. The LEFT JOIN returns four, with an empty INVOICE_NUM on row 1310. Adding WHERE INVOICE.INVOICE_NUM IS NULL narrows it to that one row. WHERE always goes before ORDER BY.

-- Starter:
--   -- Run these three one at a time and compare the row counts.
--   -- 1. Inner join: which customers drop out, and why?
--   SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
--   FROM CUSTOMER INNER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
--   ORDER BY CUSTOMER.CUSTOMER_NUM;
--
--   -- 2. Now change INNER JOIN to LEFT JOIN and run it again.
--   -- 3. Then put this line just before the ORDER BY and run it a third time:
--   --      WHERE INVOICE.INVOICE_NUM IS NULL

-- Solution:
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
-- LEFT JOIN keeps every row of the table on the LEFT, matched or not. Where a
-- customer has no invoice, SQL fills the INVOICE columns with NULL - so all four
-- customers come back, not the three an INNER JOIN would return.
FROM CUSTOMER LEFT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 24  --  section 5-5  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Five rows. One has an empty customer and invoice 50713, the orphan invoice. One has Companion Care Clinic and an empty invoice. Both unmatched sides survive, which is what makes the join full. Without the DELETE on the first line, a second run would fail on the primary key.

-- Starter:
--   -- FULL OUTER JOIN keeps unmatched rows from BOTH sides. The shipped data
--   -- has no orphan invoice, so this INSERT makes one first: invoice 50713
--   -- points at customer 9999, which does not exist.
--   -- The DELETE on the first line clears any 50713 left over from a previous
--   -- run, so you can run the whole box as many times as you like.
--   -- Press Reset when you are done to restore the shipped data.
--
--   DELETE FROM INVOICE WHERE INVOICE_NUM = '50713';
--
--   INSERT INTO INVOICE (INVOICE_NUM, CUSTOMER_NUM, INVOICE_DATE)
--   VALUES ('50713', '9999', '2026-06-16');
--
--   SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
--   FROM CUSTOMER FULL OUTER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
--   ORDER BY CUSTOMER.CUSTOMER_NUM, INVOICE.INVOICE_NUM;

-- Solution:
-- Housekeeping, so this box survives a second Run.
DELETE FROM INVOICE WHERE INVOICE_NUM = '50713';

-- Add an ORPHAN invoice on purpose: customer 9999 does not exist. Without one,
-- a full outer join would look identical to a left join on this data.
INSERT INTO INVOICE (INVOICE_NUM, CUSTOMER_NUM, INVOICE_DATE)
VALUES ('50713', '9999', '2026-06-16');

SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
-- FULL OUTER JOIN protects BOTH sides: the customer with no invoice AND the
-- invoice with no customer both survive, each padded with nulls.
FROM CUSTOMER FULL OUTER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM, INVOICE.INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Exercise 25  --  section 5-5  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The product is twelve rows, 4 times 3. Adding the WHERE condition cuts it to the four rows that are true, one per customer. FROM CUSTOMER CROSS JOIN REP also returns twelve and states the intent openly.

-- Starter:
--   -- No join condition anywhere. Predict the row count before you run it:
--   -- CUSTOMER has 4 rows, REP has 3.
--   SELECT COUNT(*) AS ROW_COUNT FROM CUSTOMER, REP;
--
--   -- Then run the rows themselves, and finally add the missing condition
--   --      WHERE CUSTOMER.REP_NUM = REP.REP_NUM
--   -- to collapse the product into the inner join you actually wanted.

-- Solution:
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
-- The older comma-and-WHERE form. Listing two tables with no condition would
-- produce the twelve-row product...
FROM CUSTOMER, REP
-- ...and this single line is the whole difference between that and a real join.
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 26  --  section 5-5  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: Part (a) gives five rows and P200 room 101 has an empty LEASE_ID, so it is the vacant one. Part (b) also gives five rows, but for the opposite reason: L001 appears twice because it has two payments, and L004 appears once with an empty payment.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- Two gap-finding questions for StayWell. Use LEFT JOIN for both.
--   -- a) Every room, with its lease id, including rooms nobody leases.
--   -- b) Every lease, with its payments, including leases with no payment.
--   -- Part (a) is started for you: ROOM's key is two columns, so the ON
--   -- clause needs both, joined with AND.
--
--   SELECT ROOM.PROPERTY_ID, ROOM.ROOM_NUM, LEASE.LEASE_ID
--   FROM ROOM LEFT JOIN LEASE ON

-- Solution:
SELECT ROOM.PROPERTY_ID, ROOM.ROOM_NUM, LEASE.LEASE_ID
-- ROOM is on the left, so every room is kept whether or not it has been leased.
FROM ROOM LEFT JOIN LEASE
  -- The ON condition needs BOTH key columns, because a room is identified by the
  -- property and the room number together. One of them alone would over-match.
  ON ROOM.PROPERTY_ID = LEASE.PROPERTY_ID AND ROOM.ROOM_NUM = LEASE.ROOM_NUM
ORDER BY ROOM.PROPERTY_ID, ROOM.ROOM_NUM;

-- ----------------------------------------------------------------------
-- Exercise 27  --  section Summary  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Companion Care Clinic has no invoice, so an inner join drops it and a LEFT JOIN keeps it. Count I.INVOICE_NUM rather than *: the padded row is still a row, so COUNT(*) would report 1 for the clinic instead of 0.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- List every KimTay customer with the number of invoices they have,
--   -- including the customer who has never been invoiced.
--   -- Four rows come back, and one of the counts is 0.

-- Solution:
-- COUNT(I.INVOICE_NUM) counts VALUES, so an unmatched customer scores 0.
-- COUNT(*) would count the null-padded row and wrongly report 1.
SELECT C.CUSTOMER_NAME, COUNT(I.INVOICE_NUM) AS INVOICE_COUNT
FROM CUSTOMER C
-- LEFT JOIN keeps the customers with no invoices in the answer at all.
LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
-- Group by the key as well as the name, so two customers sharing a name stay apart.
GROUP BY C.CUSTOMER_NUM, C.CUSTOMER_NAME
ORDER BY C.CUSTOMER_NAME;

-- ----------------------------------------------------------------------
-- Exercise 28  --  section Key Terms  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The self-join returns one row, Access Pet Center paired with Companion Care Clinic in Maple Grove. The union returns three cities. The correlated EXISTS returns the three customers that have an invoice, leaving out Companion Care Clinic.

-- Starter:
--   -- Alias plus self-join: two KimTay customers that share a city.
--   SELECT F.CUSTOMER_NAME AS FIRST_ONE, S.CUSTOMER_NAME AS SECOND_ONE, F.CITY
--   FROM CUSTOMER F, CUSTOMER S
--   WHERE F.CITY = S.CITY
--     AND F.CUSTOMER_NUM < S.CUSTOMER_NUM;

-- Solution:
-- Alias plus self-join: two KimTay customers that share a city.
-- Both copies are aliased and both output columns are renamed for readability.
SELECT F.CUSTOMER_NAME AS FIRST_ONE, S.CUSTOMER_NAME AS SECOND_ONE, F.CITY
-- One table, opened twice under two names.
FROM CUSTOMER F, CUSTOMER S
-- The shared attribute that defines the pair.
WHERE F.CITY = S.CITY
  -- The primary key condition that removes self-pairs and reversed duplicates.
  AND F.CUSTOMER_NUM < S.CUSTOMER_NUM;

-- Union compatible: one column of city text on each side.
SELECT CITY FROM REP
-- UNION removes duplicates, so a city both tables use appears once.
UNION
SELECT CITY FROM CUSTOMER
-- One ORDER BY for the whole statement, at the end.
ORDER BY CITY;

-- Correlated subquery: the inner query names C.CUSTOMER_NUM from the outer row.
SELECT C.CUSTOMER_NAME
FROM CUSTOMER C
-- SELECT 1 rather than SELECT * - EXISTS never uses the value, so anything does.
WHERE EXISTS (SELECT 1 FROM INVOICE I WHERE I.CUSTOMER_NUM = C.CUSTOMER_NUM);

-- ----------------------------------------------------------------------
-- Exercise 29  --  section Review  --  seed: both_full
-- ----------------------------------------------------------------------

-- Hint given: KimTay: 3 reps, 4 customers, 3 invoices, 6 invoice lines, 5 items. StayWell: 2 managers, 2 properties, 5 rooms, 4 students, 4 leases, 4 payments. Those eleven numbers let you predict most row counts in your head.

-- Starter:
--   -- Scratch pad. Predict the answer, then check it here.
--   -- Start with the row counts you should be able to state from memory:
--   SELECT 'REP' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM REP
--   UNION ALL SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER
--   UNION ALL SELECT 'INVOICE', COUNT(*) FROM INVOICE
--   UNION ALL SELECT 'INVOICE_LINE', COUNT(*) FROM INVOICE_LINE
--   UNION ALL SELECT 'ITEM', COUNT(*) FROM ITEM;

-- Solution:
-- A row-count audit built entirely out of UNION ALL. Each SELECT invents a label
-- column and counts one table; UNION ALL stacks them without checking duplicates,
-- which is what you want when every row is deliberately different.
SELECT 'REP' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM REP
-- Only the FIRST SELECT needs the AS aliases - the headings come from it.
UNION ALL SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER
UNION ALL SELECT 'INVOICE', COUNT(*) FROM INVOICE
UNION ALL SELECT 'INVOICE_LINE', COUNT(*) FROM INVOICE_LINE
UNION ALL SELECT 'ITEM', COUNT(*) FROM ITEM;

-- The same audit for the StayWell database.
SELECT 'MANAGER' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM MANAGER
UNION ALL SELECT 'PROPERTY', COUNT(*) FROM PROPERTY
UNION ALL SELECT 'ROOM', COUNT(*) FROM ROOM
UNION ALL SELECT 'STUDENT', COUNT(*) FROM STUDENT
UNION ALL SELECT 'LEASE', COUNT(*) FROM LEASE
UNION ALL SELECT 'PAYMENT', COUNT(*) FROM PAYMENT;

-- ----------------------------------------------------------------------
-- Exercise 30  --  section Case Exercises  --  seed: both_full
-- ----------------------------------------------------------------------

-- Hint given: Expected counts: 3 rows, 2 rows, 4 rows, 1 row, 1 row. Rep 20 has one invoiced customer and therefore one invoice, so exercise 2 returns two descriptions with or without DISTINCT; more than two means the rep 20 filter is missing or a linking condition is. In exercise 3 every student already has a lease, so the join that can drop Jason Park is the one to PAYMENT: if you get three rows, make that join LEFT.

-- Starter:
--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)
--   -- Both databases are loaded. Write each answer under its comment,
--   -- run it, then compare the row count with the one you predicted.
--
--   -- 1. Every invoice with its date, customer name and rep last name.
--
--
--   -- 2. The distinct items on invoices belonging to rep 20's customers.
--
--
--   -- 3. Every student and the total paid so far, including one who has paid nothing.
--
--
--   -- 4. Rooms that have never appeared on a lease.
--
--
--   -- 5. Cities where KimTay has a customer but no rep.

-- Solution:
-- 1. Three rows, one per invoice.
SELECT I.INVOICE_NUM, I.INVOICE_DATE, C.CUSTOMER_NAME, R.LAST_NAME
-- Three tables, so two links.
FROM INVOICE I, CUSTOMER C, REP R
-- Link 1: invoice to the customer it belongs to.
WHERE I.CUSTOMER_NUM = C.CUSTOMER_NUM
  -- Link 2: that customer to the rep who serves it.
  AND C.REP_NUM = R.REP_NUM
ORDER BY I.INVOICE_NUM;

-- 2. Two rows: the dry food and the leash. Rep 20's only invoiced customer
-- is Access Pet Center, and it has a single invoice, so DISTINCT has nothing
-- to collapse today; it is here to keep the query right tomorrow.
SELECT DISTINCT T.DESCRIPTION
-- Four tables to travel from a rep number all the way to an item description.
FROM ITEM T, INVOICE_LINE L, INVOICE I, CUSTOMER C
-- The three links, walked backwards: item to line, line to invoice, invoice to customer.
WHERE T.ITEM_ID = L.ITEM_ID
  AND L.INVOICE_NUM = I.INVOICE_NUM
  AND I.CUSTOMER_NUM = C.CUSTOMER_NUM
  -- The restriction, on a column that never appears in the output.
  AND C.REP_NUM = '20'
ORDER BY T.DESCRIPTION;

-- 3. Four rows. Jason Park's total is null, not zero: SUM over no rows
-- has nothing to add up. COALESCE(SUM(P.AMOUNT), 0) would print 0 instead.
SELECT S.LAST_NAME, S.FIRST_NAME, SUM(P.AMOUNT) AS PAID
FROM STUDENT S
-- Two LEFT JOINs chained: a student with no lease survives the first, and then
-- survives the second as well, because a null carries straight through.
LEFT JOIN LEASE L ON S.STUDENT_ID = L.STUDENT_ID
LEFT JOIN PAYMENT P ON L.LEASE_ID = P.LEASE_ID
-- Group by the key as well as the names, so two students sharing a name stay apart.
GROUP BY S.STUDENT_ID, S.LAST_NAME, S.FIRST_NAME
ORDER BY S.LAST_NAME;

-- 4. One row: P200 room 101, Single.
SELECT R.PROPERTY_ID, R.ROOM_NUM, R.ROOM_TYPE
FROM ROOM R
-- NOT EXISTS: keep the room only when the inner search comes back empty. The
-- inner query is correlated - it names R from the outer row.
WHERE NOT EXISTS (SELECT 1 FROM LEASE L
                  -- Both key columns are needed to identify one room.
                  WHERE L.PROPERTY_ID = R.PROPERTY_ID
                    AND L.ROOM_NUM = R.ROOM_NUM);

-- 4 again, written as a difference. Same room, but only the two columns
-- ROOM and LEASE have in common: adding ROOM_TYPE to the left side would
-- break union compatibility and the statement would not run at all.
SELECT PROPERTY_ID, ROOM_NUM FROM ROOM
-- EXCEPT keeps rows from the first result that the second did not also produce.
EXCEPT
SELECT PROPERTY_ID, ROOM_NUM FROM LEASE;

-- 5. One row: Northfield.
SELECT CITY FROM CUSTOMER
-- Order matters for EXCEPT: swapping the halves asks a different question.
EXCEPT
SELECT CITY FROM REP;
