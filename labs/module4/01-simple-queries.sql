-- ======================================================================
-- Module 4 · Constructing Simple Queries
-- ======================================================================
--
-- Sections: 4-1
-- Load first: 00-setup-both.sql   (has every table this file touches)
--             individual seeds used here: kimtay_full, staywell_full
--
-- Examples are the statements shown in the lesson. Exercises are the
-- starter queries from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Section 4-1 -- Constructing Simple Queries
-- ----------------------------------------------------------------------

-- Example 4-1.1
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM;

-- Example 4-1.2
SELECT *
FROM ITEM;

-- >>> EXERCISE 1  (section 4-1, seed: kimtay_full)
-- Hint: Five rows either way; only the number of columns should change, from three to six.
-- This returns three columns for all five items.
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM;

-- Your turn: change it so that every column comes back, then run it again.

-- Example 4-1.3
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ON_HAND < 25;

-- Example 4-1.4
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CITY = 'Maple Grove';

-- Example 4-1.5
SELECT ITEM_ID, CATEGORY
FROM ITEM
WHERE CATEGORY <> 'Habitat';

-- Example 4-1.6
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CITY = 'Maple Grove'
  AND BALANCE > 1000;

-- Example 4-1.7
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE CATEGORY = 'Food'
   OR PRICE > 60;

-- Example 4-1.8
SELECT ITEM_ID, CATEGORY
FROM ITEM
WHERE NOT (CATEGORY = 'Habitat');

-- >>> EXERCISE 2  (section 4-1, seed: kimtay_full)
-- Hint: Two rows before the parentheses, one row after. If both runs match, the parentheses landed in the wrong place.
-- Run this as written and count the rows.
SELECT ITEM_ID, CATEGORY, PRICE
FROM ITEM
WHERE CATEGORY = 'Habitat' OR CATEGORY = 'Food' AND PRICE < 30;

-- Now add parentheses so that the price test applies to both categories.

-- Example 4-1.9
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE BETWEEN 15.25 AND 27.75;

-- Example 4-1.10
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE >= 15.25 AND PRICE <= 27.75;

-- >>> EXERCISE 3  (section 4-1, seed: staywell_full)
-- Hint: Four of the five rooms qualify; only the 725.00 studio in Sycamore Court falls outside the window. The rents print as 595 and 450 here, without the trailing zeros.
-- StayWell's leasing office wants every room renting from 450 through 610 a month.
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT BETWEEN 450 AND 610;

-- Your turn: rewrite the condition using >= and <= and confirm you get the same rooms.

-- Example 4-1.11
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
FROM ITEM;

-- Example 4-1.12
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT
FROM CUSTOMER;

-- Example 4-1.13
SELECT CUSTOMER_NUM, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT
FROM CUSTOMER
WHERE CREDIT_LIMIT - BALANCE > 3900;

-- >>> EXERCISE 4  (section 4-1, seed: kimtay_full)
-- Hint: Two customers qualify. Repeat the whole expression in the WHERE clause instead of using the alias, so the query also runs on MySQL.
-- Stock value per item, calculated on the fly.
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
FROM ITEM;

-- Your turn: write a query on CUSTOMER that shows CUSTOMER_NUM and
-- the credit still available (CREDIT_LIMIT minus BALANCE), keeping only
-- the customers with more than 3900 available.

-- Example 4-1.14
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET
FROM CUSTOMER
WHERE STREET LIKE '%St.';

-- Example 4-1.15
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE DESCRIPTION LIKE '%Kit';

-- Example 4-1.16
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE ITEM_ID LIKE '_F__';

-- >>> EXERCISE 5  (section 4-1, seed: kimtay_full)
-- Hint: One customer qualifies. A percent sign on both sides is what says anywhere in the value, rather than only at the end.
-- Customers whose street address ends in St.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET
FROM CUSTOMER
WHERE STREET LIKE '%St.';

-- Your turn: change the pattern to find streets that contain Ave. anywhere.

-- Example 4-1.17
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE CITY IN ('Maple Grove', 'Brookville');

-- Example 4-1.18
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE CITY = 'Maple Grove' OR CITY = 'Brookville';

-- Example 4-1.19
SELECT ITEM_ID, CATEGORY
FROM ITEM
WHERE CATEGORY NOT IN ('Habitat', 'Food');

-- >>> EXERCISE 6  (section 4-1, seed: kimtay_full)
-- Hint: Two rows either way, CF21 and GR15. If you get five rows, check that the list is inside one pair of parentheses.
-- Items in either of two categories, written the long way.
SELECT ITEM_ID, DESCRIPTION, CATEGORY
FROM ITEM
WHERE CATEGORY = 'Food' OR CATEGORY = 'Grooming';

-- Your turn: rewrite the condition with IN and confirm the rows are the same.
