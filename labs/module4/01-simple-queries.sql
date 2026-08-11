-- ======================================================================
-- Module 4 · Constructing Simple Queries
-- ======================================================================
--
-- Sections: 4-1
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 4-1  Constructing Simple Queries
-- ----------------------------------------------------------------------


-- Example 4-1.1
-- SELECT: names the three columns you want to see, in the order you want them.
--   Everything not listed here stays in the table and simply is not returned.
SELECT ITEM_ID, DESCRIPTION, PRICE

-- FROM: which table to read them out of. With no WHERE clause, every row of ITEM
--   comes back - all five of them.
FROM ITEM;

-- Example 4-1.2
-- SELECT *: the asterisk is shorthand for "every column, in the order the table
--   defines them". Handy while exploring, risky in saved code - the moment
--   somebody adds a column, your output silently changes shape.
SELECT *

-- FROM: the table being read. Five rows, six columns.
FROM ITEM;

-- >>> EXERCISE 1  (section 4-1, seed: kimtay_full)
-- Hint: Five rows either way; only the number of columns should change, from three to six.
-- This returns three columns for all five items.
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM;

-- Your turn: change it so that every column comes back, then run it again.

-- Example 4-1.4
-- SELECT: the three columns to display.
SELECT ITEM_ID, DESCRIPTION, ON_HAND

-- FROM: the table being read.
FROM ITEM

-- WHERE: the filter. It is tested once per row, and a row is returned only when
--   the condition comes back true. Two items are stocked below 25.
WHERE ON_HAND < 25;

-- Example 4-1.5
-- SELECT: two columns from the customer table.
SELECT CUSTOMER_NUM, CUSTOMER_NAME

-- FROM: the table being read.
FROM CUSTOMER

-- WHERE: an equality test against a text value, so the value goes in single
--   quotes. Numbers never take quotes; text and dates always do.
WHERE CITY = 'Maple Grove';

-- Example 4-1.6
-- SELECT: the id and the category, so the filter can be checked by eye.
SELECT ITEM_ID, CATEGORY

-- FROM: the table being read.
FROM ITEM

-- WHERE: <> means "not equal to". Some engines also accept !=, but <> is the
--   standard spelling and works everywhere.
WHERE CATEGORY <> 'Habitat';

-- Example 4-1.7
-- SELECT: three columns, including BALANCE so the second condition is visible.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE

-- FROM: the table being read.
FROM CUSTOMER

-- WHERE: the first of two conditions.
WHERE CITY = 'Maple Grove'

-- AND: a compound condition. BOTH sides must be true for the row to be kept, so
--   this is stricter than either condition alone. Companion Care Clinic is in
--   Maple Grove but owes nothing, so it fails here.
  AND BALANCE > 1000;

-- Example 4-1.8
-- SELECT: three columns.
SELECT ITEM_ID, DESCRIPTION, PRICE

-- FROM: the table being read.
FROM ITEM

-- WHERE: the first of two conditions.
WHERE CATEGORY = 'Food'

-- OR: EITHER side being true is enough to keep the row, so this is looser than
--   either condition alone. A row satisfying both is still returned once.
   OR PRICE > 60;

-- Example 4-1.9
-- SELECT: the id and the category being tested.
SELECT ITEM_ID, CATEGORY

-- FROM: the table being read.
FROM ITEM

-- WHERE: NOT reverses the condition inside the parentheses - keep the row when
--   the test is false. The parentheses are optional here but worth writing, as
--   they make it unmistakable which condition NOT applies to.
WHERE NOT (CATEGORY = 'Habitat');

-- >>> EXERCISE 2  (section 4-1, seed: kimtay_full)
-- Hint: Two rows before the parentheses, one row after. If both runs match, the parentheses landed in the wrong place.
-- Run this as written and count the rows.
SELECT ITEM_ID, CATEGORY, PRICE
FROM ITEM
WHERE CATEGORY = 'Habitat' OR CATEGORY = 'Food' AND PRICE < 30;

-- Now add parentheses so that the price test applies to both categories.

-- Example 4-1.11
-- SELECT: three columns, PRICE included so the range is easy to verify.
SELECT ITEM_ID, DESCRIPTION, PRICE

-- FROM: the table being read.
FROM ITEM

-- WHERE: BETWEEN tests a range and is INCLUSIVE at both ends, so an item priced
--   at exactly 15.25 or exactly 27.75 is kept. The smaller value must be written
--   first; reverse them and the condition matches nothing at all.
WHERE PRICE BETWEEN 15.25 AND 27.75;

-- Example 4-1.12
-- SELECT: the same three columns as the BETWEEN version above.
SELECT ITEM_ID, DESCRIPTION, PRICE

-- FROM: the same table.
FROM ITEM

-- WHERE: exactly what BETWEEN means, spelled out. Two comparisons joined by AND,
--   each using >= or <= so both endpoints are included. Same rows, more typing -
--   which is the whole argument for BETWEEN.
WHERE PRICE >= 15.25 AND PRICE <= 27.75;

-- >>> EXERCISE 3  (section 4-1, seed: staywell_full)
-- Hint: Four of the five rooms qualify; only the 725.00 studio in Sycamore Court falls outside the window. The rents print as 595 and 450 here, without the trailing zeros.
-- StayWell's leasing office wants every room renting from 450 through 610 a month.
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT BETWEEN 450 AND 610;

-- Your turn: rewrite the condition using >= and <= and confirm you get the same rooms.

-- Example 4-1.14
-- SELECT: two stored columns, then a computed one. ON_HAND * PRICE is worked out
--   once for each row as the result is built; nothing is stored back in the
--   table. AS gives the computed column the heading ON_HAND_VALUE, which is
--   worth doing - without it the heading is the arithmetic itself.
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE

-- FROM: the table supplying both columns being multiplied.
FROM ITEM;

-- Example 4-1.15
-- SELECT: two stored columns plus a subtraction. The calculation answers a
--   question the table never stored: how much of the credit limit is still free.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT

-- FROM: the table holding both of the columns being subtracted.
FROM CUSTOMER;

-- >>> EXERCISE 4  (section 4-1, seed: kimtay_full)
-- Hint: Two customers qualify. Repeat the whole expression in the WHERE clause instead of using the alias, so the query also runs on MySQL.
-- Stock value per item, calculated on the fly.
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
FROM ITEM;

-- Your turn: write a query on CUSTOMER that shows CUSTOMER_NUM and
-- the credit still available (CREDIT_LIMIT minus BALANCE), keeping only
-- the customers with more than 3900 available.

-- Example 4-1.17
-- SELECT: three columns, STREET included so the pattern match is visible.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET

-- FROM: the table being read.
FROM CUSTOMER

-- WHERE: LIKE matches a pattern instead of an exact value. % stands for any run
--   of characters, including none, so '%St.' means "anything, ending in St.".
--   LIKE is for text only, and it is slower than = because every row's value has
--   to be examined character by character.
WHERE STREET LIKE '%St.';

-- Example 4-1.18
-- SELECT: the id and the description being matched.
SELECT ITEM_ID, DESCRIPTION

-- FROM: the table being read.
FROM ITEM

-- WHERE: the same trailing-% pattern applied to product names - anything that
--   ends in the word Kit. Two of the five items do.
WHERE DESCRIPTION LIKE '%Kit';

-- Example 4-1.19
-- SELECT: the id and the description.
SELECT ITEM_ID, DESCRIPTION

-- FROM: the table being read.
FROM ITEM

-- WHERE: the other wildcard. _ stands for EXACTLY ONE character, so '_F__' means
--   a four-character id whose second character is F, with any characters in the
--   other three positions. FT88 does not qualify - its F is in position one.
WHERE ITEM_ID LIKE '_F__';

-- >>> EXERCISE 5  (section 4-1, seed: kimtay_full)
-- Hint: One customer qualifies. A percent sign on both sides is what says anywhere in the value, rather than only at the end.
-- Customers whose street address ends in St.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET
FROM CUSTOMER
WHERE STREET LIKE '%St.';

-- Your turn: change the pattern to find streets that contain Ave. anywhere.

-- Example 4-1.21
-- SELECT: three columns, CITY included so the membership test can be checked.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY

-- FROM: the table being read.
FROM CUSTOMER

-- WHERE: IN is a membership test - true when the row's CITY equals ANY value in
--   the parenthesised list. The list can be as long as you like, and each value
--   is separated by a comma.
WHERE CITY IN ('Maple Grove', 'Brookville');

-- Example 4-1.22
-- SELECT: the same three columns as the IN version above.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY

-- FROM: the same table.
FROM CUSTOMER

-- WHERE: exactly what IN means, written out as separate equality tests joined by
--   OR. Identical rows come back. IN is simply shorter, and stays readable when
--   the list grows to ten values instead of two.
WHERE CITY = 'Maple Grove' OR CITY = 'Brookville';

-- Example 4-1.23
-- SELECT: the id and the category being tested.
SELECT ITEM_ID, CATEGORY

-- FROM: the table being read.
FROM ITEM

-- WHERE: NOT IN keeps a row whose value matches NONE of the listed values. It is
--   the reverse of IN, and the same as writing CATEGORY <> 'Habitat' AND
--   CATEGORY <> 'Food'.
WHERE CATEGORY NOT IN ('Habitat', 'Food');

-- >>> EXERCISE 6  (section 4-1, seed: kimtay_full)
-- Hint: Two rows either way, CF21 and GR15. If you get five rows, check that the list is inside one pair of parentheses.
-- Items in either of two categories, written the long way.
SELECT ITEM_ID, DESCRIPTION, CATEGORY
FROM ITEM
WHERE CATEGORY = 'Food' OR CATEGORY = 'Grooming';

-- Your turn: rewrite the condition with IN and confirm the rows are the same.
