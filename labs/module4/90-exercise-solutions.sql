-- ======================================================================
-- Module 4 · Solutions to the sandbox exercises
-- ======================================================================
--
-- One entry per exercise, in the same order as the numbered lesson files.
-- Each shows the starter the student begins from and the finished query.
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
SELECT *
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
SELECT ITEM_ID, CATEGORY, PRICE
FROM ITEM
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
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
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
SELECT CUSTOMER_NUM, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT
FROM CUSTOMER
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
WHERE BALANCE > 1000
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
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT * 9 AS ACADEMIC_YEAR_RENT
FROM ROOM
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
UPDATE CUSTOMER SET REP_NUM = NULL WHERE CUSTOMER_NUM = '1310';
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
SELECT COUNT(DISTINCT CATEGORY) AS DIFFERENT_CATEGORIES
FROM ITEM;

SELECT COUNT(*) AS HABITAT_ITEMS, AVG(PRICE) AS AVG_HABITAT_PRICE
FROM ITEM
WHERE CATEGORY = 'Habitat';

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
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, MIN(PRICE) AS LOWEST, MAX(PRICE) AS HIGHEST
FROM ITEM
GROUP BY CATEGORY
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
WHERE MONTHLY_RENT > 500.00
GROUP BY PROPERTY_ID
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
UPDATE STUDENT
SET HOME_STATE = NULL
WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
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
WHERE ON_HAND > 10
GROUP BY CATEGORY
ORDER BY CATEGORY;

-- ----------------------------------------------------------------------
-- Exercise 17  --  section Summary  --  seed: kimtay_full
-- ----------------------------------------------------------------------
-- Hint given: Run it as written -- one row, Habitat with 2 items averaging 46.37. Then change `HAVING COUNT(*) > 1` to `>= 1` and the other three categories reappear, in the order Habitat, Food, Grooming, Accessory.

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
WHERE PRICE BETWEEN 10 AND 70
GROUP BY CATEGORY
HAVING COUNT(*) >= 1
ORDER BY AVG_PRICE DESC;

-- ----------------------------------------------------------------------
-- Exercise 18  --  section Terms  --  seed: kimtay_full
-- ----------------------------------------------------------------------
-- Hint given: The starter returns four rows -- Accessory, Food, Grooming, Habitat. The worked answer groups instead of de-duplicating, so you also see that Habitat holds 2 items and the rest hold 1.

-- Starter:
--   SELECT DISTINCT CATEGORY
--   FROM ITEM
--   ORDER BY CATEGORY;

-- Solution:
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS
FROM ITEM
GROUP BY CATEGORY
ORDER BY CATEGORY;

-- ----------------------------------------------------------------------
-- Exercise 19  --  section Review  --  seed: both_full
-- ----------------------------------------------------------------------
-- Hint given: Both databases are loaded, so every review statement runs here -- all 11 tables: REP, CUSTOMER, ITEM, INVOICE, INVOICE_LINE, MANAGER, PROPERTY, ROOM, STUDENT, LEASE, PAYMENT.

-- Starter:
--   -- Paste a statement from a review question here, then run it.
--   SELECT * FROM ITEM;

-- Solution:


-- ----------------------------------------------------------------------
-- Exercise 20  --  section Exercises  --  seed: both_full
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
WHERE PRICE BETWEEN 15 AND 50
ORDER BY PRICE DESC;
