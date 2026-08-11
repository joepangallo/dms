-- ======================================================================
-- Module 4 · Nesting Queries
-- ======================================================================
--
-- Sections: 4-4
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 4-4  Nesting Queries
-- ----------------------------------------------------------------------


-- Example 4-4.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- GOAL: a deliberate error, and the most common one in this lesson.
-- SELECT: two ordinary columns.
SELECT ITEM_ID, DESCRIPTION

-- FROM: the table being read.
FROM ITEM

-- WHERE: BROKEN. An aggregate cannot appear in a WHERE clause. WHERE is tested
--   one row at a time, while AVG(PRICE) needs the whole table before it can
--   produce a number, so the engine is being asked to use an answer that does
--   not exist yet. SQLite says "misuse of aggregate function AVG()". The fix is
--   to work the average out first, in a subquery.
WHERE PRICE > AVG(PRICE);

-- Example 4-4.2
-- SELECT: step 1 of the fix - work out the average on its own, and look at it.
--   Run any subquery by itself before nesting it, so you know what it returns.
SELECT AVG(PRICE)

-- FROM: the table being averaged. One row, one column, one number.
FROM ITEM;

-- Example 4-4.3
-- SELECT: three columns, PRICE included so the comparison can be checked by eye.
SELECT ITEM_ID, DESCRIPTION, PRICE

-- FROM: the table being read.
FROM ITEM

-- WHERE: the subquery in parentheses runs FIRST and collapses to a single number,
--   the average price. The outer WHERE then compares each row against that one
--   value. Because the subquery is an aggregate over the whole table, it is
--   guaranteed to return exactly one row, which is what makes = or > safe here.
WHERE PRICE > (SELECT AVG(PRICE) FROM ITEM)

-- ORDER BY: sorts the survivors, dearest first.
ORDER BY PRICE DESC;

-- Example 4-4.4
-- SELECT: step 1 again - find the value you are going to compare against.
SELECT CATEGORY

-- FROM: the table being read.
FROM ITEM

-- WHERE: filtering on the PRIMARY KEY, so at most one row can come back. That
--   guarantee is what will make it safe to use this query with = in a moment.
WHERE ITEM_ID = 'FT88';

-- Example 4-4.5
-- SELECT: three columns.
SELECT ITEM_ID, DESCRIPTION, PRICE

-- FROM: the table being read.
FROM ITEM

-- WHERE: the subquery finds FT88's category, and the outer query keeps every item
--   in that same category - FT88 itself included. = is safe here only because the
--   subquery filters on a primary key and so cannot return two rows.
WHERE CATEGORY = (SELECT CATEGORY FROM ITEM WHERE ITEM_ID = 'FT88')

-- ORDER BY: sorts the result by item id.
ORDER BY ITEM_ID;

-- >>> EXERCISE 11  (section 4-4, seed: kimtay_full)
-- Hint: Run it to see all four customers, then add a WHERE that compares BALANCE to a subquery over the whole table -- the four balances total 9533.25, so the average is 2383.3125 and two customers should survive.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
ORDER BY BALANCE DESC;

-- Example 4-4.7
-- SELECT: one column, which is a requirement - a subquery used with IN or = must
--   return exactly one column.
SELECT ITEM_ID

-- FROM: the line-item table, where quantities are recorded.
FROM INVOICE_LINE

-- WHERE: keeps the lines of two or more units. Run alone, this returns several
--   rows, and CF21 appears twice because it was ordered in bulk on two invoices.
WHERE NUM_ORDERED >= 2;

-- Example 4-4.8
-- SELECT: three columns from the item table.
SELECT ITEM_ID, DESCRIPTION, ON_HAND

-- FROM: the table being read.
FROM ITEM

-- WHERE: IN handles a subquery returning MANY rows - read it as "keep this item
--   if its id is one of the ids the inner query found". Duplicates in that inner
--   list are harmless, because each item is tested once and either matches or
--   does not.
WHERE ITEM_ID IN (SELECT ITEM_ID FROM INVOICE_LINE WHERE NUM_ORDERED >= 2)

-- ORDER BY: sorts the result by item id.
ORDER BY ITEM_ID;

-- Example 4-4.9
-- GOAL: the classic error - the previous query written with = instead of IN.
-- SELECT: two columns.
SELECT ITEM_ID, DESCRIPTION

-- FROM: the table being read.
FROM ITEM

-- WHERE: BROKEN. = compares one value against ONE other value, and the subquery
--   here returns several rows. MySQL refuses the statement outright (error 1242,
--   "Subquery returns more than 1 row"). SQLite, the engine on this page, does
--   not complain at all - it keeps whichever value came back first and quietly
--   answers the wrong question, which is far more dangerous. Use = only when the
--   subquery is an aggregate or filters on a key; otherwise use IN.
WHERE ITEM_ID = (SELECT ITEM_ID FROM INVOICE_LINE WHERE NUM_ORDERED >= 2);

-- >>> EXERCISE 12  (section 4-4, seed: staywell_full)
-- Hint: The inner query returns two property IDs, P100 and P200, because each property has one Double room. Nest it inside a query on PROPERTY to name both buildings, then swap IN for = and watch this engine hand back Millbrook Commons on its own.
SELECT PROPERTY_ID
FROM ROOM
WHERE ROOM_TYPE = 'Double';
