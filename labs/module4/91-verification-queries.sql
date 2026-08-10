-- ======================================================================
-- Module 4 · Verification queries and expected results
-- ======================================================================
--
-- Every statement the module asserts a result for, with that expected result
-- as a comment. Use it to confirm a database was seeded correctly, or to
-- check a lab environment after changing engines.
--
-- Load first: 00-setup-both.sql
--
-- Statements marked INTENTIONALLY INVALID are expected to raise an error.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Group 4-1  --  58 checks
-- ----------------------------------------------------------------------

-- Check 1
-- Expected: 5 rows, 3 columns: AV07/Aviary Starter Cage/64.99, CF21/Grain-Free Dry Food 30lb/42.50, DG04/Nylon Dog Leash 6ft/11.99, FT88/Fish Tank Filter Kit/27.75, GR15/Small Animal Grooming Kit/15.25. MySQL prints 42.50; the browser engine prints 42.5 (trailing zeros dropped).
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM;

-- Check 2
-- Expected: 5 rows, same data as above with DESCRIPTION as the first column
SELECT DESCRIPTION, ITEM_ID, PRICE FROM ITEM;

-- Check 3
-- Expected: 5 rows, 6 columns in declaration order: ITEM_ID, DESCRIPTION, CATEGORY, ON_HAND, PRICE, REORDER_LEVEL
SELECT *
FROM ITEM;

-- Check 4
-- Expected: browser engine only: all 5 are real - 64.99, 42.5, 11.99, 27.75, 15.25. Confirms DECIMAL(7,2) is stored as binary floating point here, so trailing zeros are not printed.
SELECT typeof(PRICE), PRICE FROM ITEM;

-- Check 5
-- Expected: 2 rows: AV07/Aviary Starter Cage/15 and GR15/Small Animal Grooming Kit/22
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ON_HAND < 25;

-- Check 6
-- Expected: 3 rows: CF21, DG04, FT88
SELECT ITEM_ID FROM ITEM WHERE ON_HAND > 25;

-- Check 7
-- Expected: 1 row: CF21
SELECT ITEM_ID FROM ITEM WHERE PRICE = 42.50;

-- Check 8
-- Expected: 2 rows: DG04 and GR15
SELECT ITEM_ID FROM ITEM WHERE PRICE <= 15.25;

-- Check 9
-- Expected: 2 rows: 1120/Access Pet Center/7500.00 and 1310/Companion Care Clinic/10000.00 (printed 7500 and 10000 by the browser engine)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT FROM CUSTOMER WHERE CREDIT_LIMIT >= 7500;

-- Check 10
-- Expected: 2 rows: 1120/Access Pet Center and 1310/Companion Care Clinic
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CITY = 'Maple Grove';

-- Check 11
-- Expected: 1 row: 1120/Access Pet Center
SELECT CUSTOMER_NUM, CUSTOMER_NAME FROM CUSTOMER WHERE CUSTOMER_NUM = '1120';

-- Check 12  !! INTENTIONALLY INVALID -- expected to error
-- Expected: ERROR, no result set. Browser engine: syntax error near "Grove". MySQL: ERROR 1064 syntax error near 'Grove'. Backs the quiz claim that unquoted words are read as names and the statement never runs.
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE CITY = Maple Grove;

-- Check 13  !! INTENTIONALLY INVALID -- expected to error
-- Expected: ERROR, no result set. Browser engine: no such column: Northfield. MySQL: ERROR 1054 Unknown column 'Northfield' in 'where clause'. This is the single-bare-word case named in the quiz note.
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE CITY = Northfield;

-- Check 14
-- Expected: 3 rows: CF21/Food, DG04/Accessory, GR15/Grooming
SELECT ITEM_ID, CATEGORY
FROM ITEM
WHERE CATEGORY <> 'Habitat';

-- Check 15
-- Expected: 0 rows, no error - no item is below its reorder level
SELECT ITEM_ID, DESCRIPTION FROM ITEM WHERE ON_HAND < REORDER_LEVEL;

-- Check 16
-- Expected: 1 row: 1120/Access Pet Center/3512.50 (printed 3512.5 by the browser engine); 1310 fails because its balance is 0.00
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CITY = 'Maple Grove'
  AND BALANCE > 1000;

-- Check 17
-- Expected: 2 rows in this order: AV07/Aviary Starter Cage/64.99 and CF21/Grain-Free Dry Food 30lb/42.50
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE CATEGORY = 'Food'
   OR PRICE > 60;

-- Check 18
-- Expected: 3 rows: CF21/Food, DG04/Accessory, GR15/Grooming - identical to the <> version
SELECT ITEM_ID, CATEGORY
FROM ITEM
WHERE NOT (CATEGORY = 'Habitat');

-- Check 19
-- Expected: 2 rows: AV07/Habitat/64.99 and FT88/Habitat/27.75 (AND binds first, so both Habitat rows pass untested on price)
SELECT ITEM_ID, CATEGORY, PRICE
FROM ITEM
WHERE CATEGORY = 'Habitat' OR CATEGORY = 'Food' AND PRICE < 30;

-- Check 20
-- Expected: 1 row: FT88/Habitat/27.75
SELECT ITEM_ID, CATEGORY, PRICE
FROM ITEM
WHERE (CATEGORY = 'Habitat' OR CATEGORY = 'Food') AND PRICE < 30;

-- Check 21
-- Expected: 2 rows in this order: FT88/Fish Tank Filter Kit/27.75 and GR15/Small Animal Grooming Kit/15.25 - both endpoints included
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE BETWEEN 15.25 AND 27.75;

-- Check 22
-- Expected: 2 rows, identical to the BETWEEN version: FT88 and GR15
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE >= 15.25 AND PRICE <= 27.75;

-- Check 23
-- Expected: 0 rows, no error - the endpoints are reversed
SELECT ITEM_ID, PRICE FROM ITEM WHERE PRICE BETWEEN 27.75 AND 15.25;

-- Check 24
-- Expected: 4 rows: P100/101/Single/595.00, P100/102/Double/450.00, P200/101/Single/610.00, P200/202/Double/465.00 (the 725.00 Studio at P200/201 is excluded). The browser engine prints the rents as 595, 450, 610, 465 because these values have no fractional part.
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT BETWEEN 450 AND 610;

-- Check 25
-- Expected: 4 rows, identical to the BETWEEN version
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT >= 450 AND MONTHLY_RENT <= 610;

-- Check 26
-- Expected: 5 rows. Browser engine prints AV07 974.8499999999999, CF21 2040, DG04 1438.8, FT88 832.5, GR15 335.5. MySQL DECIMAL arithmetic prints AV07 974.85, CF21 2040.00, DG04 1438.80, FT88 832.50, GR15 335.50. The AV07 tail is binary floating point, not an arithmetic error.
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
FROM ITEM;

-- Check 27
-- Expected: browser engine only, full precision: AV07 974.849999999999909, CF21 2040.0, DG04 1438.799999999999955, FT88 832.5, GR15 335.5. Confirms AV07 cannot print as 974.85 here and DG04 rounds back to 1438.8.
SELECT ITEM_ID, printf('%!.20g', ON_HAND * PRICE) FROM ITEM;

-- Check 28
-- Expected: 4 rows: 1120 3987.50, 1225 3800.00, 1310 10000.00, 1420 1179.25. The browser engine prints 3987.5, 3800, 10000, 1179.25.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT
FROM CUSTOMER;

-- Check 29
-- Expected: 2 rows: 1120 with 3987.50 and 1310 with 10000.00 (1225 at 3800.00 falls short). Runs on both engines.
SELECT CUSTOMER_NUM, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT
FROM CUSTOMER
WHERE CREDIT_LIMIT - BALANCE > 3900;

-- Check 30
-- Expected: Engine difference confirmed: the browser engine accepts the alias in WHERE and returns 2 rows (1120 3987.5, 1310 10000); MySQL rejects it with ERROR 1054 Unknown column 'AVAILABLE_CREDIT' in 'where clause'. This is why the lesson repeats the expression.
SELECT CUSTOMER_NUM, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT FROM CUSTOMER WHERE AVAILABLE_CREDIT > 3900;

-- Check 31
-- Expected: 2 rows: 1225/Downtown Aquarium & Pets/642 Chestnut St. and 1420/Whiskers & Wags Boutique/77 Elm St.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET
FROM CUSTOMER
WHERE STREET LIKE '%St.';

-- Check 32
-- Expected: 2 rows: FT88/Fish Tank Filter Kit and GR15/Small Animal Grooming Kit
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE DESCRIPTION LIKE '%Kit';

-- Check 33
-- Expected: 1 row: CF21/Grain-Free Dry Food 30lb (FT88 has its F in first place, so it is excluded)
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE ITEM_ID LIKE '_F__';

-- Check 34
-- Expected: 2 rows: CF21 and FT88 - backs the quiz note that % finds F anywhere
SELECT ITEM_ID FROM ITEM WHERE ITEM_ID LIKE '%F%';

-- Check 35
-- Expected: 1 row: FT88 - backs the quiz note that this pattern pins F to the first position
SELECT ITEM_ID FROM ITEM WHERE ITEM_ID LIKE 'F___';

-- Check 36
-- Expected: 2 rows: 1225 and 1420 - same rows here, but the trailing % unanchors the end, which is the point of the distractor
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE STREET LIKE '%St.%';

-- Check 37
-- Expected: 1 row: 1120/Access Pet Center/215 Foster Ave.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET
FROM CUSTOMER
WHERE STREET LIKE '%Ave.%';

-- Check 38
-- Expected: 0 rows on both engines - no description contains cat in any letter case (Cage does not qualify)
SELECT ITEM_ID, DESCRIPTION FROM ITEM WHERE DESCRIPTION LIKE '%Cat%';

-- Check 39
-- Expected: 3 rows: 1120/Maple Grove, 1310/Maple Grove, 1420/Brookville
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE CITY IN ('Maple Grove', 'Brookville');

-- Check 40
-- Expected: 3 rows, identical to the IN version: 1120, 1310, 1420
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE CITY = 'Maple Grove' OR CITY = 'Brookville';

-- Check 41
-- Expected: 0 rows, no error - one CITY value cannot equal both
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE CITY = 'Maple Grove' AND CITY = 'Brookville';

-- Check 42
-- Expected: 2 rows: DG04/Accessory and GR15/Grooming
SELECT ITEM_ID, CATEGORY
FROM ITEM
WHERE CATEGORY NOT IN ('Habitat', 'Food');

-- Check 43
-- Expected: 2 rows: CF21/Grain-Free Dry Food 30lb/Food and GR15/Small Animal Grooming Kit/Grooming
SELECT ITEM_ID, DESCRIPTION, CATEGORY
FROM ITEM
WHERE CATEGORY = 'Food' OR CATEGORY = 'Grooming';

-- Check 44
-- Expected: 2 rows, identical to the OR version: CF21 and GR15
SELECT ITEM_ID, DESCRIPTION, CATEGORY
FROM ITEM
WHERE CATEGORY IN ('Food', 'Grooming');

-- Check 45
-- Expected: 0 rows, no error - the asterisk is not a wildcard inside a comparison
SELECT ITEM_ID, DESCRIPTION, PRICE FROM ITEM WHERE ITEM_ID = '*';

-- Check 46
-- Expected: 2 rows: FT88/27.75 and GR15/15.25 (matcher card)
SELECT ITEM_ID, PRICE FROM ITEM WHERE PRICE BETWEEN 15.25 AND 27.75;

-- Check 47
-- Expected: 2 rows: FT88/27.75 and GR15/15.25 (matcher card)
SELECT ITEM_ID, PRICE FROM ITEM WHERE PRICE >= 15.25 AND PRICE <= 27.75;

-- Check 48
-- Expected: 3 rows: 1120/Maple Grove, 1310/Maple Grove, 1420/Brookville (matcher card)
SELECT CUSTOMER_NUM, CITY FROM CUSTOMER WHERE CITY IN ('Maple Grove', 'Brookville');

-- Check 49
-- Expected: 2 rows: CF21/Food and GR15/Grooming (matcher card)
SELECT ITEM_ID, CATEGORY FROM ITEM WHERE CATEGORY IN ('Food', 'Grooming');

-- Check 50
-- Expected: 5 rows, no filtering: AV07 974.8499999999999, CF21 2040, DG04 1438.8, FT88 832.5, GR15 335.5 on this page (974.85 / 2040.00 / 1438.80 / 832.50 / 335.50 on MySQL)
SELECT ITEM_ID, ON_HAND * PRICE AS ON_HAND_VALUE FROM ITEM;

-- Check 51
-- Expected: 4 rows, no filtering: 1120 3987.50, 1225 3800.00, 1310 10000.00, 1420 1179.25
SELECT CUSTOMER_NUM, CREDIT_LIMIT - BALANCE AS AVAILABLE_CREDIT FROM CUSTOMER;

-- Check 52
-- Expected: 4 rows: 1120, 1225, 1310, 1420 - every customer
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE STATE = 'OH';

-- Check 53
-- Expected: 5 rows: AV07, CF21, DG04, FT88, GR15 - every item
SELECT ITEM_ID FROM ITEM WHERE PRICE > 0;

-- Check 54
-- Expected: 4 rows: 1120, 1225, 1310, 1420 - every customer
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE CITY IN ('Maple Grove', 'Brookville', 'Northfield');

-- Check 55
-- Expected: 2 rows: AV07 and GR15
SELECT ITEM_ID FROM ITEM WHERE ON_HAND < 25;

-- Check 56
-- Expected: 2 rows: 1225 and 1420
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE STREET LIKE '%St.';

-- Check 57
-- Expected: 0 rows - reversed endpoints
SELECT ITEM_ID FROM ITEM WHERE PRICE BETWEEN 27.75 AND 15.25;

-- Check 58
-- Expected: 0 rows - no customer is over the credit limit
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE BALANCE > CREDIT_LIMIT;

-- ----------------------------------------------------------------------
-- Group 4-2  --  25 checks
-- ----------------------------------------------------------------------

-- Check 59
-- Expected: 4 rows in this order: 1120 Access Pet Center 3512.50; 1310 Companion Care Clinic 0.00; 1225 Downtown Aquarium & Pets 1200.00; 1420 Whiskers & Wags Boutique 4820.75 (SQLite prints the balances as 3512.5, 0, 1200, 4820.75)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
ORDER BY CUSTOMER_NAME;

-- Check 60
-- Expected: 5 rows: AV07 64.99; CF21 42.50; FT88 27.75; GR15 15.25; DG04 11.99
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
ORDER BY PRICE DESC;

-- Check 61
-- Expected: The same 5 rows reversed: DG04 11.99; GR15 15.25; FT88 27.75; CF21 42.50; AV07 64.99
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
ORDER BY PRICE;

-- Check 62
-- Expected: 5 rows, descriptions Z to A: GR15 Small Animal Grooming Kit; DG04 Nylon Dog Leash 6ft; CF21 Grain-Free Dry Food 30lb; FT88 Fish Tank Filter Kit; AV07 Aviary Starter Cage
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
ORDER BY DESCRIPTION DESC;

-- Check 63
-- Expected: 4 rows: DG04 120; CF21 48; FT88 30; GR15 22 (AV07 with 15 is filtered out)
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ON_HAND > 20
ORDER BY ON_HAND DESC;

-- Check 64
-- Expected: 3 rows: 1225 Downtown Aquarium & Pets 1200.00; 1120 Access Pet Center 3512.50; 1420 Whiskers & Wags Boutique 4820.75 (1310 at 0.00 is filtered out)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > 1000
ORDER BY BALANCE;

-- Check 65
-- Expected: 3 rows: 1420 Whiskers & Wags Boutique 4820.75; 1120 Access Pet Center 3512.50; 1225 Downtown Aquarium & Pets 1200.00
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > 1000
ORDER BY BALANCE DESC;

-- Check 66
-- Expected: 4 rows: Whiskers & Wags Boutique Brookville 4820.75; Access Pet Center Maple Grove 3512.50; Companion Care Clinic Maple Grove 0.00; Downtown Aquarium & Pets Northfield 1200.00
SELECT CUSTOMER_NAME, CITY, BALANCE
FROM CUSTOMER
ORDER BY CITY, CUSTOMER_NAME;

-- Check 67
-- Expected: 4 rows: Whiskers & Wags Boutique Brookville 4820.75; Companion Care Clinic Maple Grove 0.00; Access Pet Center Maple Grove 3512.50; Downtown Aquarium & Pets Northfield 1200.00 (the two Maple Grove rows flip compared with sorting by name)
SELECT CUSTOMER_NAME, CITY, BALANCE
FROM CUSTOMER
ORDER BY CITY, BALANCE;

-- Check 68
-- Expected: 4 rows: Downtown Aquarium & Pets Northfield 1200.00; Access Pet Center Maple Grove 3512.50; Companion Care Clinic Maple Grove 0.00; Whiskers & Wags Boutique Brookville 4820.75
SELECT CUSTOMER_NAME, CITY, BALANCE
FROM CUSTOMER
ORDER BY CITY DESC, BALANCE DESC;

-- Check 69
-- Expected: 4 rows: Whiskers & Wags Boutique Brookville 4820.75; Access Pet Center Maple Grove 3512.50; Companion Care Clinic Maple Grove 0.00; Downtown Aquarium & Pets Northfield 1200.00
SELECT CUSTOMER_NAME, CITY, BALANCE
FROM CUSTOMER
ORDER BY CITY, BALANCE DESC;

-- Check 70
-- Expected: 5 rows: P100 101 Single 595.00; P100 102 Double 450.00; P200 201 Studio 725.00; P200 101 Single 610.00; P200 202 Double 465.00
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
ORDER BY PROPERTY_ID, MONTHLY_RENT DESC;

-- Check 71
-- Expected: 5 rows: CF21 2040.00; DG04 1438.80; AV07 974.85; FT88 832.50; GR15 335.50 (SQLite prints 2040.0, 1438.8, 974.85, 832.5, 335.5 -- same values, no trailing zeros)
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
FROM ITEM
ORDER BY ON_HAND_VALUE DESC;

-- Check 72
-- Expected: Same 5 rows and same order as sorting by the alias: CF21 2040.00; DG04 1438.80; AV07 974.85; FT88 832.50; GR15 335.50
SELECT ITEM_ID, DESCRIPTION, ON_HAND * PRICE AS ON_HAND_VALUE
FROM ITEM
ORDER BY ON_HAND * PRICE DESC;

-- Check 73
-- Expected: 5 rows in ascending ON_HAND order: AV07 15 64.99; GR15 22 15.25; FT88 30 27.75; CF21 48 42.50; DG04 120 11.99 -- the 120 leashes come LAST, which is why this is not a substitute for ordering on ON_HAND * PRICE (quiz 3, option A)
SELECT ITEM_ID, ON_HAND, PRICE
FROM ITEM
ORDER BY ON_HAND, PRICE DESC;

-- Check 74
-- Expected: 5 rows: Nylon Dog Leash 6ft Accessory 11.99; Grain-Free Dry Food 30lb Food 42.50; Small Animal Grooming Kit Grooming 15.25; Aviary Starter Cage Habitat 64.99; Fish Tank Filter Kit Habitat 27.75
SELECT DESCRIPTION, CATEGORY, PRICE
FROM ITEM
ORDER BY 2, 3 DESC;

-- Check 75
-- Expected: Identical to ORDER BY 2, 3 DESC: Nylon Dog Leash 6ft Accessory 11.99; Grain-Free Dry Food 30lb Food 42.50; Small Animal Grooming Kit Grooming 15.25; Aviary Starter Cage Habitat 64.99; Fish Tank Filter Kit Habitat 27.75
SELECT DESCRIPTION, CATEGORY, PRICE
FROM ITEM
ORDER BY CATEGORY, PRICE DESC;

-- Check 76
-- Expected: Quiz 1 option D: the Habitat block reads Fish Tank Filter Kit 27.75 then Aviary Starter Cage 64.99 -- cheapest first inside each category
SELECT DESCRIPTION, CATEGORY, PRICE
FROM ITEM
ORDER BY CATEGORY, PRICE;

-- Check 77
-- Expected: Quiz 1 option C: Aviary Starter Cage Habitat 64.99; Fish Tank Filter Kit Habitat 27.75; Small Animal Grooming Kit Grooming 15.25; Grain-Free Dry Food 30lb Food 42.50; Nylon Dog Leash 6ft Accessory 11.99 -- categories run Habitat, Grooming, Food, Accessory
SELECT DESCRIPTION, CATEGORY, PRICE
FROM ITEM
ORDER BY CATEGORY DESC, PRICE DESC;

-- Check 78
-- Expected: Quiz 1 option A: Aviary Starter Cage Habitat 64.99; Grain-Free Dry Food 30lb Food 42.50; Fish Tank Filter Kit Habitat 27.75; Small Animal Grooming Kit Grooming 15.25; Nylon Dog Leash 6ft Accessory 11.99 -- the two Habitat rows sit in positions 1 and 3, and CATEGORY never breaks a tie because no two prices are equal
SELECT DESCRIPTION, CATEGORY, PRICE
FROM ITEM
ORDER BY PRICE DESC, CATEGORY;

-- Check 79
-- Expected: 3 rows: P100 101 595.00; P200 101 610.00; P200 201 725.00
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT >= 500
ORDER BY MONTHLY_RENT;

-- Check 80
-- Expected: Quiz 2 option B: 3 rows in the wrong direction: P200 201 725.00; P200 101 610.00; P100 101 595.00
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT >= 500
ORDER BY MONTHLY_RENT DESC;

-- Check 81
-- Expected: Quiz 2 option C: all 5 rows: P100 102 450.00; P200 202 465.00; P100 101 595.00; P200 101 610.00; P200 201 725.00 -- the two sub-500 rooms are not filtered out
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT
FROM ROOM
ORDER BY MONTHLY_RENT;

-- Check 82
-- Expected: 5 rows: P100 101 5355.00; P100 102 4050.00; P200 101 5490.00; P200 201 6525.00; P200 202 4185.00
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT * 9 AS ACADEMIC_YEAR_RENT
FROM ROOM
ORDER BY PROPERTY_ID, ROOM_NUM;

-- Check 83
-- Expected: 5 rows: P200 201 6525.00; P200 101 5490.00; P100 101 5355.00; P200 202 4185.00; P100 102 4050.00
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT * 9 AS ACADEMIC_YEAR_RENT
FROM ROOM
ORDER BY ACADEMIC_YEAR_RENT DESC;

-- ----------------------------------------------------------------------
-- Group 4-3  --  34 checks
-- ----------------------------------------------------------------------

-- Check 84
-- Expected: One row, one column headed COUNT(*), value 5. Verified in SQLite.
SELECT COUNT(*)
FROM ITEM;

-- Check 85
-- Expected: One row: ITEM_COUNT = 2 (AV07 and FT88). Verified in SQLite.
SELECT COUNT(*) AS ITEM_COUNT
FROM ITEM
WHERE CATEGORY = 'Habitat';

-- Check 86
-- Expected: One row: ALL_ROWS = 4, WITH_A_REP = 4 on the shipped data (no seeded row is null). Verified in SQLite.
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
FROM CUSTOMER;

-- Check 87
-- Expected: Sandbox 1 starter. The UPDATE is commented out, so only the SELECT runs: ALL_ROWS = 4, WITH_A_REP = 4. Verified in SQLite.
-- Step 1: run this as it stands. Both counts come back as 4.
-- Step 2: delete the two dashes in front of the UPDATE line, run it again,
--         and watch WITH_A_REP drop to 3 while ALL_ROWS stays at 4.
-- UPDATE CUSTOMER SET REP_NUM = NULL WHERE CUSTOMER_NUM = '1310';
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
FROM CUSTOMER;

-- Check 88
-- Expected: Sandbox 1 solution. sql.js runs both statements and returns one result set (the SELECT only): ALL_ROWS = 4, WITH_A_REP = 3. Verified in SQLite.
UPDATE CUSTOMER SET REP_NUM = NULL WHERE CUSTOMER_NUM = '1310';
SELECT COUNT(*) AS ALL_ROWS, COUNT(REP_NUM) AS WITH_A_REP
FROM CUSTOMER;

-- Check 89
-- Expected: One row: TOTAL_OWED = 9533.25. Verified in SQLite; MySQL prints 9533.25 as well (SUM keeps the DECIMAL(9,2) scale).
SELECT SUM(BALANCE) AS TOTAL_OWED
FROM CUSTOMER;

-- Check 90
-- Expected: One row: OWED_TO_REP_20 = 3512.5 in SQLite (verified); MySQL prints 3512.50. Difference is stated in the prose.
SELECT SUM(BALANCE) AS OWED_TO_REP_20
FROM CUSTOMER
WHERE REP_NUM = '20';

-- Check 91
-- Expected: One row: ROWS_FOUND = 0 and TOTAL = NULL (renders as an empty cell). Verified in SQLite; identical in MySQL.
SELECT COUNT(*) AS ROWS_FOUND, SUM(BALANCE) AS TOTAL FROM CUSTOMER WHERE BALANCE > 10000;

-- Check 92
-- Expected: One row: AVG_PRICE = 32.496, HIGHEST = 64.99, LOWEST = 11.99. Verified in SQLite; MySQL shows AVG_PRICE as 32.496000 (AVG widens a DECIMAL's scale). Difference is stated in the prose.
SELECT AVG(PRICE) AS AVG_PRICE,
       MAX(PRICE) AS HIGHEST,
       MIN(PRICE) AS LOWEST
FROM ITEM;

-- Check 93
-- Expected: One row: AVG_BALANCE = 2383.3125. Verified in SQLite; MySQL prints 2383.312500.
SELECT AVG(BALANCE) AS AVG_BALANCE FROM CUSTOMER;

-- Check 94
-- Expected: Updates 1 row; no result set. Used in the 'Null is not zero' callout, paired with the next statement, and undone with Reset.
UPDATE CUSTOMER SET BALANCE = NULL WHERE CUSTOMER_NUM = '1310';

-- Check 95
-- Expected: Run after the UPDATE above: one row with TOTAL = 9533.25, AVG_BALANCE = 3177.75, COUNTED = 3. Verified in SQLite. (On unmodified data it would be 9533.25, 2383.3125, 4.)
SELECT SUM(BALANCE) AS TOTAL, AVG(BALANCE) AS AVG_BALANCE, COUNT(BALANCE) AS COUNTED FROM CUSTOMER;

-- Check 96
-- Expected: One row: FIRST_INVOICE = 2026-06-14, LAST_INVOICE = 2026-06-15. Verified in SQLite (the ISO date text sorts correctly); same in MySQL as a DATE.
SELECT MIN(INVOICE_DATE) AS FIRST_INVOICE,
       MAX(INVOICE_DATE) AS LAST_INVOICE
FROM INVOICE;

-- Check 97
-- Expected: One row: FIRST_ALPHABETICALLY = Hull, LAST_ALPHABETICALLY = Perez. Verified in SQLite; the three names differ in their first letter, so MySQL's case-insensitive default collation gives the same answer.
SELECT MIN(LAST_NAME) AS FIRST_ALPHABETICALLY, MAX(LAST_NAME) AS LAST_ALPHABETICALLY FROM REP;

-- Check 98
-- Expected: Shown only as a warning example. Verified in SQLite: one row, Aviary Starter Cage and 64.99, because SQLite has a documented rule for a query whose sole aggregate is a lone MIN or MAX. MySQL rejects it under the default ONLY_FULL_GROUP_BY sql_mode. The prose flags the difference.
SELECT DESCRIPTION, MAX(PRICE) FROM ITEM;

-- Check 99
-- Expected: Four rows, one per customer: Maple Grove, Northfield, Maple Grove, Brookville. No ORDER BY, so the order is not guaranteed; the prose says so and only claims the duplicate.
SELECT CITY
FROM CUSTOMER;

-- Check 100
-- Expected: Three rows: Brookville, Maple Grove, Northfield. Verified in SQLite.
SELECT DISTINCT CITY
FROM CUSTOMER
ORDER BY CITY;

-- Check 101
-- Expected: Three rows: Brookville OH, Maple Grove OH, Northfield OH. Verified in SQLite.
SELECT DISTINCT CITY, STATE
FROM CUSTOMER
ORDER BY CITY;

-- Check 102
-- Expected: One row, value 1 (every customer is in OH). Verified in SQLite.
SELECT COUNT(DISTINCT STATE) FROM CUSTOMER;

-- Check 103
-- Expected: One row: 4, 4, 3. Verified in SQLite.
SELECT COUNT(*) AS ALL_ROWS,
       COUNT(CITY) AS CITY_VALUES,
       COUNT(DISTINCT CITY) AS DIFFERENT_CITIES
FROM CUSTOMER;

-- Check 104
-- Expected: One row: 6, 3, 5. Verified in SQLite.
SELECT COUNT(*) AS LINE_COUNT,
       COUNT(DISTINCT INVOICE_NUM) AS INVOICES,
       COUNT(DISTINCT ITEM_ID) AS ITEMS
FROM INVOICE_LINE;

-- Check 105  !! INTENTIONALLY INVALID -- expected to error
-- Expected: Named in the 'Where DISTINCT goes' callout as an engine difference, not offered as a working example. Verified: SQLite raises 'wrong number of arguments to function COUNT()'. MySQL accepts COUNT(DISTINCT expr, expr) and would return 3 here.
SELECT COUNT(DISTINCT CITY, STATE) FROM CUSTOMER;

-- Check 106
-- Expected: Sandbox 2 starter: one row, DIFFERENT_CATEGORIES = 4 (Habitat, Food, Accessory, Grooming). Verified in SQLite.
-- ITEM holds 5 rows. Answer three questions, one query at a time.
-- 1. How many different categories are there? (written for you)
-- 2. How many Habitat items are there, and what do they average in price?
-- 3. How many units are on hand across all items, and what are the highest
--    and lowest prices in the catalog?
SELECT COUNT(DISTINCT CATEGORY) AS DIFFERENT_CATEGORIES
FROM ITEM;

-- Check 107
-- Expected: Sandbox 2 solution, three result sets: (1) DIFFERENT_CATEGORIES = 4; (2) HABITAT_ITEMS = 2, AVG_HABITAT_PRICE = 46.37 (MySQL: 46.370000); (3) UNITS_ON_HAND = 235, HIGHEST_PRICE = 64.99, LOWEST_PRICE = 11.99. All verified in SQLite.
SELECT COUNT(DISTINCT CATEGORY) AS DIFFERENT_CATEGORIES
FROM ITEM;

SELECT COUNT(*) AS HABITAT_ITEMS, AVG(PRICE) AS AVG_HABITAT_PRICE
FROM ITEM
WHERE CATEGORY = 'Habitat';

SELECT SUM(ON_HAND) AS UNITS_ON_HAND,
       MAX(PRICE) AS HIGHEST_PRICE,
       MIN(PRICE) AS LOWEST_PRICE
FROM ITEM;

-- Check 108
-- Expected: Quoted in the summary table: one row, value 5. Verified in SQLite.
SELECT COUNT(*) FROM ITEM;

-- Check 109
-- Expected: Quoted in the summary table: one row, value 4 on the unmodified seed data. Verified in SQLite.
SELECT COUNT(REP_NUM) FROM CUSTOMER;

-- Check 110
-- Expected: Quoted in the summary table and matcher card 4: one row, value 9533.25. Verified in SQLite.
SELECT SUM(BALANCE) FROM CUSTOMER;

-- Check 111
-- Expected: Quoted in the summary table and matcher card 6: one row, value 32.496 (MySQL: 32.496000). Verified in SQLite.
SELECT AVG(PRICE) FROM ITEM;

-- Check 112
-- Expected: Quoted in the summary table and matcher card 7: one row, value 64.99. Verified in SQLite.
SELECT MAX(PRICE) FROM ITEM;

-- Check 113
-- Expected: Quoted in the summary table and matcher card 8: one row, value 0 in SQLite (verified); MySQL displays 0.00. The table says so.
SELECT MIN(BALANCE) FROM CUSTOMER;

-- Check 114
-- Expected: Quoted in the summary table and matcher card 2: one row, value 3. Verified in SQLite.
SELECT COUNT(DISTINCT CITY) FROM CUSTOMER;

-- Check 115
-- Expected: Matcher card 1: one row, value 6. Verified in SQLite.
SELECT COUNT(*) FROM INVOICE_LINE;

-- Check 116
-- Expected: Matcher card 3: one row, value 3. Verified in SQLite.
SELECT COUNT(DISTINCT INVOICE_NUM) FROM INVOICE_LINE;

-- Check 117
-- Expected: Matcher card 5: one row, value 235 (15+48+120+30+22). Verified in SQLite.
SELECT SUM(ON_HAND) FROM ITEM;

-- ----------------------------------------------------------------------
-- Group 4-4  --  18 checks
-- ----------------------------------------------------------------------

-- Check 118  !! INTENTIONALLY INVALID -- expected to error
-- Expected: Error in both engines, no rows. SQLite 3.51 (verified): 'misuse of aggregate function AVG()'. MySQL: error 1111 'Invalid use of group function'.
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE PRICE > AVG(PRICE);

-- Check 119
-- Expected: 1 row, 1 column: 32.496 (64.99 + 42.50 + 11.99 + 27.75 + 15.25 = 162.48, / 5 = 32.496). SQLite displays 32.496; MySQL displays 32.496000 because AVG over DECIMAL(7,2) widens the scale.
SELECT AVG(PRICE)
FROM ITEM;

-- Check 120
-- Expected: 2 rows in this order: AV07 | Aviary Starter Cage | 64.99, then CF21 | Grain-Free Dry Food 30lb | 42.50. Verified in SQLite, which displays the second price as 42.5; the lesson flags that display difference in a note.
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE > (SELECT AVG(PRICE) FROM ITEM)
ORDER BY PRICE DESC;

-- Check 121
-- Expected: 1 row, 1 column: Habitat. Verified.
SELECT CATEGORY
FROM ITEM
WHERE ITEM_ID = 'FT88';

-- Check 122
-- Expected: 2 rows in this order: AV07 | Aviary Starter Cage | 64.99, then FT88 | Fish Tank Filter Kit | 27.75. Verified.
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE CATEGORY = (SELECT CATEGORY FROM ITEM WHERE ITEM_ID = 'FT88')
ORDER BY ITEM_ID;

-- Check 123
-- Expected: 4 rows in this order: 1420 | Whiskers & Wags Boutique | 4820.75; 1120 | Access Pet Center | 3512.50; 1225 | Downtown Aquarium & Pets | 1200.00; 1310 | Companion Care Clinic | 0.00. (Sandbox 1 starter.) SQLite prints 3512.5, 1200.0 and 0.0.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
ORDER BY BALANCE DESC;

-- Check 124
-- Expected: 1 row, 1 column: 2383.3125 (3512.50 + 1200.00 + 0.00 + 4820.75 = 9533.25, / 4). Verified; value cited in the sandbox 1 hint.
SELECT AVG(BALANCE)
FROM CUSTOMER;

-- Check 125
-- Expected: 2 rows in this order: 1420 | Whiskers & Wags Boutique | 4820.75, then 1120 | Access Pet Center | 3512.50. (Sandbox 1 solution.) Verified.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > (SELECT AVG(BALANCE) FROM CUSTOMER)
ORDER BY BALANCE DESC;

-- Check 126
-- Expected: 4 rows, one column: CF21, DG04, CF21, FT88 (three distinct values). SQLite returned them in that order, but with no ORDER BY the order is not guaranteed and the lesson says so.
SELECT ITEM_ID
FROM INVOICE_LINE
WHERE NUM_ORDERED >= 2;

-- Check 127
-- Expected: 3 rows in this order: CF21 | Grain-Free Dry Food 30lb | 48; DG04 | Nylon Dog Leash 6ft | 120; FT88 | Fish Tank Filter Kit | 30. AV07 and GR15 are excluded. Verified.
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ITEM_ID IN (SELECT ITEM_ID FROM INVOICE_LINE WHERE NUM_ORDERED >= 2)
ORDER BY ITEM_ID;

-- Check 128
-- Expected: Engine-dependent, and the lesson says so. SQLite (this page, verified): 1 row, CF21 | Grain-Free Dry Food 30lb, no error -- it keeps the first value the unordered inner query produced. MySQL: error 1242 'Subquery returns more than 1 row', no rows.
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE ITEM_ID = (SELECT ITEM_ID FROM INVOICE_LINE WHERE NUM_ORDERED >= 2);

-- Check 129
-- Expected: 2 rows, one column: P100 (room 102) and P200 (room 202). (Sandbox 2 starter; staywell_full seed.) Verified against the shipped ROOM rows.
SELECT PROPERTY_ID
FROM ROOM
WHERE ROOM_TYPE = 'Double';

-- Check 130
-- Expected: 2 rows in this order: P100 | Millbrook Commons, then P200 | Sycamore Court. (Sandbox 2 solution.) Verified.
SELECT PROPERTY_ID, PROPERTY_NAME
FROM PROPERTY
WHERE PROPERTY_ID IN (SELECT PROPERTY_ID FROM ROOM WHERE ROOM_TYPE = 'Double')
ORDER BY PROPERTY_ID;

-- Check 131
-- Expected: Engine-dependent, as claimed by the sandbox 2 hint and quiz question 2. SQLite (verified): 1 row, P100 | Millbrook Commons, no error. MySQL: error 1242 'Subquery returns more than 1 row'.
SELECT PROPERTY_ID, PROPERTY_NAME
FROM PROPERTY
WHERE PROPERTY_ID = (SELECT PROPERTY_ID FROM ROOM WHERE ROOM_TYPE = 'Double')
ORDER BY PROPERTY_ID;

-- Check 132
-- Expected: 0 rows: no item is priced at exactly 32.496. Verified. (Claimed in quiz question 1, option note 3.)
SELECT ITEM_ID
FROM ITEM
WHERE PRICE IN (SELECT AVG(PRICE) FROM ITEM);

-- Check 133
-- Expected: 0 rows: every item's ON_HAND exceeds its REORDER_LEVEL (15>5, 48>15, 120>25, 30>10, 22>8). Verified. Cited only as a no-subquery-needed shape in the matcher; no row count is claimed to students.
SELECT ITEM_ID
FROM ITEM
WHERE ON_HAND < REORDER_LEVEL;

-- Check 134
-- Expected: 1 row: Whiskers & Wags Boutique. Verified. Cited only as a no-subquery-needed shape in the matcher; no row count is claimed to students.
SELECT CUSTOMER_NAME
FROM CUSTOMER
WHERE BALANCE > 4000;

-- Check 135  !! INTENTIONALLY INVALID -- expected to error
-- Expected: Error in both engines, no rows. SQLite (verified): 'sub-select returns 2 columns - expected 1'. MySQL: error 1241 'Operand should contain 1 column(s)'. (Matcher 'will not run' card.)
SELECT ITEM_ID
FROM ITEM
WHERE ITEM_ID IN (SELECT ITEM_ID, NUM_ORDERED FROM INVOICE_LINE);

-- ----------------------------------------------------------------------
-- Group 4-5  --  21 checks
-- ----------------------------------------------------------------------

-- Check 136
-- Expected: 4 rows: Accessory|1|11.99, Food|1|42.5, Grooming|1|15.25, Habitat|2|46.37
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVG_PRICE
FROM ITEM
GROUP BY CATEGORY;

-- Check 137
-- Expected: 3 rows in this order: 50710|151.48, 50712|120.49, 50711|100.25 (all three totals land on exact doubles, so no float artifacts appear)
SELECT INVOICE_NUM, SUM(NUM_ORDERED * QUOTED_PRICE) AS INVOICE_TOTAL
FROM INVOICE_LINE
GROUP BY INVOICE_NUM
ORDER BY INVOICE_TOTAL DESC;

-- Check 138
-- Expected: 4 rows: Accessory|1, Food|1, Grooming|1, Habitat|2 (sandbox 1 starter)
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY;

-- Check 139
-- Expected: 4 rows in this order: Habitat|2|27.75|64.99, Accessory|1|11.99|11.99, Food|1|42.5|42.5, Grooming|1|15.25|15.25 (sandbox 1 solution)
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, MIN(PRICE) AS LOWEST, MAX(PRICE) AS HIGHEST
FROM ITEM
GROUP BY CATEGORY
ORDER BY ITEM_COUNT DESC, CATEGORY;

-- Check 140
-- Expected: MySQL with ONLY_FULL_GROUP_BY rejects the statement. SQLite accepts it and returns 4 rows, with the Habitat row showing only one of its two descriptions and ITEM_COUNT 2; which description appears is unspecified by SQL (this SQLite build returns 'Aviary Starter Cage', but the lesson deliberately does not rely on that). Shown as a mistake.
SELECT CATEGORY, DESCRIPTION, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY;

-- Check 141
-- Expected: 5 rows, each with ITEM_COUNT 1: Accessory|Nylon Dog Leash 6ft, Food|Grain-Free Dry Food 30lb, Grooming|Small Animal Grooming Kit, Habitat|Aviary Starter Cage, Habitat|Fish Tank Filter Kit
SELECT CATEGORY, DESCRIPTION, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY, DESCRIPTION
ORDER BY CATEGORY, DESCRIPTION;

-- Check 142
-- Expected: 3 rows: 20|Maple Grove|2, 35|Northfield|1, 65|Brookville|1
SELECT REP_NUM, CITY, COUNT(*) AS CUSTOMER_COUNT
FROM CUSTOMER
GROUP BY REP_NUM, CITY
ORDER BY REP_NUM, CITY;

-- Check 143
-- Expected: 1 row: Habitat|2
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT
FROM ITEM
GROUP BY CATEGORY
HAVING COUNT(*) > 1;

-- Check 144  !! INTENTIONALLY INVALID -- expected to error
-- Expected: Error on both engines (this is the previous query with the test moved from HAVING up into WHERE). SQLite: 'misuse of aggregate: COUNT()'. MySQL: 'Invalid use of group function'. Shown deliberately as an illegal statement.
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT FROM ITEM WHERE COUNT(*) > 1 GROUP BY CATEGORY;

-- Check 145
-- Expected: 3 rows: 20|1, 35|1, 65|1 (question A -- rep 20 counts 1 because the 0.00 balance row is filtered out first)
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT
FROM CUSTOMER
WHERE BALANCE > 1000.00
GROUP BY REP_NUM
ORDER BY REP_NUM;

-- Check 146
-- Expected: 3 rows: 20|2, 35|1, 65|1 (question B -- rep 20 counts 2 because no row was filtered before grouping)
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT
FROM CUSTOMER
GROUP BY REP_NUM
HAVING SUM(BALANCE) > 1000.00
ORDER BY REP_NUM;

-- Check 147
-- Expected: 2 rows: Food|1, Habitat|2. Accessory and Grooming do not appear at all, not even with a count of 0.
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT FROM ITEM WHERE PRICE > 20.00 GROUP BY CATEGORY ORDER BY CATEGORY;

-- Check 148
-- Expected: 2 rows in this order: 65|1|4820.75, 20|1|3512.5 (rep 35 survives WHERE with 1200.00 but is then dropped by HAVING)
SELECT REP_NUM, COUNT(*) AS CUSTOMER_COUNT, SUM(BALANCE) AS TOTAL_OWED
FROM CUSTOMER
WHERE BALANCE > 1000.00
GROUP BY REP_NUM
HAVING SUM(BALANCE) > 2000.00
ORDER BY TOTAL_OWED DESC;

-- Check 149
-- Expected: 1 row: Habitat|2
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT FROM ITEM WHERE CATEGORY = 'Habitat' GROUP BY CATEGORY;

-- Check 150
-- Expected: 1 row: Habitat|2 -- the same result as the WHERE version, and legal on both engines because CATEGORY is the grouping column
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT FROM ITEM GROUP BY CATEGORY HAVING CATEGORY = 'Habitat';

-- Check 151
-- Expected: 2 rows: P100|2|522.5, P200|3|600 (sandbox 2 starter, StayWell). The browser sandbox renders the P200 average as 600, not 600.0, because sql.js hands back a plain JavaScript number; a MySQL server would show it padded to the DECIMAL scale instead.
SELECT PROPERTY_ID, COUNT(*) AS ROOM_COUNT, AVG(MONTHLY_RENT) AS AVG_RENT
FROM ROOM
GROUP BY PROPERTY_ID
ORDER BY PROPERTY_ID;

-- Check 152
-- Expected: 1 row: P200|2|667.5 (sandbox 2 solution, StayWell)
SELECT PROPERTY_ID, COUNT(*) AS ROOM_COUNT, AVG(MONTHLY_RENT) AS AVG_RENT
FROM ROOM
WHERE MONTHLY_RENT > 500.00
GROUP BY PROPERTY_ID
HAVING COUNT(*) > 1
ORDER BY AVG_RENT DESC;

-- Check 153
-- Expected: Backs quiz question 4's wrong option D. MySQL rejects it (MONTHLY_RENT is neither grouped nor aggregated). SQLite runs it and returns 2 rows, P100|2|522.5 and P200|3|600 -- the rent test filtered nothing, so sub-500 rooms are still counted and still in the averages.
SELECT PROPERTY_ID, COUNT(*) AS ROOM_COUNT, AVG(MONTHLY_RENT) AS AVG_RENT FROM ROOM GROUP BY PROPERTY_ID HAVING MONTHLY_RENT > 500.00 AND COUNT(*) > 1;

-- Check 154
-- Expected: 2 rows in this order: Habitat|46.37, Food|42.5 -- confirms SQLite accepts a SELECT alias in HAVING, as MySQL does, though strict standard SQL does not
SELECT CATEGORY, AVG(PRICE) AS AVG_PRICE FROM ITEM GROUP BY CATEGORY HAVING AVG_PRICE > 20.00 ORDER BY AVG_PRICE DESC;

-- Check 155
-- Expected: Backs the matcher card `ON_HAND > REORDER_LEVEL` in the WHERE zone: 4 rows, Accessory|1, Food|1, Grooming|1, Habitat|2 -- every seeded item is above its reorder level, and the column-to-column test needs no grouping.
SELECT CATEGORY, COUNT(*) AS C FROM ITEM WHERE ON_HAND > REORDER_LEVEL GROUP BY CATEGORY;

-- Check 156
-- Expected: Backs the matcher card `REP_NUM IN ('20','65')` in the 'either' zone: 2 rows, 20|2 and 65|1 -- identical to the WHERE version, because REP_NUM is the grouping column.
SELECT REP_NUM, COUNT(*) AS C FROM CUSTOMER GROUP BY REP_NUM HAVING REP_NUM IN ('20', '65');

-- ----------------------------------------------------------------------
-- Group 4-67  --  33 checks
-- ----------------------------------------------------------------------

-- Check 157
-- Expected: On a freshly seeded staywell_full database (no UPDATE run yet): 5 rows: P100|101|595, P100|102|450, P200|101|610, P200|201|725, P200|202|465
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT IS NOT NULL
ORDER BY PROPERTY_ID, ROOM_NUM;

-- Check 158
-- Expected: On a freshly seeded staywell_full database: 0 rows, because every seeded room has a rent
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT IS NULL;

-- Check 159
-- Expected: On a freshly seeded database: 1 row: 0 (no shipped StayWell row contains a null; the same holds for every KimTay table)
SELECT COUNT(*) AS ROWS_WITH_A_NULL
FROM STUDENT
WHERE STUDENT_ID IS NULL OR LAST_NAME IS NULL OR FIRST_NAME IS NULL
   OR EMAIL IS NULL OR HOME_STATE IS NULL;

-- Check 160
-- Expected: 4 rows: S001|Nguyen|OH, S002|Carter|PA, S003|Ibrahim|NULL, S004|Park|OH (this page's grid prints the missing value as the text NULL)
UPDATE STUDENT SET HOME_STATE = NULL WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
ORDER BY STUDENT_ID;

-- Check 161
-- Expected: 0 rows and no error. In this page's sandbox no result table is drawn at all; the message reads 'Statement ran. 1 row affected.', which is the UPDATE's row, not a match
UPDATE STUDENT SET HOME_STATE = NULL WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE = NULL;

-- Check 162
-- Expected: 0 rows, and no error
UPDATE STUDENT SET HOME_STATE = NULL WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE <> NULL;

-- Check 163
-- Expected: 1 row: S003|Ibrahim|NULL
UPDATE STUDENT SET HOME_STATE = NULL WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE IS NULL;

-- Check 164
-- Expected: 3 rows: S001|Nguyen|OH, S002|Carter|PA, S004|Park|OH
UPDATE STUDENT SET HOME_STATE = NULL WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE IS NOT NULL
ORDER BY STUDENT_ID;

-- Check 165
-- Expected: 1 row: S002|Carter|PA (S003 is excluded because its home state is unknown)
UPDATE STUDENT SET HOME_STATE = NULL WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE <> 'OH';

-- Check 166
-- Expected: 3 rows: P200|101|610|5490, P200|201|725|6525, P200|202|NULL|NULL (ROOM_NUM is CHAR(3), so the literal '202' is correctly quoted)
UPDATE ROOM SET MONTHLY_RENT = NULL WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT, MONTHLY_RENT * 9 AS NINE_MONTH_TOTAL
FROM ROOM
WHERE PROPERTY_ID = 'P200'
ORDER BY ROOM_NUM;

-- Check 167
-- Expected: 1 row, 1 column, value is null (legal with no FROM clause in both SQLite and MySQL)
SELECT 595.00 + NULL AS RENT_PLUS_UNKNOWN;

-- Check 168
-- Expected: 1 row: 3
UPDATE ROOM SET MONTHLY_RENT = NULL WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

SELECT COUNT(*) AS ROOMS_OVER_500
FROM ROOM
WHERE MONTHLY_RENT > 500.00;

-- Check 169
-- Expected: 1 row: 1 (3 + 1 = 4, while ROOM holds 5 rows)
UPDATE ROOM SET MONTHLY_RENT = NULL WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

SELECT COUNT(*) AS ROOMS_500_OR_LESS
FROM ROOM
WHERE MONTHLY_RENT <= 500.00;

-- Check 170
-- Expected: 1 row: 5 | 4 | 2380 | 595 (2380/5 would be 476, a 119 difference)
UPDATE ROOM SET MONTHLY_RENT = NULL WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

SELECT COUNT(*) AS ALL_ROOMS,
       COUNT(MONTHLY_RENT) AS RENTS_RECORDED,
       SUM(MONTHLY_RENT) AS TOTAL_RENT,
       AVG(MONTHLY_RENT) AS AVERAGE_RENT
FROM ROOM;

-- Check 171
-- Expected: 1 row: P200|202|NULL
UPDATE ROOM SET MONTHLY_RENT = NULL WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT IS NULL;

-- Check 172
-- Expected: 5 rows, null first: 202|NULL, 102|450, 101|595, 101|610, 201|725. MySQL orders nulls first in ascending order too
UPDATE ROOM SET MONTHLY_RENT = NULL WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

SELECT ROOM_NUM, MONTHLY_RENT
FROM ROOM
ORDER BY MONTHLY_RENT;

-- Check 173
-- Expected: 1 row: Habitat|2|46.37 (all 5 items pass ON_HAND > 10; the average is exactly 46.37, with no floating-point tail)
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVERAGE_PRICE
FROM ITEM
WHERE ON_HAND > 10
GROUP BY CATEGORY
HAVING COUNT(*) > 1
ORDER BY CATEGORY;

-- Check 174
-- Expected: 4 rows: Accessory|1|11.99, Food|1|42.5, Grooming|1|15.25, Habitat|2|46.37
SELECT CATEGORY, COUNT(*) AS ITEM_COUNT, AVG(PRICE) AS AVERAGE_PRICE
FROM ITEM
WHERE ON_HAND > 10
GROUP BY CATEGORY
ORDER BY CATEGORY;

-- Check 175  !! INTENTIONALLY INVALID -- expected to error
-- Expected: Error in both engines; SQLite reports 'misuse of aggregate: COUNT()'. This is the WHERE-runs-before-grouping rule the lesson states
SELECT CATEGORY FROM ITEM WHERE COUNT(*) > 1 GROUP BY CATEGORY;

-- Check 176
-- Expected: 2 rows in this page's SQLite engine: AV07|129.98, CF21|85. MySQL rejects the same statement with "Unknown column 'DOUBLED' in 'where clause'" - the portability difference called out in 4-7
SELECT ITEM_ID, PRICE * 2 AS DOUBLED FROM ITEM WHERE DOUBLED > 60;

-- Check 177
-- Expected: 1 row: 11.99 | 64.99 | 235 | 5
SELECT MIN(PRICE), MAX(PRICE), SUM(ON_HAND), COUNT(*) FROM ITEM;

-- Check 178
-- Expected: 1 row: CF21
SELECT ITEM_ID FROM ITEM WHERE CATEGORY = 'Food';

-- Check 179
-- Expected: 4 rows: AV07, DG04, FT88, GR15
SELECT ITEM_ID FROM ITEM WHERE CATEGORY <> 'Food';

-- Check 180
-- Expected: 1 row: AV07
SELECT ITEM_ID FROM ITEM WHERE ON_HAND < 20;

-- Check 181
-- Expected: 2 rows: AV07, CF21
SELECT ITEM_ID FROM ITEM WHERE PRICE >= 42.50;

-- Check 182
-- Expected: 1 row: FT88
SELECT ITEM_ID FROM ITEM WHERE CATEGORY = 'Habitat' AND PRICE < 50.00;

-- Check 183
-- Expected: 2 rows: CF21, GR15
SELECT ITEM_ID FROM ITEM WHERE CATEGORY = 'Food' OR CATEGORY = 'Grooming';

-- Check 184
-- Expected: 3 rows: CF21, DG04, GR15
SELECT ITEM_ID FROM ITEM WHERE NOT CATEGORY = 'Habitat';

-- Check 185
-- Expected: 3 rows: CF21|42.5, FT88|27.75, GR15|15.25. No ORDER BY, so the row order is the engine's choice
SELECT ITEM_ID, PRICE FROM ITEM WHERE PRICE BETWEEN 15.00 AND 45.00;

-- Check 186
-- Expected: 1 row: 1310|Companion Care Clinic
SELECT CUSTOMER_NUM, CUSTOMER_NAME FROM CUSTOMER WHERE CUSTOMER_NAME LIKE 'Comp%';

-- Check 187
-- Expected: 1 row: 1310 in this page's SQLite engine, which ignores ASCII case in LIKE. In MySQL the result depends on the column's collation, which is why the lesson tells students to control the case themselves
SELECT CUSTOMER_NUM FROM CUSTOMER WHERE CUSTOMER_NAME LIKE 'comp%';

-- Check 188
-- Expected: 3 rows: 1120|Access Pet Center, 1310|Companion Care Clinic, 1420|Whiskers & Wags Boutique
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE REP_NUM IN ('20', '65')
ORDER BY CUSTOMER_NUM;

-- Check 189
-- Expected: 1 row: 0
SELECT COUNT(*) FROM ITEM WHERE PRICE IS NULL;

-- ----------------------------------------------------------------------
-- Group 4-end  --  30 checks
-- ----------------------------------------------------------------------

-- Check 190
-- Expected: Verified in SQLite. 3 rows in this order: Habitat|2, Food|1, Grooming|1. Accessory is absent because DG04 at 11.99 fails the WHERE test; the HAVING drops nothing.
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS
FROM ITEM
WHERE PRICE > 12
GROUP BY CATEGORY
HAVING COUNT(*) >= 1
ORDER BY NUM_ITEMS DESC, CATEGORY;

-- Check 191
-- Expected: Verified in SQLite. 1 row: Habitat|2|46.37. (46.37 is exactly representable enough to display cleanly here; MySQL would show 46.370000.)
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS, AVG(PRICE) AS AVG_PRICE
FROM ITEM
WHERE PRICE BETWEEN 10 AND 70
GROUP BY CATEGORY
HAVING COUNT(*) > 1
ORDER BY AVG_PRICE DESC;

-- Check 192
-- Expected: Verified in SQLite. 4 rows in this order: Habitat|2|46.37, Food|1|42.5, Grooming|1|15.25, Accessory|1|11.99.
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS, AVG(PRICE) AS AVG_PRICE
FROM ITEM
WHERE PRICE BETWEEN 10 AND 70
GROUP BY CATEGORY
HAVING COUNT(*) >= 1
ORDER BY AVG_PRICE DESC;

-- Check 193
-- Expected: Verified in SQLite. 4 rows in this order: Accessory, Food, Grooming, Habitat.
SELECT DISTINCT CATEGORY
FROM ITEM
ORDER BY CATEGORY;

-- Check 194
-- Expected: Verified in SQLite. 4 rows: Accessory|1, Food|1, Grooming|1, Habitat|2.
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS
FROM ITEM
GROUP BY CATEGORY
ORDER BY CATEGORY;

-- Check 195
-- Expected: Verified in SQLite. All 5 ITEM rows: AV07|Aviary Starter Cage|Habitat|15|64.99|5, CF21|Grain-Free Dry Food 30lb|Food|48|42.5|15, DG04|Nylon Dog Leash 6ft|Accessory|120|11.99|25, FT88|Fish Tank Filter Kit|Habitat|30|27.75|10, GR15|Small Animal Grooming Kit|Grooming|22|15.25|8.
-- Paste a statement from a review question here, then run it.
SELECT * FROM ITEM;

-- Check 196
-- Expected: Verified in SQLite. 5 rows in this order: AV07|64.99, CF21|42.5, FT88|27.75, GR15|15.25, DG04|11.99.
-- Both databases are loaded. Exercise 1 starter:
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
ORDER BY PRICE DESC;

-- Check 197
-- Expected: Verified in SQLite. 3 rows: CF21|Grain-Free Dry Food 30lb|42.5, FT88|Fish Tank Filter Kit|27.75, GR15|Small Animal Grooming Kit|15.25.
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE BETWEEN 15 AND 50
ORDER BY PRICE DESC;

-- Check 198
-- Expected: Verified in SQLite. 3 rows in this order: Access Pet Center, Companion Care Clinic, Whiskers & Wags Boutique. Downtown Aquarium & Pets is excluded. Identical under MySQL.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE CITY = 'Maple Grove' OR CITY = 'Brookville' AND BALANCE > 4000;

-- Check 199
-- Expected: Verified in SQLite. 3 rows: AV07 (15 on hand), FT88 (30), GR15 (22).
SELECT ITEM_ID FROM ITEM WHERE ON_HAND BETWEEN 15 AND 30;

-- Check 200
-- Expected: Verified in SQLite. 2 rows: Access Pet Center and Downtown Aquarium & Pets. Same under MySQL's default case-insensitive collation; '%pet%' also returns the same 2 rows in both engines.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE CUSTOMER_NAME LIKE '%Pet%';

-- Check 201
-- Expected: Engine difference, stated as such in the question. MySQL raises 'Subquery returns more than 1 row'. SQLite does not error: it compares against a single value taken from the multi-row subquery (rep 20 when verified) and returned 2 rows, Access Pet Center and Companion Care Clinic. Which value SQLite picks is not guaranteed, which is the point of the question.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE REP_NUM = (SELECT REP_NUM FROM REP WHERE CITY = 'Maple Grove');

-- Check 202
-- Expected: Verified in SQLite. 3 rows in this order: Access Pet Center, Downtown Aquarium & Pets, Companion Care Clinic (reps 20 and 35). Identical under MySQL.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE REP_NUM IN (SELECT REP_NUM FROM REP WHERE CITY = 'Maple Grove');

-- Check 203
-- Expected: Verified in SQLite. 2 rows: CF21|2040 and DG04|1438.8 (the arithmetic values are 2040.00 and 1438.80; SQLite drops the trailing zeros because the result is a REAL). MySQL displays 2040.00 and 1438.80.
SELECT ITEM_ID, ON_HAND * PRICE AS INVENTORY_VALUE FROM ITEM WHERE ON_HAND * PRICE > 1000;

-- Check 204
-- Expected: Engine difference backing the Q5 takeaway, verified: SQLite accepts a SELECT alias in WHERE and returns the same 2 rows (CF21|2040, DG04|1438.8). MySQL rejects it with "Unknown column 'INVENTORY_VALUE' in 'where clause'". This statement is only cited as a portability warning, never given as a model answer.
SELECT ITEM_ID, ON_HAND * PRICE AS INVENTORY_VALUE FROM ITEM WHERE INVENTORY_VALUE > 1000;

-- Check 205
-- Expected: Verified in SQLite. 3 rows: Brookville|1, Maple Grove|1, Northfield|1. Maple Grove is 1 because the 0.00 balance row is removed before grouping.
SELECT CITY, COUNT(*) AS NUM_CUSTOMERS FROM CUSTOMER WHERE BALANCE > 0 GROUP BY CITY ORDER BY CITY;

-- Check 206
-- Expected: Verified in SQLite. 1 row: 20|2. This also answers Exercise 5.
SELECT REP_NUM, COUNT(*) AS NUM_CUSTOMERS FROM CUSTOMER GROUP BY REP_NUM HAVING COUNT(*) > 1;

-- Check 207
-- Expected: Verified in SQLite. 5 rows in this order: P100|101|595, P100|102|450, P200|201|725, P200|101|610, P200|202|465. (MySQL shows the rents as 595.00, 450.00, 725.00, 610.00, 465.00 because the column is DECIMAL.)
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT FROM ROOM ORDER BY PROPERTY_ID, MONTHLY_RENT DESC;

-- Check 208
-- Expected: Verified in SQLite. 1 row: 5|4.
SELECT COUNT(*) AS NUM_ROWS, COUNT(DISTINCT CATEGORY) AS NUM_CATEGORIES FROM ITEM;

-- Check 209
-- Expected: Verified in SQLite. 2 rows: AV07|64.99 and CF21|42.5. The comparison value is the average, 32.496.
SELECT ITEM_ID, PRICE FROM ITEM WHERE PRICE > (SELECT AVG(PRICE) FROM ITEM);

-- Check 210
-- Expected: Verified in SQLite. 1 row, displayed as 32.495999999999995 in the browser sandbox. The exact average is 32.496 (162.48 / 5); the trailing digits are the binary floating-point representation SQLite uses, and MySQL's DECIMAL arithmetic shows 32.496000. The module summary callout says this explicitly.
SELECT AVG(PRICE) FROM ITEM;

-- Check 211
-- Expected: Verified in SQLite. 1 row: Access Pet Center.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE BALANCE > 1000 AND CITY = 'Maple Grove';

-- Check 212
-- Expected: Verified in SQLite. 5 rows: Aviary Starter Cage|974.8499999999999, Grain-Free Dry Food 30lb|2040, Nylon Dog Leash 6ft|1438.8, Fish Tank Filter Kit|832.5, Small Animal Grooming Kit|335.5. The exact products are 974.85, 2040.00, 1438.80, 832.50, 335.50; the first row is the floating-point display the summary callout warns about. MySQL shows all five exactly.
SELECT DESCRIPTION, ON_HAND * PRICE AS VALUE_ON_HAND FROM ITEM;

-- Check 213
-- Expected: Verified in SQLite. 1 row: 5621.65 (displays cleanly in the sandbox, so the quiz stem quoting 5621.65 is safe).
SELECT SUM(ON_HAND * PRICE) AS TOTAL_VALUE FROM ITEM;

-- Check 214
-- Expected: Verified in SQLite. Exercise 2 answer: 2 rows, 1120|Access Pet Center and 1225|Downtown Aquarium & Pets.
SELECT CUSTOMER_NUM, CUSTOMER_NAME FROM CUSTOMER WHERE CUSTOMER_NAME LIKE '%Pet%';

-- Check 215
-- Expected: Verified in SQLite. Exercise 3 answer: 1 row, 4|9533.25 (displays exactly in both engines).
SELECT COUNT(*) AS NUM_CUSTOMERS, SUM(BALANCE) AS TOTAL_BALANCE FROM CUSTOMER;

-- Check 216
-- Expected: Verified in SQLite. Exercise 4 answer: 2 rows, AV07|Aviary Starter Cage|64.99 then CF21|Grain-Free Dry Food 30lb|42.5.
SELECT ITEM_ID, DESCRIPTION, PRICE FROM ITEM WHERE PRICE > (SELECT AVG(PRICE) FROM ITEM) ORDER BY PRICE DESC;

-- Check 217
-- Expected: Verified in SQLite. Exercise 6 answer: 3 rows, Double|450|465, Single|595|610, Studio|725|725.
SELECT ROOM_TYPE, MIN(MONTHLY_RENT) AS LOWEST, MAX(MONTHLY_RENT) AS HIGHEST FROM ROOM GROUP BY ROOM_TYPE ORDER BY ROOM_TYPE;

-- Check 218
-- Expected: Verified in SQLite. Exercise 7 answer: 1 row, P200|3|600 (the average of 610, 725 and 465 is exactly 600, so no floating-point tail appears; MySQL shows 600.000000).
SELECT PROPERTY_ID, COUNT(*) AS NUM_ROOMS, AVG(MONTHLY_RENT) AS AVG_RENT FROM ROOM GROUP BY PROPERTY_ID HAVING COUNT(*) > 2;

-- Check 219
-- Expected: Verified in SQLite. Exercise 8 answer: 3 rows, Layla|Ibrahim|MI, Trang|Nguyen|OH, Jason|Park|OH. Column names confirmed against the shipped STUDENT schema (STUDENT_ID, LAST_NAME, FIRST_NAME, EMAIL, HOME_STATE).
SELECT FIRST_NAME, LAST_NAME, HOME_STATE FROM STUDENT WHERE HOME_STATE IN ('OH','MI') ORDER BY LAST_NAME;
