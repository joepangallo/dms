-- ======================================================================
-- Module 4 · Sorting
-- ======================================================================
--
-- Sections: 4-2
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 4-2  Sorting
-- ----------------------------------------------------------------------


-- Example 4-2.1
-- SELECT: three columns.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE

-- FROM: the table being read.
FROM CUSTOMER

-- ORDER BY: sorts the finished result. Without it a database makes no promise at
--   all about row order, so any report anybody is going to read needs one. Text
--   sorts alphabetically, and ascending is the default.
ORDER BY CUSTOMER_NAME;

-- Example 4-2.2
-- SELECT: three columns.
SELECT ITEM_ID, DESCRIPTION, PRICE

-- FROM: the table being read.
FROM ITEM

-- ORDER BY: DESC reverses the sort, putting the largest value first - the usual
--   choice for "most expensive", "biggest total", "newest". ASC is the default
--   and rarely needs writing.
ORDER BY PRICE DESC;

-- Example 4-2.3
-- SELECT: three columns.
SELECT ITEM_ID, DESCRIPTION, ON_HAND

-- FROM: the table being read.
FROM ITEM

-- WHERE: filters first - only well-stocked items get through.
WHERE ON_HAND > 20

-- ORDER BY: sorts what survived the filter. Order of clauses matters: WHERE
--   always comes before ORDER BY, and ORDER BY is always last.
ORDER BY ON_HAND DESC;

-- >>> EXERCISE 7  (section 4-2, seed: kimtay_full)
-- Hint: Run it as written (1225, 1120, 1420), then add DESC so the largest balance is on top.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > 1000
ORDER BY BALANCE;

-- Example 4-2.5
-- SELECT: three columns.
SELECT CUSTOMER_NAME, CITY, BALANCE

-- FROM: the table being read.
FROM CUSTOMER

-- ORDER BY: two sort keys. CITY is the major key and decides the overall order;
--   CUSTOMER_NAME is the minor key and only breaks ties inside one city. Swap
--   them and you get a different report.
ORDER BY CITY, CUSTOMER_NAME;

-- Example 4-2.6
-- SELECT: three columns.
SELECT CUSTOMER_NAME, CITY, BALANCE

-- FROM: the table being read.
FROM CUSTOMER

-- ORDER BY: DESC attaches to one column, not to the whole clause, so it has to
--   be repeated. Here both keys descend: cities in reverse alphabetical order,
--   and inside each city the largest balance first.
ORDER BY CITY DESC, BALANCE DESC;

-- Example 4-2.7
-- SELECT: four columns from StayWell's room table.
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT

-- FROM: the table being read.
FROM ROOM

-- ORDER BY: mixed directions. PROPERTY_ID ascends so the properties come out in
--   a predictable order, and within each property the rents descend - the usual
--   shape of a grouped listing.
ORDER BY PROPERTY_ID, MONTHLY_RENT DESC;

-- Example 4-2.8
-- SELECT: two stored columns and one computed column named with AS.
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE

-- FROM: the table being read.
FROM ITEM

-- ORDER BY: you may sort by the alias you just created. ORDER BY runs after the
--   SELECT list has been worked out, which is why the name is available here -
--   and why the same alias would NOT work in a WHERE clause.
ORDER BY ON_HAND_VALUE DESC;

-- Example 4-2.9
-- SELECT: three columns; their positions in this list are 1, 2 and 3.
SELECT DESCRIPTION, CATEGORY, PRICE

-- FROM: the table being read.
FROM ITEM

-- ORDER BY: sorting by column POSITION rather than name - 2 is CATEGORY and 3 is
--   PRICE. It is legal and compact, and it is also fragile: reorder the SELECT
--   list and the sort silently changes. Prefer names in anything you keep.
ORDER BY 2, 3 DESC;

-- >>> EXERCISE 8  (section 4-2, seed: staywell_full)
-- Hint: A StayWell room is let for a nine-month academic year; re-sort by ACADEMIC_YEAR_RENT descending so P200 201 (6525) leads and P100 102 (4050) trails.
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT * 9 AS ACADEMIC_YEAR_RENT
FROM ROOM
ORDER BY PROPERTY_ID, ROOM_NUM;
