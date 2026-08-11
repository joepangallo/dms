-- ======================================================================
-- Module 5 · Verification queries and expected results
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
-- Group m5a  --  29 checks
-- ----------------------------------------------------------------------


-- Check 1
-- Expected: 4 rows, in CUSTOMER_NUM order (guaranteed by the ORDER BY): 1120 Access Pet Center Kaiser Valerie | 1225 Downtown Aquarium & Pets Hull Richard | 1310 Companion Care Clinic Kaiser Valerie | 1420 Whiskers & Wags Boutique Perez Juan
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME, REP.FIRST_NAME
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 2
-- Expected: 4 rows, 2 columns, in CUSTOMER_NUM order: 1120 Access Pet Center | 1225 Downtown Aquarium & Pets | 1310 Companion Care Clinic | 1420 Whiskers & Wags Boutique. The 5-1a sandbox starter.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 3
-- Expected: EXPECTED FAILURE - this statement must NOT be placed in a sandbox block. SQLite raises 'ambiguous column name: REP_NUM' at prepare time and returns no rows. It is quoted only inside a warning callout and a quiz stem as the mistake to avoid. A passing check here means the error was raised, not that rows came back.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT REP_NUM
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM;

-- Check 4
-- Expected: 2 rows: 1120 Access Pet Center Kaiser | 1310 Companion Care Clinic Kaiser
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
  AND CUSTOMER.CREDIT_LIMIT >= 7500
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 5
-- Expected: 4 rows: 1120 Access Pet Center Kaiser | 1225 Downtown Aquarium & Pets Hull | 1310 Companion Care Clinic Kaiser | 1420 Whiskers & Wags Boutique Perez. The 5-1b sandbox starter.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 6
-- Expected: 12 rows - every customer paired with every rep, 4 x 3. Quoted in the m5-1 quiz stem 'The twelve-row surprise'. Order is not guaranteed.
SELECT CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
FROM CUSTOMER, REP;

-- Check 7
-- Expected: 1 row, 1 column: COMBINATIONS = 12
SELECT COUNT(*) AS COMBINATIONS
FROM CUSTOMER, REP;

-- Check 8
-- Expected: 3 rows: Hull 1 1200 | Kaiser 2 3512.5 | Perez 1 4820.75. Kaiser's total is 3512.50 + 0.00; customer 1310 is counted but adds nothing.
SELECT REP.LAST_NAME, COUNT(*) AS NUM_CUSTOMERS, SUM(CUSTOMER.BALANCE) AS TOTAL_BALANCE
FROM REP, CUSTOMER
WHERE REP.REP_NUM = CUSTOMER.REP_NUM
GROUP BY REP.LAST_NAME
ORDER BY REP.LAST_NAME;

-- Check 9
-- Expected: 4 rows: Hull Downtown Aquarium & Pets 1200 | Kaiser Access Pet Center 3512.5 | Kaiser Companion Care Clinic 0 | Perez Whiskers & Wags Boutique 4820.75
SELECT REP.LAST_NAME, CUSTOMER.CUSTOMER_NAME, CUSTOMER.BALANCE
FROM REP, CUSTOMER
WHERE REP.REP_NUM = CUSTOMER.REP_NUM
ORDER BY REP.LAST_NAME, CUSTOMER.CUSTOMER_NAME;

-- Check 10
-- Expected: 3 rows: 1120 Access Pet Center Maple Grove | 1310 Companion Care Clinic Maple Grove | 1420 Whiskers & Wags Boutique Brookville
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE CITY IN ('Maple Grove', 'Brookville')
ORDER BY CUSTOMER_NUM;

-- Check 11
-- Expected: 3 rows: 1120 Access Pet Center | 1225 Downtown Aquarium & Pets | 1420 Whiskers & Wags Boutique. Customer 1310 is absent because it has no invoice.
SELECT DISTINCT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME
FROM CUSTOMER, INVOICE
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 12
-- Expected: 3 rows, identical to the DISTINCT join above: 1120 Access Pet Center | 1225 Downtown Aquarium & Pets | 1420 Whiskers & Wags Boutique
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
ORDER BY CUSTOMER_NUM;

-- Check 13
-- Expected: 6 rows for 5 items: AV07 50712 | CF21 50710 | CF21 50711 | DG04 50710 | FT88 50712 | GR15 50711. CF21 appears twice. The second ORDER BY key pins the order of the two CF21 rows.
SELECT ITEM.ITEM_ID, ITEM.DESCRIPTION, INVOICE_LINE.INVOICE_NUM
FROM ITEM, INVOICE_LINE
WHERE ITEM.ITEM_ID = INVOICE_LINE.ITEM_ID
ORDER BY ITEM.ITEM_ID, INVOICE_LINE.INVOICE_NUM;

-- Check 14
-- Expected: 2 rows: CF21 Grain-Free Dry Food 30lb 42.5 | DG04 Nylon Dog Leash 6ft 11.99. Second statement of the 5-2a sandbox solution.
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE ITEM_ID IN
    (SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710')
ORDER BY ITEM_ID;

-- Check 15
-- Expected: 2 rows, 1 column, order not guaranteed: the set {CF21, DG04}. Quoted in the 5-2a sandbox hint as the inner query run on its own.
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710';

-- Check 16
-- Expected: 3 rows: 1120 Access Pet Center | 1225 Downtown Aquarium & Pets | 1420 Whiskers & Wags Boutique. Also the 5-2b sandbox starter.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE EXISTS
    (SELECT *
     FROM INVOICE
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)
ORDER BY CUSTOMER_NUM;

-- Check 17
-- Expected: All 4 rows including 1310 Companion Care Clinic, order not guaranteed - the uncorrelated-EXISTS mistake quoted in the warning callout and in m5-2 quiz question 2.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE EXISTS (SELECT * FROM INVOICE);

-- Check 18
-- Expected: Same 3 rows as the SELECT * version: 1120 | 1225 | 1420. Backs the claim that the inner column list is ignored.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE EXISTS
    (SELECT 1
     FROM INVOICE
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)
ORDER BY CUSTOMER_NUM;

-- Check 19
-- Expected: 1 row: 1310 Companion Care Clinic
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE NOT EXISTS
    (SELECT *
     FROM INVOICE
     WHERE INVOICE.CUSTOMER_NUM = CUSTOMER.CUSTOMER_NUM)
ORDER BY CUSTOMER_NUM;

-- Check 20
-- Expected: 2 rows, 1 column, order not guaranteed: the set {50710, 50711}. Innermost layer, and the 5-2c sandbox starter.
SELECT INVOICE_NUM
FROM INVOICE_LINE
WHERE ITEM_ID = 'CF21';

-- Check 21
-- Expected: 2 rows, 1 column, order not guaranteed: the set {1120, 1420}. The middle layer of 5-2c with the inner result substituted.
SELECT CUSTOMER_NUM
FROM INVOICE
WHERE INVOICE_NUM IN ('50710', '50711');

-- Check 22
-- Expected: 2 rows: 1120 Access Pet Center | 1420 Whiskers & Wags Boutique
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN
    (SELECT CUSTOMER_NUM
     FROM INVOICE
     WHERE INVOICE_NUM IN
         (SELECT INVOICE_NUM
          FROM INVOICE_LINE
          WHERE ITEM_ID = 'CF21'))
ORDER BY CUSTOMER_NUM;

-- Check 23
-- Expected: 6 rows: 50710 Grain-Free Dry Food 30lb 3 | 50710 Nylon Dog Leash 6ft 2 | 50711 Grain-Free Dry Food 30lb 2 | 50711 Small Animal Grooming Kit 1 | 50712 Aviary Starter Cage 1 | 50712 Fish Tank Filter Kit 2. Also the 5-2d sandbox starter.
SELECT INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED
FROM INVOICE_LINE, ITEM
WHERE INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
ORDER BY INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Check 24
-- Expected: 6 rows, 5 columns: Access Pet Center 50710 2026-06-14 x2, then Whiskers & Wags Boutique 50711 2026-06-14 x2, then Downtown Aquarium & Pets 50712 2026-06-15 x2
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM, INVOICE.INVOICE_DATE,
       ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED
FROM CUSTOMER, INVOICE, INVOICE_LINE, ITEM
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM
  AND INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Check 25
-- Expected: 6 rows with LINE_TOTAL in this order: 127.5 | 23.98 | 85.0 | 15.25 | 64.99 | 55.5
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM, ITEM.DESCRIPTION,
       INVOICE_LINE.NUM_ORDERED * INVOICE_LINE.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER, INVOICE, INVOICE_LINE, ITEM
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM
  AND INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Check 26
-- Expected: 4 rows: Access Pet Center 50710 Grain-Free Dry Food 30lb 127.5 | Access Pet Center 50710 Nylon Dog Leash 6ft 23.98 | Downtown Aquarium & Pets 50712 Aviary Starter Cage 64.99 | Downtown Aquarium & Pets 50712 Fish Tank Filter Kit 55.5. Customer 1225 is in Northfield but its rep (35, Hull) is in Maple Grove; invoice 50711 drops out because customer 1420's rep (65, Perez) is in Brookville.
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM, ITEM.DESCRIPTION,
       INVOICE_LINE.NUM_ORDERED * INVOICE_LINE.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER, INVOICE, INVOICE_LINE, ITEM
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM
  AND INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
  AND CUSTOMER.REP_NUM IN
      (SELECT REP_NUM FROM REP WHERE CITY = 'Maple Grove')
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Check 27
-- Expected: 2 rows, 1 column, order not guaranteed: the set {20, 35}. The stage-4 subquery run on its own.
SELECT REP_NUM FROM REP WHERE CITY = 'Maple Grove';

-- Check 28
-- Expected: 3 rows: Access Pet Center 50710 151.48 | Whiskers & Wags Boutique 50711 100.25 | Downtown Aquarium & Pets 50712 120.49
SELECT CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM,
       SUM(INVOICE_LINE.NUM_ORDERED * INVOICE_LINE.QUOTED_PRICE) AS INVOICE_TOTAL
FROM CUSTOMER, INVOICE, INVOICE_LINE
WHERE CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
  AND INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM
GROUP BY CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
ORDER BY INVOICE.INVOICE_NUM;

-- Check 29
-- Expected: 0 rows - every one of the five shipped items appears on at least one invoice line. Backs the matcher card 'Report every item that has never been ordered', which is correctly a NOT EXISTS shape with an empty answer on this data.
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
WHERE NOT EXISTS
    (SELECT *
     FROM INVOICE_LINE
     WHERE INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID);

-- ----------------------------------------------------------------------
-- Group m5b  --  15 checks
-- ----------------------------------------------------------------------


-- Check 30
-- Expected: 1 row: Whiskers & Wags Boutique
SELECT C.CUSTOMER_NAME
FROM CUSTOMER AS C
WHERE C.REP_NUM = '65';

-- Check 31
-- Expected: 4 rows: 1120 Access Pet Center Kaiser 0.05; 1225 Downtown Aquarium & Pets Hull 0.07; 1310 Companion Care Clinic Kaiser 0.05; 1420 Whiskers & Wags Boutique Perez 0.05
SELECT C.CUSTOMER_NUM, C.CUSTOMER_NAME, R.LAST_NAME, R.RATE
FROM CUSTOMER C, REP R
WHERE C.REP_NUM = R.REP_NUM
ORDER BY C.CUSTOMER_NUM;

-- Check 32
-- Expected: ERROR (expected). Verified message: no such column: CUSTOMER.CUSTOMER_NUM. Appears in the 5-2e plain code block only, never in a sandbox block; MySQL and Oracle raise their own unknown-table equivalent.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER.CUSTOMER_NUM
FROM CUSTOMER C, REP R
WHERE C.REP_NUM = R.REP_NUM;

-- Check 33
-- Expected: 6 rows: 1120/1120/20, 1120/1310/20, 1225/1225/35, 1310/1120/20, 1310/1310/20, 1420/1420/65 (matches the section table row for row)
SELECT A.CUSTOMER_NUM, B.CUSTOMER_NUM, A.REP_NUM
FROM CUSTOMER A, CUSTOMER B
WHERE A.REP_NUM = B.REP_NUM
ORDER BY A.CUSTOMER_NUM, B.CUSTOMER_NUM;

-- Check 34
-- Expected: ERROR (expected). Verified message: ambiguous column name: CUSTOMER_NUM. Appears in the 5-2f plain code block that explains why self-joins must qualify every column; never in a sandbox block.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NUM
FROM CUSTOMER A, CUSTOMER B
WHERE A.REP_NUM = B.REP_NUM;

-- Check 35
-- Expected: 2 rows: 1120/1310 and 1310/1120 (self-pairs removed, mirrors kept) - backs the twocol card and quiz question 3
SELECT A.CUSTOMER_NUM, B.CUSTOMER_NUM
FROM CUSTOMER A, CUSTOMER B
WHERE A.REP_NUM = B.REP_NUM
AND A.CUSTOMER_NUM <> B.CUSTOMER_NUM;

-- Check 36
-- Expected: 1 row: 1120 Access Pet Center | 1310 Companion Care Clinic
SELECT A.CUSTOMER_NUM, A.CUSTOMER_NAME, B.CUSTOMER_NUM, B.CUSTOMER_NAME
FROM CUSTOMER A, CUSTOMER B
WHERE A.REP_NUM = B.REP_NUM
AND A.CUSTOMER_NUM < B.CUSTOMER_NUM;

-- Check 37
-- Expected: 1 row: 1310/1120 - backs the prose claim that swapping < for > returns the same pair in the other order
SELECT A.CUSTOMER_NUM, B.CUSTOMER_NUM
FROM CUSTOMER A, CUSTOMER B
WHERE A.REP_NUM = B.REP_NUM
AND A.CUSTOMER_NUM > B.CUSTOMER_NUM;

-- Check 38
-- Expected: 1 row: AV07 | FT88 | Habitat
SELECT A.ITEM_ID, B.ITEM_ID, A.CATEGORY
FROM ITEM A, ITEM B
WHERE A.CATEGORY = B.CATEGORY
AND A.ITEM_ID < B.ITEM_ID;

-- Check 39
-- Expected: 1 row: Kaiser | Access Pet Center | Companion Care Clinic
SELECT R.LAST_NAME, A.CUSTOMER_NAME, B.CUSTOMER_NAME
FROM CUSTOMER A, CUSTOMER B, REP R
WHERE A.REP_NUM = B.REP_NUM
AND A.REP_NUM = R.REP_NUM
AND A.CUSTOMER_NUM < B.CUSTOMER_NUM;

-- Check 40
-- Expected: 6 rows: 50710 Access Pet Center Grain-Free Dry Food 30lb 3; 50710 Access Pet Center Nylon Dog Leash 6ft 2; 50711 Whiskers & Wags Boutique Grain-Free Dry Food 30lb 2; 50711 Whiskers & Wags Boutique Small Animal Grooming Kit 1; 50712 Downtown Aquarium & Pets Aviary Starter Cage 1; 50712 Downtown Aquarium & Pets Fish Tank Filter Kit 2 (Companion Care Clinic absent, as the prose says)
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION, IL.NUM_ORDERED
FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND I.INVOICE_NUM = IL.INVOICE_NUM
AND IL.ITEM_ID = IT.ITEM_ID
ORDER BY I.INVOICE_NUM, IT.ITEM_ID;

-- Check 41
-- Expected: 1 row: 18 (backs the warning callout and quiz question 4 about the deleted INVOICE to INVOICE_LINE condition)
SELECT COUNT(*)
FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND IL.ITEM_ID = IT.ITEM_ID;

-- Check 42
-- Expected: 2 rows: 50712 Downtown Aquarium & Pets Aviary Starter Cage; 50712 Downtown Aquarium & Pets Fish Tank Filter Kit (backs the filter sandbox and the matcher card IT.CATEGORY = 'Habitat')
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION
FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND I.INVOICE_NUM = IL.INVOICE_NUM
AND IL.ITEM_ID = IT.ITEM_ID
AND IT.CATEGORY = 'Habitat'
ORDER BY IT.ITEM_ID;

-- Check 43
-- Expected: 6 rows: Hull/Downtown Aquarium & Pets/Aviary Starter Cage/64.99; Hull/Downtown Aquarium & Pets/Fish Tank Filter Kit/55.5; Kaiser/Access Pet Center/Grain-Free Dry Food 30lb/127.5; Kaiser/Access Pet Center/Nylon Dog Leash 6ft/23.98; Perez/Whiskers & Wags Boutique/Grain-Free Dry Food 30lb/85.0; Perez/Whiskers & Wags Boutique/Small Animal Grooming Kit/15.25
SELECT R.LAST_NAME, C.CUSTOMER_NAME, IT.DESCRIPTION,
       IL.NUM_ORDERED * IL.QUOTED_PRICE AS EXTENDED
FROM REP R, CUSTOMER C, INVOICE I, INVOICE_LINE IL, ITEM IT
WHERE R.REP_NUM = C.REP_NUM
AND C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND I.INVOICE_NUM = IL.INVOICE_NUM
AND IL.ITEM_ID = IT.ITEM_ID
ORDER BY R.LAST_NAME, IT.DESCRIPTION;

-- Check 44
-- Expected: 3 rows: 50710 Access Pet Center 151.48; 50711 Whiskers & Wags Boutique 100.25; 50712 Downtown Aquarium & Pets 120.49
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS INVOICE_TOTAL
FROM CUSTOMER C, INVOICE I, INVOICE_LINE IL
WHERE C.CUSTOMER_NUM = I.CUSTOMER_NUM
AND I.INVOICE_NUM = IL.INVOICE_NUM
GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME
ORDER BY I.INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Group m5c  --  47 checks
-- ----------------------------------------------------------------------


-- Check 45
-- Expected: 4 rows: 1120 Access Pet Center; 1225 Downtown Aquarium & Pets; 1310 Companion Care Clinic; 1420 Whiskers & Wags Boutique
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE REP_NUM = '20'
UNION
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
ORDER BY CUSTOMER_NUM;

-- Check 46
-- Expected: 7 rows in this order: Maple Grove, Northfield, Maple Grove, Brookville, Maple Grove, Maple Grove, Brookville
SELECT CITY FROM CUSTOMER
UNION ALL
SELECT CITY FROM REP;

-- Check 47
-- Expected: 3 rows: Brookville; Maple Grove; Northfield
SELECT CITY FROM CUSTOMER
UNION
SELECT CITY FROM REP
ORDER BY CITY;

-- Check 48
-- Expected: 2 rows under the single heading CUSTOMER_NAME: 'Access Pet Center'; '4820.75'. Verified: SQLite happily stacks a number under a name. Backs the corrected type-compatibility paragraph, which now says MySQL is equally permissive and only Oracle rejects the mismatch (ORA-01790). Not placed in a sandbox.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE CUSTOMER_NUM = '1120'
UNION ALL
SELECT BALANCE FROM CUSTOMER WHERE CUSTOMER_NUM = '1420';

-- Check 49
-- Expected: 4 rows: CF21, DG04, CF21, GR15 (CF21 appears twice)
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710'
UNION ALL
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50711';

-- Check 50
-- Expected: 3 rows: CF21, DG04, GR15
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50710'
UNION
SELECT ITEM_ID FROM INVOICE_LINE WHERE INVOICE_NUM = '50711';

-- Check 51
-- Expected: 1 row: 1120 Access Pet Center
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE REP_NUM = '20'
INTERSECT
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE);

-- Check 52
-- Expected: 1 row: 1310 Companion Care Clinic
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE REP_NUM = '20'
EXCEPT
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE);

-- Check 53
-- Expected: 2 rows: 1225 Downtown Aquarium & Pets; 1420 Whiskers & Wags Boutique (proves EXCEPT is directional)
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
EXCEPT
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE REP_NUM = '20';

-- Check 54
-- Expected: Error, by design. Verified SQLite text: 'SELECTs to the left and right of UNION do not have the same number of result columns'. Shown as a plain code block, never in a sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
UNION
SELECT REP_NUM
FROM REP;

-- Check 55
-- Expected: Error, by design. Verified SQLite text: 'ORDER BY clause should come after UNION not before'. Quoted in a callout, not placed in a sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NUM FROM CUSTOMER ORDER BY CUSTOMER_NUM
UNION
SELECT REP_NUM FROM REP;

-- Check 56
-- Expected: 2 rows under headings ID_NUM and NAME, in this order: 1420 Whiskers & Wags Boutique; 65 Perez. The 1420 row sorts first because both id columns are character data, so '1' precedes '6'. Backs the added sentence about the sort order.
SELECT CUSTOMER_NUM AS ID_NUM, CUSTOMER_NAME AS NAME
FROM CUSTOMER
WHERE CITY = 'Brookville'
UNION
SELECT REP_NUM, LAST_NAME
FROM REP
WHERE CITY = 'Brookville'
ORDER BY ID_NUM;

-- Check 57
-- Expected: Oracle only. Verified to be a syntax error in SQLite ('near "SELECT": syntax error'), which is why the lesson tells students to write EXCEPT in the sandbox. Not placed in a sandbox. Note the corrected callout: MINUS is Oracle's traditional keyword, and Oracle 21c also accepts EXCEPT.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT REP_NUM FROM REP
MINUS
SELECT REP_NUM FROM CUSTOMER;

-- Check 58
-- Expected: 3 rows: S001 Nguyen; S003 Ibrahim; S004 Park
SELECT STUDENT_ID, LAST_NAME FROM STUDENT WHERE HOME_STATE = 'OH'
UNION
SELECT STUDENT_ID, LAST_NAME FROM STUDENT WHERE STUDENT_ID IN (SELECT STUDENT_ID FROM LEASE WHERE PROPERTY_ID = 'P200')
ORDER BY STUDENT_ID;

-- Check 59
-- Expected: 1 row: S004 Park
SELECT STUDENT_ID, LAST_NAME FROM STUDENT WHERE HOME_STATE = 'OH'
INTERSECT
SELECT STUDENT_ID, LAST_NAME FROM STUDENT WHERE STUDENT_ID IN (SELECT STUDENT_ID FROM LEASE WHERE PROPERTY_ID = 'P200');

-- Check 60
-- Expected: 1 row: S001 Nguyen
SELECT STUDENT_ID, LAST_NAME FROM STUDENT WHERE HOME_STATE = 'OH'
EXCEPT
SELECT STUDENT_ID, LAST_NAME FROM STUDENT WHERE STUDENT_ID IN (SELECT STUDENT_ID FROM LEASE WHERE PROPERTY_ID = 'P200');

-- Check 61
-- Expected: MySQL or Oracle only. Returns 1 row: 1420 Whiskers & Wags Boutique 4820.75. Verified SQLite failure text: 'near "ALL": syntax error'. Appears in a plain code block, never a sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > ALL (SELECT BALANCE FROM CUSTOMER WHERE REP_NUM = '20');

-- Check 62
-- Expected: 1 row: 1420 Whiskers & Wags Boutique 4820.75 (runnable equivalent of > ALL)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > (SELECT MAX(BALANCE) FROM CUSTOMER WHERE REP_NUM = '20')
ORDER BY CUSTOMER_NUM;

-- Check 63
-- Expected: MySQL or Oracle only. Returns 3 rows: 1120, 1225, 1420. Verified SQLite failure text is 'near "SELECT": syntax error', NOT 'near "ANY"', because ANY is not a SQLite keyword and is parsed as a column name. The lesson callout now states this distinction. Appears in a plain code block, never a sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > ANY (SELECT BALANCE FROM CUSTOMER WHERE REP_NUM = '20');

-- Check 64
-- Expected: MySQL or Oracle only, where SOME is an exact synonym for ANY and returns 1120, 1225, 1420. Verified SQLite failure text: 'near "SELECT": syntax error', matching ANY. Backs the 'SOME means ANY' callout and the corrected error-message callout. Not placed in a sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NUM FROM CUSTOMER
WHERE BALANCE > SOME (SELECT BALANCE FROM CUSTOMER WHERE REP_NUM = '20');

-- Check 65
-- Expected: 3 rows: 1120 Access Pet Center 3512.50; 1225 Downtown Aquarium & Pets 1200.00; 1420 Whiskers & Wags Boutique 4820.75 (runnable equivalent of > ANY)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE BALANCE > (SELECT MIN(BALANCE) FROM CUSTOMER WHERE REP_NUM = '20')
ORDER BY CUSTOMER_NUM;

-- Check 66
-- Expected: 4 rows: AV07 64.99; CF21 42.50; FT88 27.75; GR15 15.25 (only DG04 at 11.99 is excluded)
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
WHERE PRICE > (SELECT MAX(PRICE) FROM ITEM WHERE CATEGORY = 'Accessory')
ORDER BY ITEM_ID;

-- Check 67
-- Expected: 3 rows: 1120; 1225; 1420 (runnable equivalent of = ANY)
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE)
ORDER BY CUSTOMER_NUM;

-- Check 68
-- Expected: 1 row: 1310 Companion Care Clinic (runnable equivalent of <> ALL). Safe because INVOICE.CUSTOMER_NUM contains no NULLs in the shipped data.
SELECT CUSTOMER_NUM, CUSTOMER_NAME
FROM CUSTOMER
WHERE CUSTOMER_NUM NOT IN (SELECT CUSTOMER_NUM FROM INVOICE)
ORDER BY CUSTOMER_NUM;

-- Check 69
-- Expected: 2 rows: P200 101 Single 610.00; P200 201 Studio 725.00
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT > (SELECT MAX(MONTHLY_RENT) FROM ROOM WHERE PROPERTY_ID = 'P100')
ORDER BY PROPERTY_ID, ROOM_NUM;

-- Check 70
-- Expected: 4 rows: P100 101 595.00; P200 101 610.00; P200 201 725.00; P200 202 465.00. P100 102 at exactly 450.00 is excluded because 450.00 is not greater than 450.00.
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE, MONTHLY_RENT
FROM ROOM
WHERE MONTHLY_RENT > (SELECT MIN(MONTHLY_RENT) FROM ROOM WHERE PROPERTY_ID = 'P100')
ORDER BY PROPERTY_ID, ROOM_NUM;

-- Check 71
-- Expected: 0 rows. Confirms the corrected empty-subquery caveat: MAX over zero rows is NULL, so the comparison is unknown and nothing returns, whereas > ALL over an empty subquery would return every row. The MIN rewrite also returns 0 rows, which is why it still agrees with > ANY.
SELECT ITEM_ID FROM ITEM WHERE PRICE > (SELECT MAX(PRICE) FROM ITEM WHERE CATEGORY = 'Toy');

-- Check 72
-- Expected: 4 rows: 1120 Kaiser; 1225 Hull; 1310 Kaiser; 1420 Perez
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
FROM CUSTOMER INNER JOIN REP ON CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 73
-- Expected: 6 rows: 50710 Grain-Free Dry Food 30lb 3; 50710 Nylon Dog Leash 6ft 2; 50711 Grain-Free Dry Food 30lb 2; 50711 Small Animal Grooming Kit 1; 50712 Aviary Starter Cage 1; 50712 Fish Tank Filter Kit 2
SELECT INVOICE.INVOICE_NUM, ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED
FROM INVOICE INNER JOIN INVOICE_LINE ON INVOICE.INVOICE_NUM = INVOICE_LINE.INVOICE_NUM
INNER JOIN ITEM ON INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
ORDER BY INVOICE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Check 74
-- Expected: 6 rows, same content as the INNER JOIN chain. Backs the rewritten matcher card, which now names the comma-plus-WHERE form so the card can only be an inner join; the previous wording ('six rows, nothing unmatched shown') also described ITEM LEFT JOIN INVOICE_LINE and fit two zones.
SELECT INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION, INVOICE_LINE.NUM_ORDERED
FROM INVOICE_LINE, ITEM
WHERE INVOICE_LINE.ITEM_ID = ITEM.ITEM_ID
ORDER BY INVOICE_LINE.INVOICE_NUM, ITEM.DESCRIPTION;

-- Check 75
-- Expected: 3 rows: 1120 50710; 1225 50712; 1420 50711. Customer 1310 is absent.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER INNER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 76
-- Expected: 4 rows: 1120 50710; 1225 50712; 1310 with NULL INVOICE_NUM; 1420 50711
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER LEFT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 77
-- Expected: Same 4 rows as the LEFT JOIN, including 1310 with NULL INVOICE_NUM. Confirms the mirror-image claim. Needs SQLite 3.39+; the sandbox is 3.45.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM INVOICE RIGHT JOIN CUSTOMER ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 78
-- Expected: 4 rows, identical to the LEFT JOIN, because no invoice is unmatched in the shipped data. This is exactly what the lesson text claims. MySQL has no FULL OUTER JOIN; Oracle and SQLite 3.39+ do.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER FULL OUTER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 79
-- Expected: 5 rows: NULL customer with invoice 50713; 1120 50710; 1225 50712; 1310 with NULL invoice; 1420 50711. The orphan INSERT succeeds because SQLite leaves foreign key enforcement off by default. The leading DELETE is required: without it a second run of the box fails with 'UNIQUE constraint failed: INVOICE.INVOICE_NUM', which the original starter did. Verified to produce identical output on two consecutive runs. Reset restores the seed.
DELETE FROM INVOICE WHERE INVOICE_NUM = '50713';

INSERT INTO INVOICE (INVOICE_NUM, CUSTOMER_NUM, INVOICE_DATE)
VALUES ('50713', '9999', '2026-06-16');

SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER FULL OUTER JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM, INVOICE.INVOICE_NUM;

-- Check 80
-- Expected: The MySQL emulation of FULL OUTER JOIN exactly as the twocol block describes it: LEFT JOIN UNION RIGHT JOIN. With the orphan invoice 50713 present it returns the same 5 rows as the FULL OUTER JOIN above. The previous version of this check used LEFT JOIN twice with the table order flipped, which is equivalent but did not validate the sentence students read.
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER LEFT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
UNION
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, INVOICE.INVOICE_NUM
FROM CUSTOMER RIGHT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM, INVOICE.INVOICE_NUM;

-- Check 81
-- Expected: 1 row: 1310 Companion Care Clinic
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME
FROM CUSTOMER LEFT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
WHERE INVOICE.INVOICE_NUM IS NULL;

-- Check 82
-- Expected: 1 row: 0. Backs the added sentence that '= NULL' never matches anything and IS NULL is the only test that works. Not placed in a sandbox.
SELECT COUNT(*) AS ROW_COUNT
FROM CUSTOMER LEFT JOIN INVOICE ON CUSTOMER.CUSTOMER_NUM = INVOICE.CUSTOMER_NUM
WHERE INVOICE.INVOICE_NUM = NULL;

-- Check 83
-- Expected: 6 rows with no NULL anywhere: AV07 50712; CF21 50710; CF21 50711; DG04 50710; FT88 50712; GR15 50711. Backs the 'an outer join does not always add NULLs' callout.
SELECT ITEM.ITEM_ID, ITEM.DESCRIPTION, INVOICE_LINE.INVOICE_NUM
FROM ITEM LEFT JOIN INVOICE_LINE ON ITEM.ITEM_ID = INVOICE_LINE.ITEM_ID
ORDER BY ITEM.ITEM_ID, INVOICE_LINE.INVOICE_NUM;

-- Check 84
-- Expected: 1 row: 12
SELECT COUNT(*) AS ROW_COUNT FROM CUSTOMER, REP;

-- Check 85
-- Expected: 12 rows: each of 1120, 1225, 1310, 1420 paired with each of 20, 35, 65. Only 4 of the 12 pair a customer with its real rep, so 8 are nonsense, as the prose says.
SELECT CUSTOMER.CUSTOMER_NUM, REP.REP_NUM
FROM CUSTOMER, REP
ORDER BY CUSTOMER.CUSTOMER_NUM, REP.REP_NUM;

-- Check 86
-- Expected: 1 row: 12. Confirms CROSS JOIN and the comma form agree.
SELECT COUNT(*) AS ROW_COUNT FROM CUSTOMER CROSS JOIN REP;

-- Check 87
-- Expected: 4 rows, byte-identical to the INNER JOIN ... ON version: 1120 Kaiser; 1225 Hull; 1310 Kaiser; 1420 Perez
SELECT CUSTOMER.CUSTOMER_NUM, CUSTOMER.CUSTOMER_NAME, REP.LAST_NAME
FROM CUSTOMER, REP
WHERE CUSTOMER.REP_NUM = REP.REP_NUM
ORDER BY CUSTOMER.CUSTOMER_NUM;

-- Check 88
-- Expected: 5 rows: P100 101 L001; P100 102 L002; P200 101 with NULL LEASE_ID; P200 201 L003; P200 202 L004
SELECT ROOM.PROPERTY_ID, ROOM.ROOM_NUM, LEASE.LEASE_ID
FROM ROOM LEFT JOIN LEASE
  ON ROOM.PROPERTY_ID = LEASE.PROPERTY_ID AND ROOM.ROOM_NUM = LEASE.ROOM_NUM
ORDER BY ROOM.PROPERTY_ID, ROOM.ROOM_NUM;

-- Check 89
-- Expected: 5 rows: L001 1 595.00; L001 2 595.00; L002 3 450.00; L003 4 725.00; L004 with NULL payment. Shows a left join both duplicating and NULL-padding.
SELECT LEASE.LEASE_ID, PAYMENT.PAYMENT_ID, PAYMENT.AMOUNT
FROM LEASE LEFT JOIN PAYMENT ON LEASE.LEASE_ID = PAYMENT.LEASE_ID
ORDER BY LEASE.LEASE_ID, PAYMENT.PAYMENT_ID;

-- Check 90
-- Expected: 1 row: 8. Backs the matcher card claiming 4 students times 2 properties.
SELECT COUNT(*) AS ROW_COUNT FROM STUDENT, PROPERTY;

-- Check 91
-- Expected: 3 rows: 20 Kaiser 2; 35 Hull 1; 65 Perez 1. Used to confirm the 'every rep has customers' claim behind the KimTay examples.
SELECT REP.REP_NUM, REP.LAST_NAME, COUNT(CUSTOMER.CUSTOMER_NUM) AS NUM_CUSTOMERS
FROM REP LEFT JOIN CUSTOMER ON REP.REP_NUM = CUSTOMER.REP_NUM
GROUP BY REP.REP_NUM, REP.LAST_NAME
ORDER BY REP.REP_NUM;

-- ----------------------------------------------------------------------
-- Group m5end  --  32 checks
-- ----------------------------------------------------------------------


-- Check 92
-- Expected: 4 rows: Access Pet Center 1; Companion Care Clinic 0; Downtown Aquarium & Pets 1; Whiskers & Wags Boutique 1 (m5-summary sandbox solution)
SELECT C.CUSTOMER_NAME, COUNT(I.INVOICE_NUM) AS INVOICE_COUNT FROM CUSTOMER C LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM GROUP BY C.CUSTOMER_NUM, C.CUSTOMER_NAME ORDER BY C.CUSTOMER_NAME;

-- Check 93
-- Expected: 4 rows, every count 1, including Companion Care Clinic - the COUNT(*) trap in review Q2
SELECT C.CUSTOMER_NAME, COUNT(*) FROM CUSTOMER C LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM GROUP BY C.CUSTOMER_NUM, C.CUSTOMER_NAME;

-- Check 94
-- Expected: 1 row: Access Pet Center | Companion Care Clinic | Maple Grove (m5-terms sandbox starter)
SELECT F.CUSTOMER_NAME AS FIRST_ONE, S.CUSTOMER_NAME AS SECOND_ONE, F.CITY FROM CUSTOMER F, CUSTOMER S WHERE F.CITY = S.CITY AND F.CUSTOMER_NUM < S.CUSTOMER_NUM;

-- Check 95
-- Expected: 3 rows: Brookville; Maple Grove; Northfield (m5-terms sandbox solution)
SELECT CITY FROM REP UNION SELECT CITY FROM CUSTOMER ORDER BY CITY;

-- Check 96
-- Expected: 3 rows: Access Pet Center; Downtown Aquarium & Pets; Whiskers & Wags Boutique - Companion Care Clinic excluded (m5-terms sandbox solution and matcher card 8)
SELECT C.CUSTOMER_NAME FROM CUSTOMER C WHERE EXISTS (SELECT 1 FROM INVOICE I WHERE I.CUSTOMER_NUM = C.CUSTOMER_NUM);

-- Check 97
-- Expected: 5 rows: REP 3; CUSTOMER 4; INVOICE 3; INVOICE_LINE 6; ITEM 5 - the first five of the eleven numbers named in the m5-review sandbox hint
SELECT 'REP' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM REP UNION ALL SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER UNION ALL SELECT 'INVOICE', COUNT(*) FROM INVOICE UNION ALL SELECT 'INVOICE_LINE', COUNT(*) FROM INVOICE_LINE UNION ALL SELECT 'ITEM', COUNT(*) FROM ITEM;

-- Check 98
-- Expected: 6 rows: MANAGER 2; PROPERTY 2; ROOM 5; STUDENT 4; LEASE 4; PAYMENT 4 - the remaining six of the eleven numbers (m5-review sandbox solution)
SELECT 'MANAGER' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM MANAGER UNION ALL SELECT 'PROPERTY', COUNT(*) FROM PROPERTY UNION ALL SELECT 'ROOM', COUNT(*) FROM ROOM UNION ALL SELECT 'STUDENT', COUNT(*) FROM STUDENT UNION ALL SELECT 'LEASE', COUNT(*) FROM LEASE UNION ALL SELECT 'PAYMENT', COUNT(*) FROM PAYMENT;

-- Check 99
-- Expected: 3 rows: 50710 2026-06-14 Access Pet Center Kaiser; 50711 2026-06-14 Whiskers & Wags Boutique Perez; 50712 2026-06-15 Downtown Aquarium & Pets Hull (exercise 1)
SELECT I.INVOICE_NUM, I.INVOICE_DATE, C.CUSTOMER_NAME, R.LAST_NAME FROM INVOICE I, CUSTOMER C, REP R WHERE I.CUSTOMER_NUM = C.CUSTOMER_NUM AND C.REP_NUM = R.REP_NUM ORDER BY I.INVOICE_NUM;

-- Check 100
-- Expected: 2 rows: Grain-Free Dry Food 30lb; Nylon Dog Leash 6ft (exercise 2)
SELECT DISTINCT T.DESCRIPTION FROM ITEM T, INVOICE_LINE L, INVOICE I, CUSTOMER C WHERE T.ITEM_ID = L.ITEM_ID AND L.INVOICE_NUM = I.INVOICE_NUM AND I.CUSTOMER_NUM = C.CUSTOMER_NUM AND C.REP_NUM = '20' ORDER BY T.DESCRIPTION;

-- Check 101
-- Expected: Also 2 rows without DISTINCT - rep 20's only invoiced customer (1120) has a single invoice, so DISTINCT collapses nothing on the shipped data. This is why exercise 2's prose presents DISTINCT as insurance rather than as a fix for duplicates that exist today.
SELECT T.DESCRIPTION FROM ITEM T, INVOICE_LINE L, INVOICE I, CUSTOMER C WHERE T.ITEM_ID = L.ITEM_ID AND L.INVOICE_NUM = I.INVOICE_NUM AND I.CUSTOMER_NUM = C.CUSTOMER_NUM AND C.REP_NUM = '20';

-- Check 102
-- Expected: 4 rows: Carter Miles 450; Ibrahim Layla 725; Nguyen Trang 1190; Park Jason NULL. The NULL is produced by the outer join, not stored in PAYMENT (exercise 3)
SELECT S.LAST_NAME, S.FIRST_NAME, SUM(P.AMOUNT) AS PAID FROM STUDENT S LEFT JOIN LEASE L ON S.STUDENT_ID = L.STUDENT_ID LEFT JOIN PAYMENT P ON L.LEASE_ID = P.LEASE_ID GROUP BY S.STUDENT_ID, S.LAST_NAME, S.FIRST_NAME ORDER BY S.LAST_NAME;

-- Check 103
-- Expected: Still 4 rows, Park Jason NULL - an inner join to LEASE does NOT drop anyone, because every student has a lease. Only an inner join to PAYMENT drops Park, which is what exercise 3's hint must say.
SELECT S.LAST_NAME, SUM(P.AMOUNT) FROM STUDENT S JOIN LEASE L ON S.STUDENT_ID = L.STUDENT_ID LEFT JOIN PAYMENT P ON L.LEASE_ID = P.LEASE_ID GROUP BY S.STUDENT_ID ORDER BY S.LAST_NAME;

-- Check 104
-- Expected: 3 rows: Carter 450; Ibrahim 725; Nguyen 1190 - Park Jason is gone. This is the exact failure exercise 3's hint diagnoses.
SELECT S.LAST_NAME, SUM(P.AMOUNT) FROM STUDENT S LEFT JOIN LEASE L ON S.STUDENT_ID = L.STUDENT_ID JOIN PAYMENT P ON L.LEASE_ID = P.LEASE_ID GROUP BY S.STUDENT_ID ORDER BY S.LAST_NAME;

-- Check 105
-- Expected: 1 row: P200 | 101 | Single (exercise 4, NOT EXISTS version - three columns)
SELECT R.PROPERTY_ID, R.ROOM_NUM, R.ROOM_TYPE FROM ROOM R WHERE NOT EXISTS (SELECT 1 FROM LEASE L WHERE L.PROPERTY_ID = R.PROPERTY_ID AND L.ROOM_NUM = R.ROOM_NUM);

-- Check 106
-- Expected: 1 row: P200 | 101 (exercise 4, difference version - two columns only)
SELECT PROPERTY_ID, ROOM_NUM FROM ROOM EXCEPT SELECT PROPERTY_ID, ROOM_NUM FROM LEASE;

-- Check 107
-- Expected: Error: SELECTs to the left and right of EXCEPT do not have the same number of result columns. LEASE has no ROOM_TYPE, so the difference version cannot report the room type - exercise 4's prose must say so instead of asking for the same three columns twice.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT PROPERTY_ID, ROOM_NUM, ROOM_TYPE FROM ROOM EXCEPT SELECT PROPERTY_ID, ROOM_NUM FROM LEASE;

-- Check 108
-- Expected: 1 row: Northfield (exercise 5)
SELECT CITY FROM CUSTOMER EXCEPT SELECT CITY FROM REP;

-- Check 109
-- Expected: 12 rows - the product of 3 reps and 4 customers (review Q1, matcher card 5)
SELECT R.LAST_NAME, C.CUSTOMER_NAME FROM REP R, CUSTOMER C;

-- Check 110
-- Expected: 0 rows - every one of the five items has been ordered (review Q3)
SELECT DESCRIPTION FROM ITEM I WHERE NOT EXISTS (SELECT 1 FROM INVOICE_LINE L WHERE L.ITEM_ID = I.ITEM_ID);

-- Check 111
-- Expected: 1 row: 7 - UNION ALL keeps all 3 + 4 city values, versus 3 for UNION (review Q4)
SELECT COUNT(*) FROM (SELECT CITY FROM REP UNION ALL SELECT CITY FROM CUSTOMER);

-- Check 112
-- Expected: 3 rows: Access Pet Center 50710; Whiskers & Wags Boutique 50711; Downtown Aquarium & Pets 50712 - Companion Care Clinic absent (review Q5)
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM FROM INVOICE I LEFT JOIN CUSTOMER C ON I.CUSTOMER_NUM = C.CUSTOMER_NUM;

-- Check 113
-- Expected: 1 row: Whiskers & Wags Boutique. SQLite rejects this statement with 'near "ALL": syntax error', so it is labelled MySQL only, kept out of every sandbox, and paired with the MAX rewrite (review Q6, summary engine note, m5-terms ALL row)
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE BALANCE > ALL (SELECT BALANCE FROM CUSTOMER WHERE REP_NUM = '20');

-- Check 114
-- Expected: 3 rows: Access Pet Center; Downtown Aquarium & Pets; Whiskers & Wags Boutique. SQLite rejects this with a syntax error at the subquery after ANY, so it is labelled MySQL only and paired with the MIN rewrite (summary engine note, m5-terms ANY row)
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE BALANCE > ANY (SELECT BALANCE FROM CUSTOMER WHERE REP_NUM = '20');

-- Check 115
-- Expected: 1 row: Whiskers & Wags Boutique - the runnable equivalent of > ALL (review Q6, summary engine note)
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE BALANCE > (SELECT MAX(BALANCE) FROM CUSTOMER WHERE REP_NUM = '20');

-- Check 116
-- Expected: 3 rows in balance order: Downtown Aquarium & Pets 1200; Access Pet Center 3512.5; Whiskers & Wags Boutique 4820.75 (SQLite prints no trailing zeros) - the runnable equivalent of > ANY (summary engine note)
SELECT CUSTOMER_NAME, BALANCE FROM CUSTOMER WHERE BALANCE > (SELECT MIN(BALANCE) FROM CUSTOMER WHERE REP_NUM = '20') ORDER BY BALANCE;

-- Check 117
-- Expected: 2 rows: Access Pet Center/Companion Care Clinic and Companion Care Clinic/Access Pet Center (review Q7)
SELECT A.CUSTOMER_NAME, B.CUSTOMER_NAME FROM CUSTOMER A, CUSTOMER B WHERE A.CITY = B.CITY AND A.CUSTOMER_NUM <> B.CUSTOMER_NUM;

-- Check 118
-- Expected: Error: ambiguous column name: REP_NUM (review Q8)
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER_NAME, LAST_NAME FROM REP, CUSTOMER WHERE REP_NUM = REP_NUM;

-- Check 119
-- Expected: 2 rows: Access Pet Center; Whiskers & Wags Boutique (review Q10)
SELECT CUSTOMER_NAME FROM CUSTOMER WHERE CUSTOMER_NUM IN (SELECT CUSTOMER_NUM FROM INVOICE WHERE INVOICE_NUM IN (SELECT INVOICE_NUM FROM INVOICE_LINE WHERE ITEM_ID = 'CF21'));

-- Check 120
-- Expected: Error: no such column: CUSTOMER.CITY - an alias replaces the table name (m5-terms closing paragraph)
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CUSTOMER.CITY FROM CUSTOMER F;

-- Check 121
-- Expected: Error: no such column: REP.LAST_NAME - the same rule stated on matcher card 2
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT REP.LAST_NAME FROM REP R;

-- Check 122
-- Expected: Error: SELECTs to the left and right of UNION do not have the same number of result columns - the two results are not union compatible (m5-terms callout)
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CITY FROM REP UNION SELECT CITY, STATE FROM CUSTOMER;

-- Check 123
-- Expected: 1 row: 16 - the 4 by 4 product described in matcher card 6
SELECT COUNT(*) FROM CUSTOMER, STUDENT;
