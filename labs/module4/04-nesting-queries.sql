-- ======================================================================
-- Module 4 · Nesting Queries
-- ======================================================================
--
-- Sections: 4-4
-- Load first: 00-setup-both.sql   (has every table this file touches)
--             individual seeds used here: kimtay_full, staywell_full
--
-- Examples are the statements shown in the lesson. Exercises are the
-- starter queries from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Section 4-4 -- Nesting Queries
-- ----------------------------------------------------------------------

-- Example 4-4.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
--    The lesson uses the error message to make its point. Run it and
--    read the error; do not "fix" it.
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE PRICE > AVG(PRICE);

-- Example 4-4.2
SELECT AVG(PRICE)
FROM ITEM;

-- Example 4-4.3
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE > (SELECT AVG(PRICE) FROM ITEM)
ORDER BY PRICE DESC;

-- Example 4-4.4
SELECT CATEGORY
FROM ITEM
WHERE ITEM_ID = 'FT88';

-- Example 4-4.5
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE CATEGORY = (SELECT CATEGORY FROM ITEM WHERE ITEM_ID = 'FT88')
ORDER BY ITEM_ID;

-- >>> EXERCISE 11  (section 4-4, seed: kimtay_full)
-- Hint: Run it to see all four customers, then add a WHERE that compares BALANCE to a subquery over the whole table -- the four balances total 9533.25, so the average is 2383.3125 and two customers should survive.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
ORDER BY BALANCE DESC;

-- Example 4-4.6
SELECT ITEM_ID
FROM INVOICE_LINE
WHERE NUM_ORDERED >= 2;

-- Example 4-4.7
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ITEM_ID IN (SELECT ITEM_ID FROM INVOICE_LINE WHERE NUM_ORDERED >= 2)
ORDER BY ITEM_ID;

-- Example 4-4.8
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE ITEM_ID = (SELECT ITEM_ID FROM INVOICE_LINE WHERE NUM_ORDERED >= 2);

-- >>> EXERCISE 12  (section 4-4, seed: staywell_full)
-- Hint: The inner query returns two property IDs, P100 and P200, because each property has one Double room. Nest it inside a query on PROPERTY to name both buildings, then swap IN for = and watch this engine hand back Millbrook Commons on its own.
SELECT PROPERTY_ID
FROM ROOM
WHERE ROOM_TYPE = 'Double';
