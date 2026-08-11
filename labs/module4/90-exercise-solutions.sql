-- ======================================================================
-- Module 4 · Solutions to the sandbox exercises
-- ======================================================================
--
-- One entry per exercise, in the same order as the numbered lesson files.
-- Each shows the starter the student begins from and the finished query,
-- with the line-by-line commentary the page carries.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Exercise 1  --  section 4-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Five rows either way; only the number of columns should change, from three to six.

-- Starter:
--   -- This returns three columns for all five items.
--   SELECT ITEM_ID, DESCRIPTION, PRICE
--   FROM ITEM;
--
--   -- Your turn: change it so that every column comes back, then run it again.

-- Solution:
-- SELECT *: every column, in the order the table declares them.
SELECT *
-- FROM: the table read. No WHERE clause, so all five rows come back.
FROM ITEM;

-- ----------------------------------------------------------------------
-- Exercise 2  --  section 4-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two rows before the parentheses, one row after. If both runs match, the parentheses landed in the wrong place.

-- Starter:
--   -- Run this as written and count the rows.
--   SELECT ITEM_ID, CATEGORY, PRICE
--   FROM ITEM
--   WHERE CATEGORY = 'Habitat' OR CATEGORY = 'Food' AND PRICE < 30;
--
--   -- Now add parentheses so that the price test applies to both categories.

-- Solution:
-- SELECT: the id plus the two columns being tested, so the filter is checkable by eye.
SELECT ITEM_ID, CATEGORY, PRICE
FROM ITEM
-- The parentheses matter: OR is evaluated first, then AND applies to the whole
-- bracket. Without them, AND would bind tighter and the query would mean
-- something quite different.
WHERE (CATEGORY = 'Habitat' OR CATEGORY = 'Food') AND PRICE < 30;

-- ----------------------------------------------------------------------
-- Exercise 3  --  section 4-1  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: Four of the five rooms qualify; only the 725.00 studio in Sycamore Court falls outside the window. The rents print as 595 and 450 here, without the trailing zeros.

-- Starter:
--   -- StayWell's leasing office wants every room renting from 450 through 610 a month.
--   SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
--   FROM ROOM
--   WHERE MONTHLY_RENT BETWEEN 450 AND 610;
--
--   -- Your turn: rewrite the condition using >= and <= and confirm you get the same rooms.

-- Solution:
-- SELECT: four columns from StayWell's room table.
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
-- Two comparisons joined by AND, each using >= or <= so both endpoints count.
-- BETWEEN 450 AND 610 would say exactly the same thing in fewer characters.
WHERE MONTHLY_RENT >= 450 AND MONTHLY_RENT <= 610;

-- ----------------------------------------------------------------------
-- Exercise 4  --  section 4-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two customers qualify. Repeat the whole expression in the WHERE clause instead of using the alias, so the query also runs on MySQL.

-- Starter:
--   -- Stock value per item, calculated on the fly.
--   SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
--   FROM ITEM;
--
--   -- Your turn: write a query on CUSTOMER that shows CUSTOMER_NUM and
--   -- the credit still available (CREDIT_LIMIT minus BALANCE), keeping only
--   -- the customers with more than 3900 available.

-- Solution:
-- SELECT: a computed column. The subtraction runs once per row and AS names it.
SELECT CUSTOMER_NUM, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT
FROM CUSTOMER
-- The calculation is repeated here rather than reusing AVAILABLE_CREDIT: WHERE is
-- evaluated before the SELECT list, so the alias does not exist yet.
WHERE CREDIT_LIMIT - BALANCE > 3900;

-- ----------------------------------------------------------------------
-- Exercise 5  --  section 4-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: One customer qualifies. A percent sign on both sides is what says anywhere in the value, rather than only at the end.

-- Starter:
--   -- Customers whose street address ends in St.
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET
--   FROM CUSTOMER
--   WHERE STREET LIKE '%St.';
--
--   -- Your turn: change the pattern to find streets that contain Ave. anywhere.

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET
FROM CUSTOMER
-- LIKE matches a pattern. % stands for any run of characters, so a % on both
-- sides means the word may appear anywhere inside the street.
WHERE STREET LIKE '%Ave.%';

-- ----------------------------------------------------------------------
-- Exercise 6  --  section 4-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two rows either way, CF21 and GR15. If you get five rows, check that the list is inside one pair of parentheses.

-- Starter:
--   -- Items in either of two categories, written the long way.
--   SELECT ITEM_ID, DESCRIPTION, CATEGORY
--   FROM ITEM
--   WHERE CATEGORY = 'Food' OR CATEGORY = 'Grooming';
--
--   -- Your turn: rewrite the condition with IN and confirm the rows are the same.

-- Solution:
SELECT ITEM_ID, DESCRIPTION, CATEGORY
FROM ITEM
-- IN is a membership test - true when CATEGORY equals any value in the list.
-- The same thing as CATEGORY = 'Food' OR CATEGORY = 'Grooming', but shorter.
WHERE CATEGORY IN ('Food', 'Grooming');

-- ----------------------------------------------------------------------
-- Exercise 7  --  section 4-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Run it as written (1225, 1120, 1420), then add DESC so the largest balance is on top.

-- Starter:
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE BALANCE > 1000
--   ORDER BY BALANCE;

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
-- WHERE filters first...
WHERE BALANCE > 1000
-- ...then ORDER BY sorts whatever survived. DESC puts the largest first.
ORDER BY BALANCE DESC;

-- ----------------------------------------------------------------------
-- Exercise 8  --  section 4-2  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: A StayWell room is let for a nine-month academic year; re-sort by ACADEMIC_YEAR_RENT descending so P200 201 (6525) leads and P100 102 (4050) trails.

-- Starter:
--   SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT * 9 AS ACADEMIC_YEAR_RENT
--   FROM ROOM
--   ORDER BY PROPERTY_ID, ROOM_NUM;

-- Solution:
-- The multiplication happens once per row, and AS names the result.
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT * 9 AS ACADEMIC_YEAR_RENT
FROM ROOM
-- Sorting by the alias is allowed, because ORDER BY runs after the SELECT list.
ORDER BY ACADEMIC_YEAR_RENT DESC;

-- ----------------------------------------------------------------------
-- Exercise 9  --  section 4-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Both statements run together, and only the SELECT prints a result. Press Reset when you are done -- it reloads the original KimTay data with the rep number back in place.

-- Starter:
--   -- Step 1: run this as it stands. Both counts come back as 4.
--   -- Step 2: delete the two dashes in front of the UPDATE line, run it again,
--   --         and watch WITH_A_REP drop to 3 while ALL_ROWS stays at 4.
--   -- UPDATE CUSTOMER SET REP_NUM = NULL WHERE CUSTOMER_NUM = '1310';
--   SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
--   FROM CUSTOMER;

-- Solution:
-- Create a null to study: this clears one customer's rep, it does not delete the row.
UPDATE CUSTOMER SET REP_NUM = NULL WHERE CUSTOMER_NUM = '1310';
-- COUNT(*) counts ROWS and COUNT(column) counts VALUES, skipping nulls. The gap
-- between the two numbers is exactly how many rows have no rep recorded.
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
FROM CUSTOMER;

-- ----------------------------------------------------------------------
-- Exercise 10  --  section 4-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Question 2 needs a WHERE clause; question 3 needs three functions in one SELECT list.

-- Starter:
--   -- ITEM holds 5 rows. Answer three questions, one query at a time.
--   -- 1. How many different categories are there? (written for you)
--   -- 2. How many Habitat items are there, and what do they average in price?
--   -- 3. How many units are on hand across all items, and what are the highest
--   --    and lowest prices in the catalog?
--   SELECT COUNT(DISTINCT CATEGORY) AS DIFFERENT_CATEGORIES
--   FROM ITEM;

-- Solution:
-- COUNT(DISTINCT column): how many DIFFERENT values appear, not how many rows.
SELECT COUNT(DISTINCT CATEGORY) AS DIFFERENT_CATEGORIES
FROM ITEM;

-- Two aggregates over the same filtered rows. The WHERE runs first, so both
-- numbers describe the habitat items only.
SELECT COUNT(*) AS HABITAT_ITEMS, AVG(PRICE) AS AVG_HABITAT_PRICE
FROM ITEM
WHERE CATEGORY = 'Habitat';

-- SUM adds the values in a column; MAX and MIN simply pick the largest and
-- smallest. All three collapse the whole table into one row.
SELECT SUM(ON_HAND) AS UNITS_ON_HAND,
       MAX(PRICE) AS HIGHEST_PRICE,
       MIN(PRICE) AS LOWEST_PRICE
FROM ITEM;

-- ----------------------------------------------------------------------
-- Exercise 11  --  section 4-4  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Run it to see all four customers, then add a WHERE that compares BALANCE to a subquery over the whole table -- the four balances total 9533.25, so the average is 2383.3125 and two customers should survive.

-- Starter:
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   ORDER BY BALANCE DESC;

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
-- The subquery runs first and collapses to one number, the average balance.
-- Being an aggregate over the whole table, it can only ever return one row,
-- which is what makes the plain > comparison safe here.
WHERE BALANCE > (SELECT AVG(BALANCE) FROM CUSTOMER)
ORDER BY BALANCE DESC;

-- ----------------------------------------------------------------------
-- Exercise 12  --  section 4-4  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: The inner query returns two property IDs, P100 and P200, because each property has one Double room. Nest it inside a query on PROPERTY to name both buildings, then swap IN for = and watch this engine hand back Millbrook Commons on its own.

-- Starter:
--   SELECT PROPERTY_ID
--   FROM ROOM
--   WHERE ROOM_TYPE = 'Double';

-- Solution:
SELECT PROPERTY_ID, PROPERTY_NAME
FROM PROPERTY
-- The subquery returns MANY property ids, so the test has to be IN and not =.
-- Read it as: keep this property if its id is one of the ids the inner query found.
WHERE PROPERTY_ID IN (SELECT PROPERTY_ID FROM ROOM WHERE ROOM_TYPE = 'Double')
ORDER BY PROPERTY_ID;

-- ----------------------------------------------------------------------
-- Exercise 13  --  section 4-5  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: MIN and MAX group the same way COUNT does. Expect Habitat first with 2, 27.75 and 64.99, then the three single-item categories, where the lowest and the highest are the same price.

-- Starter:
--   -- One row per category, with a count:
--   SELECT CATEGORY, COUNT(*) AS ITEM_COUNT
--   FROM ITEM
--   GROUP BY CATEGORY;
--
--   -- Your turn: keep the count, add the cheapest and the dearest price
--   -- in each category, and sort so the biggest category comes first.

-- Solution:
-- The grouping column, then three aggregates computed once PER GROUP.
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, MIN(PRICE) AS LOWEST, MAX(PRICE) AS HIGHEST
FROM ITEM
-- GROUP BY sorts the rows into piles, one pile per distinct category.
GROUP BY CATEGORY
-- Two sort keys: biggest count first, then category name to break ties.
ORDER BY ITEM_COUNT DESC, CATEGORY;

-- ----------------------------------------------------------------------
-- Exercise 14  --  section 4-5  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: The rent test is about one room row, the count test is about a finished group. The starter gives P100 with 2 rooms at 522.5 and P200 with 3 at 600; the finished query gives one row, P200 with 2 rooms at 667.5.

-- Starter:
--   -- Every property, every room:
--   SELECT PROPERTY_ID, COUNT(*) AS ROOM_COUNT, AVG(MONTHLY_RENT) AS AVG_RENT
--   FROM ROOM
--   GROUP BY PROPERTY_ID
--   ORDER BY PROPERTY_ID;
--
--   -- Your turn, one clause at a time:
--   --   1. count only rooms renting for more than 500.00
--   --   2. keep only the properties that still have more than one such room
--   --   3. sort by average rent, highest first

-- Solution:
SELECT PROPERTY_ID, COUNT(*) AS ROOM_COUNT, AVG(MONTHLY_RENT) AS AVG_RENT
FROM ROOM
-- WHERE runs FIRST and discards individual rows before any grouping happens.
WHERE MONTHLY_RENT > 500.00
-- GROUP BY piles up whatever survived, one pile per property.
GROUP BY PROPERTY_ID
-- HAVING runs LAST and discards whole piles. It is the only place an aggregate
-- may appear in a condition, and it is what WHERE cannot do.
HAVING COUNT(*) > 1
ORDER BY AVG_RENT DESC;

-- ----------------------------------------------------------------------
-- Exercise 15  --  section 4-6  --  seed: staywell_full
-- ----------------------------------------------------------------------

-- Hint given: Run it unchanged first. The page answers "Statement ran. 1 row affected." -- that 1 belongs to the UPDATE, and the absence of any result table is the SELECT matching nothing. Now swap the comparison for the null-aware test and you get a real grid: one row, S003, with NULL in HOME_STATE.

-- Starter:
--   -- Step 1: clear one home state so there is a null to study.
--   UPDATE STUDENT
--   SET HOME_STATE = NULL
--   WHERE STUDENT_ID = 'S003';
--
--   -- Step 2: this is meant to list the students whose home state is missing.
--   -- Run the box exactly as written first. No result table will appear at all,
--   -- because the condition below matches nothing. Then repair the condition.
--   SELECT STUDENT_ID, LAST_NAME, HOME_STATE
--   FROM STUDENT
--   WHERE HOME_STATE = NULL;

-- Solution:
-- Clear one value so there is a null to look for. NULL is a keyword, not text.
UPDATE STUDENT
SET HOME_STATE = NULL
WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
-- IS NULL is the only test that finds a missing value. = NULL never matches
-- anything, because comparing against an unknown gives unknown, not true.
WHERE HOME_STATE IS NULL;

-- ----------------------------------------------------------------------
-- Exercise 16  --  section 4-7  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: As written you get one row, Habitat. Delete the HAVING line and run it again to see the three single-item groups it was holding back, for four rows in total.

-- Starter:
--   -- All six clauses, in the order you write them.
--   SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVERAGE_PRICE
--   FROM ITEM
--   WHERE ON_HAND > 10
--   GROUP BY CATEGORY
--   HAVING COUNT(*) > 1
--   ORDER BY CATEGORY;

-- Solution:
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVERAGE_PRICE
FROM ITEM
-- Filter rows first: only well-stocked items reach a pile.
WHERE ON_HAND > 10
-- Then group what is left. Every column above is either grouped or aggregated,
-- which is the rule a grouped query has to obey.
GROUP BY CATEGORY
ORDER BY CATEGORY;

-- ----------------------------------------------------------------------
-- Exercise 17  --  section Summary  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Run it as written -- one row, Habitat with 2 items averaging 46.37. Then change HAVING COUNT(*) > 1 to >= 1 and the other three categories reappear, in the order Habitat, Food, Grooming, Accessory.

-- Starter:
--   SELECT CATEGORY, COUNT(*) AS NUM_ITEMS, AVG(PRICE) AS AVG_PRICE
--   FROM ITEM
--   WHERE PRICE BETWEEN 10 AND 70
--   GROUP BY CATEGORY
--   HAVING COUNT(*) > 1
--   ORDER BY AVG_PRICE DESC;

-- Solution:
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS, AVG(PRICE) AS AVG_PRICE
FROM ITEM
-- BETWEEN is inclusive at both ends, so a price of exactly 10 or 70 is kept.
WHERE PRICE BETWEEN 10 AND 70
GROUP BY CATEGORY
-- >= 1 keeps every pile that exists, so it changes nothing here. It is written
-- to show where the clause goes and that it belongs after GROUP BY.
HAVING COUNT(*) >= 1
ORDER BY AVG_PRICE DESC;

-- ----------------------------------------------------------------------
-- Exercise 18  --  section Key Terms  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The starter returns four rows -- Accessory, Food, Grooming, Habitat. The worked answer groups instead of de-duplicating, so you also see that Habitat holds 2 items and the rest hold 1.

-- Starter:
--   SELECT DISTINCT CATEGORY
--   FROM ITEM
--   ORDER BY CATEGORY;

-- Solution:
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS
FROM ITEM
-- One output row per distinct category, with COUNT(*) counting the rows in each.
GROUP BY CATEGORY
ORDER BY CATEGORY;

-- ----------------------------------------------------------------------
-- Exercise 19  --  section Review  --  seed: both_full
-- ----------------------------------------------------------------------

-- Hint given: Both databases are loaded, so every review statement runs here -- all 11 tables: REP, CUSTOMER, ITEM, INVOICE, INVOICE_LINE, MANAGER, PROPERTY, ROOM, STUDENT, LEASE, PAYMENT.

-- Starter:
--   -- Paste a statement from a review question here, then run it.
--   SELECT * FROM ITEM;

-- No canned solution: this sandbox is an open scratchpad.

-- ----------------------------------------------------------------------
-- Exercise 20  --  section Case Exercises  --  seed: both_full
-- ----------------------------------------------------------------------

-- Hint given: The starter lists all five items, priciest first. Add one clause to answer Exercise 1; the worked answer is one click away when you want to compare.

-- Starter:
--   -- Both databases are loaded. Exercise 1 starter:
--   SELECT ITEM_ID, DESCRIPTION, PRICE
--   FROM ITEM
--   ORDER BY PRICE DESC;

-- Solution:
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
-- BETWEEN tests a range and includes both endpoints. The smaller value must be
-- written first; reversed, the condition matches nothing at all.
WHERE PRICE BETWEEN 15 AND 50
ORDER BY PRICE DESC;
