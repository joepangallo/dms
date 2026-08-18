-- ======================================================================
-- Module 8 · Verification queries and expected results
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
-- Group m8a  --  44 checks
-- ----------------------------------------------------------------------


-- Check 1
-- Expected: 2 rows: 1120 Access Pet Center 3512.5; 1310 Companion Care Clinic 0
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- Check 2
-- Expected: Prepared statement shown inside host-language pseudocode. A driver compiles it once and supplies '20' for the ? at execute time, returning the same 2 rows. It is not runnable as typed at any SQL prompt, in any engine, because the ? has no value yet.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE FROM CUSTOMER WHERE REP_NUM = ? ORDER BY CUSTOMER_NUM

-- Check 3
-- Expected: MySQL: creates the stored procedure, no result set. Sandbox: verified to fail with 'near "PROCEDURE": syntax error' - CREATE PROCEDURE is not implemented in SQLite. Presented as a labeled MySQL-only code block, never as a sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER $$
CREATE PROCEDURE CUSTOMERS_OF_REP(IN REP_WANTED CHAR(2))
BEGIN
    SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
    FROM CUSTOMER
    WHERE REP_NUM = REP_WANTED
    ORDER BY CUSTOMER_NUM;
END$$
DELIMITER ;

-- Check 4
-- Expected: MySQL: returns 1120 Access Pet Center 3512.50 and 1310 Companion Care Clinic 0.00. Not runnable in the sandbox; CALL does not exist in SQLite.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL CUSTOMERS_OF_REP('20');

-- Check 5
-- Expected: 1 row: CF21 | 42.5 | 44. Executed three times in a row against one persistent sql.js database and returned CF21|42.5|44 every time. The reset UPDATE is required: the page reseeds only on Reset, and without it a second Run logs CF21|44|44 because OLD.PRICE is whatever the previous Run left behind. The reset runs before CREATE TRIGGER, so it logs nothing itself.
DROP TRIGGER IF EXISTS LOG_PRICE_CHANGE;
DROP TABLE IF EXISTS PRICE_LOG;

UPDATE ITEM SET PRICE = 42.50 WHERE ITEM_ID = 'CF21';

CREATE TABLE PRICE_LOG (
    ITEM_ID    CHAR(4),
    OLD_PRICE  DECIMAL(7,2),
    NEW_PRICE  DECIMAL(7,2),
    CHANGED_ON DATE
);

CREATE TRIGGER LOG_PRICE_CHANGE
AFTER UPDATE OF PRICE ON ITEM
BEGIN
    INSERT INTO PRICE_LOG
    VALUES (OLD.ITEM_ID, OLD.PRICE, NEW.PRICE, DATE('now'));
END;

UPDATE ITEM SET PRICE = 44.00 WHERE ITEM_ID = 'CF21';

SELECT ITEM_ID, OLD_PRICE, NEW_PRICE FROM PRICE_LOG;

-- Check 6
-- Expected: 4 rows: 1120 Access Pet Center Maple Grove; 1225 Downtown Aquarium & Pets Northfield; 1310 Companion Care Clinic Maple Grove; 1420 Whiskers & Wags Boutique Brookville
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- Check 7
-- Expected: 4 rows: 1120 ACCESS PET CENTER maple grove; 1225 DOWNTOWN AQUARIUM & PETS northfield; 1310 COMPANION CARE CLINIC maple grove; 1420 WHISKERS & WAGS BOUTIQUE brookville
SELECT CUSTOMER_NUM,
       UPPER(CUSTOMER_NAME) AS UPPER_NAME,
       LOWER(CITY) AS LOWER_CITY
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- Check 8
-- Expected: 0 rows. Text comparison with = is case sensitive, so the lower case literal matches nothing. sql.js returns no result set at all for a zero-row SELECT, so the page prints its 'Ran successfully. (No rows returned...)' message instead of an empty table. This is the intended starter behavior and the lesson prose now says so.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE CITY = 'maple grove'
ORDER BY CUSTOMER_NUM;

-- Check 9
-- Expected: 0 rows. Quiz distractor: lowering only the column leaves the literal capitalized, so the two sides still differ.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE LOWER(CITY) = 'MAPLE GROVE'
ORDER BY CUSTOMER_NUM;

-- Check 10
-- Expected: 2 rows: 1120 Access Pet Center Maple Grove; 1310 Companion Care Clinic Maple Grove
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE UPPER(CITY) = 'MAPLE GROVE'
ORDER BY CUSTOMER_NUM;

-- Check 11
-- Expected: 5 rows: AV07 Aviary Starter Cage; CF21 Grain-Free Dry Food 30lb; DG04 Nylon Dog Leash 6ft; FT88 Fish Tank Filter Kit; GR15 Small Animal Grooming Kit
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
ORDER BY ITEM_ID;

-- Check 12
-- Expected: 5 rows: AV07 AV 19; CF21 CF 24; DG04 DG 19; FT88 FT 20; GR15 GR 25. SUBSTRING(ITEM_ID,1,2) was also verified to run in SQLite 3.45.2 and give the same PREFIX values.
SELECT ITEM_ID,
       SUBSTR(ITEM_ID, 1, 2) AS PREFIX,
       LENGTH(DESCRIPTION) AS NAME_LENGTH
FROM ITEM
ORDER BY ITEM_ID;

-- Check 13
-- Expected: 2 rows: CF21 Grain-Free Dry Food 30lb 24; GR15 Small Animal Grooming Kit 25. Changing 20 to 19 returns 3 rows, adding FT88 at exactly 20.
SELECT ITEM_ID, DESCRIPTION, LENGTH(DESCRIPTION) AS NAME_LENGTH
FROM ITEM
WHERE LENGTH(DESCRIPTION) > 20
ORDER BY ITEM_ID;

-- Check 14
-- Expected: Sandbox: verified to fail with "no such function: CHAR_LENGTH". MySQL runs it and returns the character count. This is why the character-function table marks CHAR_LENGTH as non-portable.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CHAR_LENGTH(CITY) FROM REP;

-- Check 15
-- Expected: 1 row: [ Maple Grove ] | [Maple Grove] | 15 | 11
SELECT '[' || '  Maple Grove  ' || ']' AS RAW_VALUE,
       '[' || TRIM('  Maple Grove  ') || ']' AS TRIMMED_VALUE,
       LENGTH('  Maple Grove  ') AS BEFORE_LEN,
       LENGTH(TRIM('  Maple Grove  ')) AS AFTER_LEN;

-- Check 16
-- Expected: 3 rows: 20 Valerie Kaiser; 35 Richard Hull; 65 Juan Perez
SELECT REP_NUM, FIRST_NAME, LAST_NAME
FROM REP
ORDER BY REP_NUM;

-- Check 17
-- Expected: 3 rows: 20 VK KAI; 35 RH HUL; 65 JP PER
SELECT REP_NUM,
       SUBSTR(FIRST_NAME, 1, 1) || SUBSTR(LAST_NAME, 1, 1) AS INITIALS,
       UPPER(SUBSTR(LAST_NAME, 1, 3)) AS CODE
FROM REP
ORDER BY REP_NUM;

-- Check 18
-- Expected: 3 rows: 20 21560 0.05; 35 39355 0.07; 65 23764 0.05
SELECT REP_NUM, COMMISSION, RATE
FROM REP
ORDER BY REP_NUM;

-- Check 19
-- Expected: 3 rows as rendered by the page: 20 | 21560 | 0.05 | 1078 | 1078; 35 | 39355 | 0.07 | 2754.8500000000004 | 2754.85; 65 | 23764 | 0.05 | 1188.2 | 1188.2. Rep 35 is the only row where ROUND changes anything - that float tail is what motivates the function. Note the page prints REAL values through JavaScript String(), so a whole result shows as 1078, never 1078.0.
SELECT REP_NUM, COMMISSION, RATE,
       COMMISSION * RATE AS RAW_PAYOUT,
       ROUND(COMMISSION * RATE, 2) AS PAYOUT
FROM REP
ORDER BY REP_NUM;

-- Check 20
-- Expected: 6 rows: 50710 CF21 3 42.5; 50710 DG04 2 11.99; 50711 CF21 2 42.5; 50711 GR15 1 15.25; 50712 AV07 1 64.99; 50712 FT88 2 27.75
SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE
FROM INVOICE_LINE
ORDER BY INVOICE_NUM, ITEM_ID;

-- Check 21
-- Expected: 6 rows with LINE_TOTAL rendered as 127.5, 23.98, 85, 15.25, 64.99, 55.5 in that order. The 50711/CF21 total renders as 85, not 85.0.
SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE,
       ROUND(NUM_ORDERED * QUOTED_PRICE, 2) AS LINE_TOTAL
FROM INVOICE_LINE
ORDER BY INVOICE_NUM, ITEM_ID;

-- Check 22
-- Expected: 4 rows: 1120 Access Pet Center 3512.5 7500; 1225 Downtown Aquarium & Pets 1200 5000; 1310 Companion Care Clinic 0 10000; 1420 Whiskers & Wags Boutique 4820.75 6000
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- Check 23
-- Expected: 4 rows: 1120 -3987.5 3987.5; 1225 -3800 3800; 1310 -10000 10000; 1420 -1179.25 1179.25
SELECT CUSTOMER_NUM, CUSTOMER_NAME,
       BALANCE - CREDIT_LIMIT AS DIFF,
       ABS(BALANCE - CREDIT_LIMIT) AS GAP
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- Check 24
-- Expected: 4 rows in this order: 1310 Companion Care Clinic 10000; 1120 Access Pet Center 3987.5; 1225 Downtown Aquarium & Pets 3800; 1420 Whiskers & Wags Boutique 1179.25
SELECT CUSTOMER_NUM, CUSTOMER_NAME,
       ABS(CREDIT_LIMIT - BALANCE) AS AVAILABLE
FROM CUSTOMER
ORDER BY ABS(CREDIT_LIMIT - BALANCE) DESC;

-- Check 25
-- Expected: MySQL: 5 rows with WHOLE_DOLLARS 64, 42, 11, 27, 15. Sandbox: verified to fail with "no such function: TRUNCATE", so it ships as a labeled MySQL-only code block.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT ITEM_ID, PRICE, TRUNCATE(PRICE, 0) AS WHOLE_DOLLARS
FROM ITEM
ORDER BY ITEM_ID;

-- Check 26
-- Expected: 5 rows as rendered: AV07 64.99 65 64; CF21 42.5 43 42; DG04 11.99 12 11; FT88 27.75 28 27; GR15 15.25 15 15. ROUND returns a REAL, but the page renders it through JavaScript String(), so 65.0 displays as 65 - the hint must not promise a trailing .0.
SELECT ITEM_ID, PRICE,
       ROUND(PRICE, 0) AS ROUNDED,
       CAST(PRICE AS INTEGER) AS CHOPPED
FROM ITEM
ORDER BY ITEM_ID;

-- Check 27
-- Expected: 1 row. TODAY is the current UTC date in YYYY-MM-DD form and RIGHT_NOW is that date plus HH:MM:SS (verified 2026-08-03 and 2026-08-03 02:21:19 at check time). The values change on every run, which the lesson states explicitly.
SELECT DATE('now') AS TODAY,
       DATETIME('now') AS RIGHT_NOW;

-- Check 28
-- Expected: 3 rows: 50710 2026-06-14; 50711 2026-06-14; 50712 2026-06-15
SELECT INVOICE_NUM, INVOICE_DATE
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 29
-- Expected: 3 rows, all with INVOICE_YEAR 2026, INVOICE_MONTH 06 and PERIOD 2026-06; typeof() confirms all three come back as text, with the leading zero kept
SELECT INVOICE_NUM, INVOICE_DATE,
       strftime('%Y', INVOICE_DATE) AS INVOICE_YEAR,
       strftime('%m', INVOICE_DATE) AS INVOICE_MONTH,
       strftime('%Y-%m', INVOICE_DATE) AS PERIOD
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 30
-- Expected: 3 rows, every value NULL. Quiz distractor: 'year' is not a valid modifier, and SQLite answers with NULL rather than an error - the option note now says so.
SELECT DATE(INVOICE_DATE, 'year') FROM INVOICE ORDER BY INVOICE_NUM;

-- Check 31
-- Expected: 3 rows: 50710 2026-06-14 2026-06-29; 50711 2026-06-14 2026-06-29; 50712 2026-06-15 2026-06-30
SELECT INVOICE_NUM, INVOICE_DATE,
       DATE(INVOICE_DATE, '+15 days') AS DUE_DATE
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 32
-- Expected: 3 rows: 50710 2026-06-14 2026-07-14; 50711 2026-06-14 2026-07-14; 50712 2026-06-15 2026-07-15
SELECT INVOICE_NUM, INVOICE_DATE,
       DATE(INVOICE_DATE, '+30 days') AS DUE_DATE
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 33
-- Expected: 3 rows: 50710 2026-06-14 2461205.5; 50711 2026-06-14 2461205.5; 50712 2026-06-15 2461206.5
SELECT INVOICE_NUM, INVOICE_DATE,
       julianday(INVOICE_DATE) AS JULIAN
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 34
-- Expected: 3 rows: 50710 17; 50711 17; 50712 16. Both operands are dates at the same Julian half-day offset, so the difference is exactly whole and the page renders 17, NOT 17.0 - no CAST is needed to clean it up here.
SELECT INVOICE_NUM, INVOICE_DATE,
       julianday('2026-07-01') - julianday(INVOICE_DATE) AS DAYS_OLD
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 35
-- Expected: 3 rows, values change with the clock. Verified at check time: RAW_DAYS 50.10020332178101, 50.10020332178101, 49.10020332178101 and DAYS_OLD 50, 50, 49. This is where the fraction is genuinely visible, because 'now' carries the time of day; CAST chops rather than rounds.
SELECT INVOICE_NUM, INVOICE_DATE,
       julianday('now') - julianday(INVOICE_DATE) AS RAW_DAYS,
       CAST(julianday('now') - julianday(INVOICE_DATE) AS INTEGER) AS DAYS_OLD
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 36
-- Expected: MySQL: 3 rows with INVOICE_YEAR 2026, DUE_DATE 2026-07-14, 2026-07-14, 2026-07-15, and DAYS_OLD counted from the current date. Sandbox: CURDATE, YEAR and DATEDIFF each fail with 'no such function', while DATE_ADD fails earlier still with 'near "30": syntax error' because INTERVAL 30 DAY is unparseable - the warning callout now distinguishes the two failure modes. Ships only as a labeled MySQL-only code block.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT CURDATE() AS TODAY,
       YEAR(INVOICE_DATE) AS INVOICE_YEAR,
       DATEDIFF(CURDATE(), INVOICE_DATE) AS DAYS_OLD,
       DATE_ADD(INVOICE_DATE, INTERVAL 30 DAY) AS DUE_DATE
FROM INVOICE
ORDER BY INVOICE_NUM;

-- Check 37
-- Expected: 3 rows: 20 ValerieKaiser; 35 RichardHull; 65 JuanPerez (no space, which is the point of the starter). CONCAT exists in SQLite from 3.44 onward and this sandbox is 3.45.2, verified.
SELECT REP_NUM,
       CONCAT(FIRST_NAME, LAST_NAME) AS FULL_NAME
FROM REP
ORDER BY REP_NUM;

-- Check 38
-- Expected: 3 rows: 20 Valerie Kaiser; 35 Richard Hull; 65 Juan Perez
SELECT REP_NUM,
       CONCAT(FIRST_NAME, ' ', LAST_NAME) AS FULL_NAME
FROM REP
ORDER BY REP_NUM;

-- Check 39
-- Expected: 3 rows: 20 Maple Grove OH 44601; 35 Maple Grove OH 44601; 65 Brookville OH 44403
SELECT REP_NUM, CITY, STATE, ZIP
FROM REP
ORDER BY REP_NUM;

-- Check 40
-- Expected: 3 rows: 20 Maple Grove, OH 44601; 35 Maple Grove, OH 44601; 65 Brookville, OH 44403
SELECT REP_NUM,
       CITY || ', ' || STATE || ' ' || ZIP AS MAILING_LINE
FROM REP
ORDER BY REP_NUM;

-- Check 41
-- Expected: 4 rows, the full address columns of CUSTOMER: 1120 Access Pet Center 215 Foster Ave. Maple Grove OH 44601; 1225 Downtown Aquarium & Pets 642 Chestnut St. Northfield OH 44067; 1310 Companion Care Clinic 89 River Rd. Maple Grove OH 44601; 1420 Whiskers & Wags Boutique 77 Elm St. Brookville OH 44403
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- Check 42
-- Expected: 4 rows, e.g. 1120 -> "Access Pet Center, 215 Foster Ave., Maple Grove OH 44601" and 1310 -> "Companion Care Clinic, 89 River Rd., Maple Grove OH 44601". The call takes NINE arguments: five columns and four separators - the hint says nine, not eight.
SELECT CUSTOMER_NUM,
       CONCAT(CUSTOMER_NAME, ', ', STREET, ', ', CITY, ' ', STATE, ' ', ZIP) AS MAILING_LABEL
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- Check 43
-- Expected: 1 row: CONCAT_RESULT is the text 'Rep: ' (typeof text, null skipped); PIPE_RESULT is NULL (typeof null), which the page renders as the literal word NULL, not as a blank cell; SAFE_RESULT is 'Rep: unassigned'. Verified against sql.js 1.10.3 / SQLite 3.45.2; MySQL would return NULL for CONCAT_RESULT instead.
SELECT CONCAT('Rep: ', NULL) AS CONCAT_RESULT,
       'Rep: ' || NULL AS PIPE_RESULT,
       'Rep: ' || COALESCE(NULL, 'unassigned') AS SAFE_RESULT;

-- Check 44
-- Expected: 4 rows. Access Pet Center / 50710, Downtown Aquarium & Pets / 50712 and Whiskers & Wags Boutique / 50711 are identical in all three label columns. Companion Care Clinic has PIPE_LABEL NULL - displayed as the word NULL by the page's cell renderer - CONCAT_LABEL 'Companion Care Clinic / ' and SAFE_LABEL 'Companion Care Clinic / no invoice'.
SELECT C.CUSTOMER_NAME,
       C.CUSTOMER_NAME || ' / ' || I.INVOICE_NUM AS PIPE_LABEL,
       CONCAT(C.CUSTOMER_NAME, ' / ', I.INVOICE_NUM) AS CONCAT_LABEL,
       C.CUSTOMER_NAME || ' / ' || COALESCE(I.INVOICE_NUM, 'no invoice') AS SAFE_LABEL
FROM CUSTOMER C
LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
ORDER BY C.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Group m8b  --  32 checks
-- ----------------------------------------------------------------------


-- Check 45
-- Expected: Query OK, 0 rows affected. Procedure SHOW_REP_COUNT is stored in the current schema. MySQL only: SQLite has no CREATE PROCEDURE.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS SHOW_REP_COUNT //

CREATE PROCEDURE SHOW_REP_COUNT()
BEGIN
    SELECT COUNT(*) AS REP_COUNT FROM REP;
END //

DELIMITER ;

-- Check 46
-- Expected: One result set, one row, one column: REP_COUNT = 3 (reps 20, 35, 65).
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL SHOW_REP_COUNT();

-- Check 47
-- Expected: Query OK, 0 rows affected. The procedure is created successfully; the parameter/column naming collision is not detected until it is called. Shown deliberately as the mistake to avoid.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS BAD_REP_NAME //

CREATE PROCEDURE BAD_REP_NAME(
    IN  REP_NUM     CHAR(2),
    OUT o_last_name VARCHAR(20))
BEGIN
    SELECT LAST_NAME
    INTO   o_last_name
    FROM   REP
    WHERE  REP_NUM = REP_NUM;
END //

DELIMITER ;

-- Check 48
-- Expected: ERROR 1172 (42000): Result consisted of more than one row. Both sides of WHERE REP_NUM = REP_NUM resolve to the parameter, so all three REP rows match.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL BAD_REP_NAME('35', @last);

-- Check 49
-- Expected: Query OK, 0 rows affected. Procedure DISP_REP_NAME stored. Two columns are selected into two variables, matched by position.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS DISP_REP_NAME //

CREATE PROCEDURE DISP_REP_NAME(
    IN  i_rep_num    CHAR(2),
    OUT o_last_name  VARCHAR(20),
    OUT o_first_name VARCHAR(20))
BEGIN
    SELECT LAST_NAME, FIRST_NAME
    INTO   o_last_name, o_first_name
    FROM   REP
    WHERE  REP_NUM = i_rep_num;
END //

DELIMITER ;

-- Check 50
-- Expected: The CALL returns no result set. The SELECT returns one row: LAST_NAME = Hull, FIRST_NAME = Richard.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL DISP_REP_NAME('35', @last, @first);
SELECT @last AS LAST_NAME, @first AS FIRST_NAME;

-- Check 51
-- Expected: Query OK, 0 rows affected. Procedure GET_CREDIT_AVAILABLE stored.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS GET_CREDIT_AVAILABLE //

CREATE PROCEDURE GET_CREDIT_AVAILABLE(
    IN  i_customer_num CHAR(4),
    OUT o_available    DECIMAL(9,2))
BEGIN
    DECLARE v_balance      DECIMAL(9,2);
    DECLARE v_credit_limit DECIMAL(9,2);

    SELECT BALANCE, CREDIT_LIMIT
    INTO   v_balance, v_credit_limit
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    SET o_available = v_credit_limit - v_balance;
END //

DELIMITER ;

-- Check 52
-- Expected: Two result sets. First: CREDIT_AVAILABLE = 1179.25 (6000.00 - 4820.75, Whiskers & Wags Boutique). Second: CREDIT_AVAILABLE = 10000.00 (10000.00 - 0.00, Companion Care Clinic). Neither call changes any row.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL GET_CREDIT_AVAILABLE('1420', @avail);
SELECT @avail AS CREDIT_AVAILABLE;

CALL GET_CREDIT_AVAILABLE('1310', @avail);
SELECT @avail AS CREDIT_AVAILABLE;

-- Check 53
-- Expected: Query OK, 0 rows affected. Procedure ADD_SALE_TO_COMMISSION stored. It computes a new total for the caller and does not write to REP.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS ADD_SALE_TO_COMMISSION //

CREATE PROCEDURE ADD_SALE_TO_COMMISSION(
    IN    i_rep_num     CHAR(2),
    IN    i_sale_amount DECIMAL(9,2),
    INOUT io_commission DECIMAL(8,2))
BEGIN
    DECLARE v_rate DECIMAL(4,2);

    SELECT RATE
    INTO   v_rate
    FROM   REP
    WHERE  REP_NUM = i_rep_num;

    SET io_commission = io_commission + (i_sale_amount * v_rate);
END //

DELIMITER ;

-- Check 54
-- Expected: One row: NEW_COMMISSION = 39439.00. Rep 35's RATE is 0.07, so 1200.00 * 0.07 = 84.00 is added to 39355.00. The REP table is unchanged.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SET @comm = 39355.00;
CALL ADD_SALE_TO_COMMISSION('35', 1200.00, @comm);
SELECT @comm AS NEW_COMMISSION;

-- Check 55
-- Expected: One row per stored routine in the current database, each with ROUTINE_TYPE = PROCEDURE. After 8-4 that is ADD_SALE_TO_COMMISSION, BAD_REP_NAME, DISP_REP_NAME, GET_CREDIT_AVAILABLE, SHOW_REP_COUNT, in that alphabetical order. INFORMATION_SCHEMA does not exist in SQLite.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM   INFORMATION_SCHEMA.ROUTINES
WHERE  ROUTINE_SCHEMA = DATABASE()
ORDER  BY ROUTINE_NAME;

-- Check 56
-- Expected: One row holding the stored CREATE PROCEDURE text for DISP_REP_NAME, confirming that it exists in the current schema. The Create Procedure column also shows the DEFINER clause MySQL supplied.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SHOW CREATE PROCEDURE DISP_REP_NAME;

-- Check 57
-- Expected: Query OK, 0 rows affected. Procedure GET_CUST_BALANCE_UNSAFE stored. It deliberately has no handler.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS GET_CUST_BALANCE_UNSAFE //

CREATE PROCEDURE GET_CUST_BALANCE_UNSAFE(
    IN  i_customer_num CHAR(4),
    OUT o_balance      DECIMAL(9,2))
BEGIN
    SELECT BALANCE
    INTO   o_balance
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;
END //

DELIMITER ;

-- Check 58
-- Expected: First SELECT: BALANCE_FOUND = 3512.50. The second CALL raises Warning 1329, 'No data - zero rows fetched, selected, or processed', which SHOW WARNINGS displays. Final SELECT: BALANCE_FOUND = NULL, because the OUT parameter was set to NULL as the procedure started and nothing was assigned.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SET @bal = 0;
CALL GET_CUST_BALANCE_UNSAFE('1120', @bal);
SELECT @bal AS BALANCE_FOUND;

CALL GET_CUST_BALANCE_UNSAFE('9999', @bal);
SHOW WARNINGS;
SELECT @bal AS BALANCE_FOUND;

-- Check 59
-- Expected: Query OK, 0 rows affected. Procedure STALE_DEMO stored.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS STALE_DEMO //

CREATE PROCEDURE STALE_DEMO(
    IN    i_customer_num CHAR(4),
    INOUT io_balance     DECIMAL(9,2))
BEGIN
    SELECT BALANCE
    INTO   io_balance
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;
END //

DELIMITER ;

-- Check 60
-- Expected: Both SELECT statements return BALANCE_FOUND = 3512.50. The INOUT parameter is not blanked at entry, so it carries the 3512.50 left over from the first call into the second; warning 1329 is raised, nothing is assigned, and that stale value is handed back for a customer that does not exist.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SET @bal = 0;
CALL STALE_DEMO('1120', @bal);
SELECT @bal AS BALANCE_FOUND;

CALL STALE_DEMO('9999', @bal);
SELECT @bal AS BALANCE_FOUND;

-- Check 61
-- Expected: Query OK, 0 rows affected. Procedure GET_CUST_BALANCE stored with a CONTINUE handler for NOT FOUND, declared before the first executable statement as MySQL requires.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS GET_CUST_BALANCE //

CREATE PROCEDURE GET_CUST_BALANCE(
    IN  i_customer_num CHAR(4),
    OUT o_balance      DECIMAL(9,2),
    OUT o_status       VARCHAR(60))
BEGIN
    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET o_status = CONCAT('No customer numbered ', i_customer_num);

    SET o_balance = NULL;
    SET o_status  = 'OK';

    SELECT BALANCE
    INTO   o_balance
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;
END //

DELIMITER ;

-- Check 62
-- Expected: First row: BALANCE_FOUND = 3512.50, STATUS = OK. Second row: BALANCE_FOUND = NULL, STATUS = 'No customer numbered 9999'. No error reaches the client.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL GET_CUST_BALANCE('1120', @bal, @status);
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;

CALL GET_CUST_BALANCE('9999', @bal, @status);
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;

-- Check 63
-- Expected: Query OK, 0 rows affected. Procedure GET_BALANCE_BY_CITY stored with an EXIT handler for SQLEXCEPTION.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS GET_BALANCE_BY_CITY //

CREATE PROCEDURE GET_BALANCE_BY_CITY(
    IN  i_city    VARCHAR(20),
    OUT o_balance DECIMAL(9,2),
    OUT o_status  VARCHAR(60))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        SET o_status = CONCAT('Lookup failed for ', i_city, ' - check the city');

    SET o_balance = NULL;
    SET o_status  = 'OK';

    SELECT BALANCE
    INTO   o_balance
    FROM   CUSTOMER
    WHERE  CITY = i_city;
END //

DELIMITER ;

-- Check 64
-- Expected: First row: BALANCE_FOUND = 1200.00, STATUS = OK (only Downtown Aquarium & Pets is in Northfield). Second row: BALANCE_FOUND = NULL, STATUS = 'Lookup failed for Maple Grove - check the city', because customers 1120 and 1310 both match, ERROR 1172 (42000) is raised, and the handler catches it so nothing reaches the client.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL GET_BALANCE_BY_CITY('Northfield', @bal, @status);
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;

CALL GET_BALANCE_BY_CITY('Maple Grove', @bal, @status);
SELECT @bal AS BALANCE_FOUND, @status AS STATUS;

-- Check 65
-- Expected: Query OK, 4 rows affected: 1120 becomes 3762.50, 1225 becomes 1450.00, 1310 becomes 250.00, 1420 becomes 5070.75. Recorded here only to document the accident a procedure prevents. It is NOT part of any worked example and must not be run: every later example in this group assumes the shipped balances are intact.
UPDATE CUSTOMER
SET    BALANCE = BALANCE + 250.00;

-- Check 66
-- Expected: Query OK, 0 rows affected. Procedure UPD_CUST_BALANCE stored. Declaration order is the required one: local variable, then handler, then executable statements.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS UPD_CUST_BALANCE //

CREATE PROCEDURE UPD_CUST_BALANCE(
    IN  i_customer_num CHAR(4),
    IN  i_amount       DECIMAL(9,2),
    OUT o_status       VARCHAR(60))
BEGIN
    DECLARE v_name VARCHAR(35);

    DECLARE EXIT HANDLER FOR NOT FOUND
        SET o_status = CONCAT('No customer numbered ', i_customer_num, ' - nothing changed');

    SELECT CUSTOMER_NAME
    INTO   v_name
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    UPDATE CUSTOMER
    SET    BALANCE = BALANCE + i_amount
    WHERE  CUSTOMER_NUM = i_customer_num;

    SET o_status = CONCAT('Balance for ', v_name, ' changed by ', i_amount);
END //

DELIMITER ;

-- Check 67
-- Expected: STATUS = 'Balance for Access Pet Center changed by 250.00'. The four-row listing shows 1120 at 3762.50, 1225 at 1200.00, 1310 at 0.00, 1420 at 4820.75. The second STATUS = 'No customer numbered 9999 - nothing changed' and no row is modified, because the EXIT handler returns before the UPDATE. Run once against the shipped data; re-running the first CALL adds another 250.00, and the restore statement at the end of 8-6 puts 1120 back to 3512.50.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL UPD_CUST_BALANCE('1120', 250.00, @status);
SELECT @status AS STATUS;
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE FROM CUSTOMER ORDER BY CUSTOMER_NUM;

CALL UPD_CUST_BALANCE('9999', 250.00, @status);
SELECT @status AS STATUS;

-- Check 68
-- Expected: Query OK, 0 rows affected. Procedure SHIP_ITEM stored, with a compound SQLEXCEPTION handler that rolls back and a single-statement NOT FOUND handler. Declaration order (variable, then handlers, then statements) is required.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS SHIP_ITEM //

CREATE PROCEDURE SHIP_ITEM(
    IN  i_item_id     CHAR(4),
    IN  i_qty_shipped SMALLINT,
    OUT o_status      VARCHAR(60))
BEGIN
    DECLARE v_description VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET o_status = 'Shipment failed - stock left unchanged';
    END;

    DECLARE EXIT HANDLER FOR NOT FOUND
        SET o_status = CONCAT('No item numbered ', i_item_id);

    SELECT DESCRIPTION
    INTO   v_description
    FROM   ITEM
    WHERE  ITEM_ID = i_item_id;

    START TRANSACTION;

    UPDATE ITEM
    SET    ON_HAND = ON_HAND - i_qty_shipped
    WHERE  ITEM_ID = i_item_id;

    COMMIT;

    SET o_status = CONCAT('Shipped ', i_qty_shipped, ' of ', v_description);
END //

DELIMITER ;

-- Check 69
-- Expected: STATUS = 'Shipped 3 of Grain-Free Dry Food 30lb'; the ITEM row shows CF21 with ON_HAND = 45, down from the shipped value of 48. The second STATUS = 'No item numbered ZZ99' and no transaction is opened, because the NOT FOUND handler exits before START TRANSACTION. The restore statement at the end of 8-6 puts CF21 back to 48. Note that ON_HAND is a signed SMALLINT in the shipped schema, so an oversized shipment would go negative rather than raise ERROR 1264; that error requires SMALLINT UNSIGNED under strict SQL mode.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL SHIP_ITEM('CF21', 3, @status);
SELECT @status AS STATUS;
SELECT ITEM_ID, DESCRIPTION, ON_HAND FROM ITEM WHERE ITEM_ID = 'CF21';

CALL SHIP_ITEM('ZZ99', 1, @status);
SELECT @status AS STATUS;

-- Check 70
-- Expected: ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails, because invoices 50710, 50711, and 50712 reference customers 1120, 1420, and 1225. The statement is rolled back and no rows are deleted. Recorded only as the accident to avoid; requires the FK from INVOICE.CUSTOMER_NUM to CUSTOMER.
DELETE FROM CUSTOMER;

-- Check 71
-- Expected: Query OK, 0 rows affected. Procedure DEL_CUSTOMER stored with both a SQLEXCEPTION and a NOT FOUND handler; the two conditions cover different SQLSTATE classes (23 and 02), so they do not conflict. MySQL stores it with SQL SECURITY DEFINER by default.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS DEL_CUSTOMER //

CREATE PROCEDURE DEL_CUSTOMER(
    IN  i_customer_num CHAR(4),
    OUT o_status       VARCHAR(70))
BEGIN
    DECLARE v_name VARCHAR(35);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        SET o_status = CONCAT('Could not delete ', i_customer_num, ' - invoices still reference it');

    DECLARE EXIT HANDLER FOR NOT FOUND
        SET o_status = CONCAT('No customer numbered ', i_customer_num);

    SELECT CUSTOMER_NAME
    INTO   v_name
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    DELETE FROM CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    SET o_status = CONCAT('Deleted ', v_name);
END //

DELIMITER ;

-- Check 72
-- Expected: STATUS values in order: 'Deleted Companion Care Clinic'; 'Could not delete 1120 - invoices still reference it'; 'No customer numbered 9999'. The final listing returns three rows: 1120 Access Pet Center, 1225 Downtown Aquarium & Pets, 1420 Whiskers & Wags Boutique. It selects only CUSTOMER_NUM and CUSTOMER_NAME, so it is unaffected by the balance change made earlier by UPD_CUST_BALANCE. Requires the foreign key from INVOICE.CUSTOMER_NUM to CUSTOMER.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL DEL_CUSTOMER('1310', @status);
SELECT @status AS STATUS;

CALL DEL_CUSTOMER('1120', @status);
SELECT @status AS STATUS;

CALL DEL_CUSTOMER('9999', @status);
SELECT @status AS STATUS;

SELECT CUSTOMER_NUM, CUSTOMER_NAME FROM CUSTOMER ORDER BY CUSTOMER_NUM;

-- Check 73
-- Expected: Query OK, 1 row affected. Nine values for the nine CUSTOMER columns, restoring Companion Care Clinic exactly as shipped, so CUSTOMER holds four rows again.
INSERT INTO CUSTOMER
VALUES ('1310', 'Companion Care Clinic', '89 River Rd.', 'Maple Grove', 'OH',
        '44601', 0.00, 10000.00, '20');

-- Check 74
-- Expected: Query OK for each statement when run by an account holding CREATE USER and GRANT OPTION, against a schema actually named KIMTAY. The clerk can then CALL DEL_CUSTOMER and read CUSTOMER while holding no DELETE privilege on the table. This works because the procedure keeps MySQL's default SQL SECURITY DEFINER, so its DELETE runs on the definer's privileges; with SQL SECURITY INVOKER the clerk would need DELETE on CUSTOMER. GRANT and CREATE USER do not exist in SQLite.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE USER IF NOT EXISTS 'billing_clerk'@'localhost' IDENTIFIED BY 'change_me';
GRANT EXECUTE ON PROCEDURE KIMTAY.DEL_CUSTOMER TO 'billing_clerk'@'localhost';
GRANT SELECT ON KIMTAY.CUSTOMER TO 'billing_clerk'@'localhost';

-- Check 75
-- Expected: Rows matched: 1, Changed: 1 for each statement immediately after the 8-6 examples, restoring Access Pet Center to 3512.50 and CF21 to 48. Both assign an absolute value rather than adjusting, so running them a second time reports Rows matched: 1, Changed: 0 and the data still matches the shipped seed.
UPDATE CUSTOMER SET BALANCE = 3512.50 WHERE CUSTOMER_NUM = '1120';
UPDATE ITEM     SET ON_HAND = 48      WHERE ITEM_ID = 'CF21';

-- Check 76
-- Expected: Query OK, 0 rows affected for each statement, whether or not the procedure existed. All twelve procedures created in 8-4, 8-5, and 8-6 are named here, so afterward the INFORMATION_SCHEMA.ROUTINES query returns no rows for any of them.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DROP PROCEDURE IF EXISTS SHOW_REP_COUNT;
DROP PROCEDURE IF EXISTS BAD_REP_NAME;
DROP PROCEDURE IF EXISTS DISP_REP_NAME;
DROP PROCEDURE IF EXISTS GET_CREDIT_AVAILABLE;
DROP PROCEDURE IF EXISTS ADD_SALE_TO_COMMISSION;
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE_UNSAFE;
DROP PROCEDURE IF EXISTS STALE_DEMO;
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE;
DROP PROCEDURE IF EXISTS GET_BALANCE_BY_CITY;
DROP PROCEDURE IF EXISTS UPD_CUST_BALANCE;
DROP PROCEDURE IF EXISTS SHIP_ITEM;
DROP PROCEDURE IF EXISTS DEL_CUSTOMER;

-- ----------------------------------------------------------------------
-- Group m8c  --  21 checks
-- ----------------------------------------------------------------------


-- Check 77
-- Expected: Procedure-body fragment, not standalone. Inside a MySQL procedure with i_customer_num = '1120' it assigns v_balance = 3512.50 and v_credit_limit = 7500.00. Fails with ERROR 1172 if the WHERE clause ever matches more than one row.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SELECT BALANCE, CREDIT_LIMIT
    INTO v_balance, v_credit_limit
    FROM CUSTOMER
    WHERE CUSTOMER_NUM = i_customer_num;

-- Check 78
-- Expected: 2 rows: 1120|Access Pet Center|3512.5|7500 and 1310|Companion Care Clinic|0|10000. Executed in SQLite and verified; SQLite has no fixed DECIMAL display, so it renders 3512.5 rather than 3512.50 and 0 rather than 0.00. The values are the seeded ones.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- Check 79
-- Expected: Declaration fragment shown in stages; valid only inside a MySQL BEGIN block after the variable declarations. Defines the cursor and retrieves no rows.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DECLARE cust_cursor CURSOR FOR
    SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
    FROM CUSTOMER
    WHERE REP_NUM = i_rep_num
    ORDER BY CUSTOMER_NUM;

-- Check 80
-- Expected: Runs the cursor's SELECT and positions above the first row. No output. ERROR 1325 (Cursor is already open) if the cursor is already open.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
OPEN cust_cursor;

-- Check 81
-- Expected: Advances one row and assigns four variables. With rep 20 the first FETCH gives 1120 / Access Pet Center / 3512.50 / 7500.00. ERROR 1328 (Incorrect number of FETCH variables) if the variable count is not 4; ERROR 1326 if the cursor was never opened.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
FETCH cust_cursor INTO v_customer_num, v_customer_name,
                       v_balance, v_credit_limit;

-- Check 82
-- Expected: Loop skeleton fragment; valid inside a MySQL procedure between OPEN and CLOSE. With rep 20 it iterates twice and leaves on the third FETCH. No output on its own.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DECLARE v_done INT DEFAULT 0;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

cust_loop: LOOP
    FETCH cust_cursor INTO v_customer_num, v_customer_name,
                           v_balance, v_credit_limit;
    IF v_done = 1 THEN
        LEAVE cust_loop;
    END IF;

    -- work on the row that was retrieved goes here
END LOOP cust_loop;

-- Check 83
-- Expected: Releases the result set. No output. ERROR 1326 (Cursor is not open) if the cursor is not open.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CLOSE cust_cursor;

-- Check 84
-- Expected: Creates the empty 4-column report table. 0 rows affected. Shown as MySQL setup for the procedure, and the identical DDL also executes in SQLite, which is why the 8-7g sandbox can repeat it.
DROP TABLE IF EXISTS CUST_REVIEW;

CREATE TABLE CUST_REVIEW
    (CUSTOMER_NUM CHAR(4),
     CUSTOMER_NAME VARCHAR(35),
     AVAILABLE_CREDIT DECIMAL(9,2),
     REVIEW_NOTE VARCHAR(10));

-- Check 85
-- Expected: Stage 1. Creates the procedure successfully. Calling it opens and closes the cursor and produces no rows and no output.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS REP_CREDIT_REVIEW //

CREATE PROCEDURE REP_CREDIT_REVIEW (IN i_rep_num CHAR(2))
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_customer_num CHAR(4);
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_balance DECIMAL(9,2);
    DECLARE v_credit_limit DECIMAL(9,2);
    DECLARE v_available DECIMAL(9,2);
    DECLARE v_note VARCHAR(10);

    DECLARE cust_cursor CURSOR FOR
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
        FROM CUSTOMER
        WHERE REP_NUM = i_rep_num
        ORDER BY CUSTOMER_NUM;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN cust_cursor;
    CLOSE cust_cursor;
END //

DELIMITER ;

-- Check 86
-- Expected: Stage 2 fragment replacing the OPEN/CLOSE pair of stage 1. Inside the procedure it walks all matching rows and still produces no output; for rep 20 the loop body executes twice.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
OPEN cust_cursor;

    cust_loop: LOOP
        FETCH cust_cursor INTO v_customer_num, v_customer_name,
                               v_balance, v_credit_limit;
        IF v_done = 1 THEN
            LEAVE cust_loop;
        END IF;
    END LOOP cust_loop;

    CLOSE cust_cursor;

-- Check 87
-- Expected: Stage 3, the complete procedure. Creates successfully. Requires CUST_REVIEW to exist first.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

DROP PROCEDURE IF EXISTS REP_CREDIT_REVIEW //

CREATE PROCEDURE REP_CREDIT_REVIEW (IN i_rep_num CHAR(2))
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_customer_num CHAR(4);
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_balance DECIMAL(9,2);
    DECLARE v_credit_limit DECIMAL(9,2);
    DECLARE v_available DECIMAL(9,2);
    DECLARE v_note VARCHAR(10);

    DECLARE cust_cursor CURSOR FOR
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
        FROM CUSTOMER
        WHERE REP_NUM = i_rep_num
        ORDER BY CUSTOMER_NUM;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN cust_cursor;

    cust_loop: LOOP
        FETCH cust_cursor INTO v_customer_num, v_customer_name,
                               v_balance, v_credit_limit;
        IF v_done = 1 THEN
            LEAVE cust_loop;
        END IF;

        SET v_available = v_credit_limit - v_balance;

        IF v_available < 5000 THEN
            SET v_note = 'Call rep';
        ELSE
            SET v_note = 'No action';
        END IF;

        INSERT INTO CUST_REVIEW
               (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
        VALUES (v_customer_num, v_customer_name, v_available, v_note);
    END LOOP cust_loop;

    CLOSE cust_cursor;
END //

DELIMITER ;

-- Check 88
-- Expected: Inserts exactly 2 rows into CUST_REVIEW: (1120, Access Pet Center, 3987.50, 'Call rep') and (1310, Companion Care Clinic, 10000.00, 'No action'). Arithmetic verified against the seed data: 7500.00 - 3512.50 = 3987.50 and 10000.00 - 0.00 = 10000.00.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL REP_CREDIT_REVIEW('20');

-- Check 89
-- Expected: After CALL REP_CREDIT_REVIEW('20'): 2 rows, 1120|Access Pet Center|3987.50|Call rep and 1310|Companion Care Clinic|10000.00|No action. MySQL's DECIMAL(9,2) column keeps the two trailing decimals.
SELECT * FROM CUST_REVIEW
ORDER BY CUSTOMER_NUM;

-- Check 90
-- Expected: Declaration fragment inside a MySQL procedure. Four columns, so the FETCH needs four variables. With i_rep_num = '20' the cursor yields 2 rows (invoice 50710: Grain-Free Dry Food 30lb 127.50, Nylon Dog Leash 6ft 23.98). All four joined tables are required: dropping JOIN ITEM removes the only source of DESCRIPTION and the statement fails to prepare.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DECLARE line_cursor CURSOR FOR
    SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
           L.NUM_ORDERED * L.QUOTED_PRICE
    FROM CUSTOMER C
    JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
    JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
    JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
    WHERE C.REP_NUM = i_rep_num
    ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Check 91
-- Expected: 2 rows: Access Pet Center|50710|Grain-Free Dry Food 30lb|127.5 and Access Pet Center|50710|Nylon Dog Leash 6ft|23.98. Executed in SQLite and verified (127.5 is how SQLite renders 127.50).
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
       L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
WHERE C.REP_NUM = '20'
ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Check 92
-- Expected: The '65' variation of the same sandbox. 2 rows: Whiskers & Wags Boutique|50711|Grain-Free Dry Food 30lb|85.0 and Whiskers & Wags Boutique|50711|Small Animal Grooming Kit|15.25. Executed in SQLite and verified.
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
       L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
WHERE C.REP_NUM = '65'
ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Check 93
-- Expected: Creates BIG_LINE_LOG and the two-parameter procedure, then the CALL inserts exactly 1 row: Whiskers & Wags Boutique|50711|Grain-Free Dry Food 30lb|85.00. The underlying result set was executed in SQLite and verified against the seed data; rep 65's other line, Small Animal Grooming Kit at 15.25, is filtered out by the 50.00 minimum.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DROP TABLE IF EXISTS BIG_LINE_LOG;

CREATE TABLE BIG_LINE_LOG
    (CUSTOMER_NAME VARCHAR(35),
     INVOICE_NUM CHAR(5),
     DESCRIPTION VARCHAR(30),
     LINE_TOTAL DECIMAL(9,2));

DELIMITER //

DROP PROCEDURE IF EXISTS BIG_LINE_ITEMS //

CREATE PROCEDURE BIG_LINE_ITEMS (IN i_rep_num CHAR(2),
                                 IN i_min_total DECIMAL(7,2))
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_invoice_num CHAR(5);
    DECLARE v_description VARCHAR(30);
    DECLARE v_line_total DECIMAL(9,2);

    DECLARE line_cursor CURSOR FOR
        SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
               L.NUM_ORDERED * L.QUOTED_PRICE
        FROM CUSTOMER C
        JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
        JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
        JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
        WHERE C.REP_NUM = i_rep_num
          AND L.NUM_ORDERED * L.QUOTED_PRICE >= i_min_total
        ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN line_cursor;

    line_loop: LOOP
        FETCH line_cursor INTO v_customer_name, v_invoice_num,
                               v_description, v_line_total;
        IF v_done = 1 THEN
            LEAVE line_loop;
        END IF;

        INSERT INTO BIG_LINE_LOG
               (CUSTOMER_NAME, INVOICE_NUM, DESCRIPTION, LINE_TOTAL)
        VALUES (v_customer_name, v_invoice_num, v_description, v_line_total);
    END LOOP line_loop;

    CLOSE line_cursor;
END //

DELIMITER ;

CALL BIG_LINE_ITEMS('65', 50.00);

-- Check 94
-- Expected: 1 row: Whiskers & Wags Boutique|50711|Grain-Free Dry Food 30lb|85.0. Executed in SQLite and verified. Lowering 50 to 10 returns 2 rows, adding Small Animal Grooming Kit|15.25.
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
       L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
WHERE C.REP_NUM = '65'
  AND L.NUM_ORDERED * L.QUOTED_PRICE >= 50
ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Check 95
-- Expected: Declaration fragment inside a MySQL procedure. Yields 3 grouped rows, one per invoice, so a loop over it iterates 3 times.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DECLARE invoice_cursor CURSOR FOR
    SELECT I.INVOICE_NUM, C.CUSTOMER_NAME,
           SUM(L.NUM_ORDERED * L.QUOTED_PRICE)
    FROM INVOICE I
    JOIN CUSTOMER C ON I.CUSTOMER_NUM = C.CUSTOMER_NUM
    JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
    GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME
    ORDER BY I.INVOICE_NUM;

-- Check 96
-- Expected: 3 rows: 50710|Access Pet Center|151.48, 50711|Whiskers & Wags Boutique|100.25, 50712|Downtown Aquarium & Pets|120.49. Executed in SQLite and verified, including that the floating-point sums print exactly as shown.
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME,
       SUM(L.NUM_ORDERED * L.QUOTED_PRICE) AS INVOICE_TOTAL
FROM INVOICE I
JOIN CUSTOMER C ON I.CUSTOMER_NUM = C.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME
ORDER BY I.INVOICE_NUM;

-- Check 97
-- Expected: Final SELECT returns 2 rows: 1120|Access Pet Center|3987.5|Call rep and 1310|Companion Care Clinic|10000|No action, matching the cursor procedure's output. Executed end to end in SQLite and verified, including a second consecutive run, which succeeds because of the leading DROP TABLE IF EXISTS.
DROP TABLE IF EXISTS CUST_REVIEW;

CREATE TABLE CUST_REVIEW
    (CUSTOMER_NUM CHAR(4),
     CUSTOMER_NAME VARCHAR(35),
     AVAILABLE_CREDIT DECIMAL(9,2),
     REVIEW_NOTE VARCHAR(10));

INSERT INTO CUST_REVIEW
       (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE, 'Call rep'
FROM CUSTOMER
WHERE REP_NUM = '20' AND CREDIT_LIMIT - BALANCE < 5000;

INSERT INTO CUST_REVIEW
       (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE, 'No action'
FROM CUSTOMER
WHERE REP_NUM = '20' AND CREDIT_LIMIT - BALANCE >= 5000;

SELECT * FROM CUST_REVIEW ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Group m8d  --  37 checks
-- ----------------------------------------------------------------------


-- Check 98
-- Expected: Three result sets. First: 1 row, Downtown Aquarium & Pets | 1200. Second: 0 rows. Third: 2 rows, Access Pet Center | 3512.5 and Companion Care Clinic | 0. Verified; re-runnable with identical output.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1225';

SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1999';

SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20';

-- Check 99
-- Expected: 2 rows: 1120 | Access Pet Center | 3512.5 and 1310 | Companion Care Clinic | 0. Verified; re-runnable. Changing '20' to '65' returns exactly 1 row, 1420 | Whiskers & Wags Boutique | 4820.75.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- Check 100
-- Expected: 1 row: Whiskers & Wags Boutique | 4820.75. Verified; re-runnable.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1420';

-- Check 101
-- Expected: 1 row: 1225 | Downtown Aquarium & Pets | 1550 | 5000. The leading reset UPDATE makes the box idempotent; verified identical on a second run.
UPDATE CUSTOMER
SET BALANCE = 1200.00
WHERE CUSTOMER_NUM = '1225';

UPDATE CUSTOMER
SET BALANCE = BALANCE + 350.00
WHERE CUSTOMER_NUM = '1225';

SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1225';

-- Check 102
-- Expected: Two result sets. First: 1 row, 50710 | DG04 | 2. Second: 4 rows (AV07, CF21, FT88, GR15) with DG04 absent. CREATE TABLE ... AS SELECT copies no constraints, so the working copy has no foreign key. Verified; re-runnable because of DROP TABLE IF EXISTS.
SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED
FROM INVOICE_LINE
WHERE ITEM_ID = 'DG04';

DROP TABLE IF EXISTS ITEM_WORK;
CREATE TABLE ITEM_WORK AS SELECT * FROM ITEM;

DELETE FROM ITEM_WORK
WHERE ITEM_ID = 'DG04';

SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM_WORK
ORDER BY ITEM_ID;

-- Check 103
-- Expected: Fails with 'FOREIGN KEY constraint failed' because INVOICE_LINE row 50710/DG04 still references the item. Verified. Shown as a code block, not placed in a sandbox, because the error would replace all other output.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
PRAGMA foreign_keys = ON;

DELETE FROM ITEM
WHERE ITEM_ID = 'DG04';

-- Check 104
-- Expected: Two result sets. First: 2 rows, 50710 | Access Pet Center | Grain-Free Dry Food 30lb | 127.5 and 50710 | Access Pet Center | Nylon Dog Leash 6ft | 23.98. Second: 1 row, REP_TOTAL 151.48. Companion Care Clinic has no invoice and contributes nothing. Verified; re-runnable.
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION,
       IL.NUM_ORDERED * IL.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
     JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
     JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
     JOIN ITEM IT         ON IL.ITEM_ID = IT.ITEM_ID
WHERE C.REP_NUM = '20'
ORDER BY I.INVOICE_NUM, IT.DESCRIPTION;

SELECT SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS REP_TOTAL
FROM CUSTOMER C
     JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
     JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
WHERE C.REP_NUM = '20';

-- Check 105
-- Expected: 1 row: 1310 | Companion Care Clinic | (null). The null is produced by the outer join, not by the seed data, which has no missing values. Replacing IS NULL with = NULL returns 0 rows. Verified; backs review quiz question 3.
SELECT C.CUSTOMER_NUM, C.CUSTOMER_NAME, I.INVOICE_NUM
FROM CUSTOMER C
     LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
WHERE I.INVOICE_NUM IS NULL;

-- Check 106
-- Expected: 1 row: 1 | 50712 | GR15 | 4 | whatever date the box is run on. The trigger fires and writes the log row although the INSERT never names INVOICE_LINE_LOG. Verified; identical output on a second run thanks to the three housekeeping statements.
DROP TRIGGER IF EXISTS LOG_NEW_LINE;
DROP TABLE IF EXISTS INVOICE_LINE_LOG;
DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';

CREATE TABLE INVOICE_LINE_LOG (
    LOG_ID       INTEGER  PRIMARY KEY,
    INVOICE_NUM  CHAR(5),
    ITEM_ID      CHAR(4),
    NUM_ORDERED  SMALLINT,
    LOGGED_ON    DATE
);

CREATE TRIGGER LOG_NEW_LINE
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    INSERT INTO INVOICE_LINE_LOG (INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON)
    VALUES (NEW.INVOICE_NUM, NEW.ITEM_ID, NEW.NUM_ORDERED, DATE('now'));
END;

INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
VALUES ('50712', 'GR15', 4, 15.25);

SELECT LOG_ID, INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON
FROM INVOICE_LINE_LOG;

-- Check 107
-- Expected: Exactly 1 row: 1 | 1120 | 3512.5 | 3762.5. Two UPDATE statements run but the WHEN OLD.BALANCE <> NEW.BALANCE guard suppresses the no-change one. The reset UPDATE runs after the DROP TRIGGER, so it is never logged. Verified; re-runnable.
DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE;
DROP TABLE IF EXISTS BALANCE_LOG;
UPDATE CUSTOMER SET BALANCE = 3512.50 WHERE CUSTOMER_NUM = '1120';

CREATE TABLE BALANCE_LOG (
    LOG_ID        INTEGER  PRIMARY KEY,
    CUSTOMER_NUM  CHAR(4),
    OLD_BALANCE   DECIMAL(9,2),
    NEW_BALANCE   DECIMAL(9,2)
);

CREATE TRIGGER LOG_BALANCE_CHANGE
AFTER UPDATE OF BALANCE ON CUSTOMER
FOR EACH ROW
WHEN OLD.BALANCE <> NEW.BALANCE
BEGIN
    INSERT INTO BALANCE_LOG (CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE)
    VALUES (OLD.CUSTOMER_NUM, OLD.BALANCE, NEW.BALANCE);
END;

UPDATE CUSTOMER
SET BALANCE = BALANCE + 250.00
WHERE CUSTOMER_NUM = '1120';

UPDATE CUSTOMER
SET BALANCE = BALANCE
WHERE CUSTOMER_NUM = '1120';

SELECT LOG_ID, CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE
FROM BALANCE_LOG;

-- Check 108
-- Expected: 1 row: 1500 | Harbor Pet Supply | 9000. Verified; re-runnable. The ceiling is a strict > 10000, so seeded customer 1310 at exactly 10000.00 would also be accepted. Separately verified that changing 9000.00 to 15000.00 makes the statement fail with 'Credit limit over 10000 needs manager approval' and stores nothing.
DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
DELETE FROM CUSTOMER WHERE CUSTOMER_NUM = '1500';

CREATE TRIGGER CHECK_CREDIT_LIMIT
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
WHEN NEW.CREDIT_LIMIT > 10000
BEGIN
    SELECT RAISE(ABORT, 'Credit limit over 10000 needs manager approval');
END;

INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP,
                      BALANCE, CREDIT_LIMIT, REP_NUM)
VALUES ('1500', 'Harbor Pet Supply', '12 Dock St.', 'Northfield', 'OH', '44067',
        0.00, 9000.00, '35');

SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1500';

-- Check 109
-- Expected: 1 row: GR15 | Small Animal Grooming Kit | 18, down from the seeded 22. The INSERT names only INVOICE_LINE. Verified; the reset UPDATE keeps the answer at 18 on every re-run.
DROP TRIGGER IF EXISTS REDUCE_ON_HAND;
DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';
UPDATE ITEM SET ON_HAND = 22 WHERE ITEM_ID = 'GR15';

CREATE TRIGGER REDUCE_ON_HAND
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    UPDATE ITEM
    SET ON_HAND = ON_HAND - NEW.NUM_ORDERED
    WHERE ITEM_ID = NEW.ITEM_ID;
END;

INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
VALUES ('50712', 'GR15', 4, 15.25);

SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ITEM_ID = 'GR15';

-- Check 110
-- Expected: 1 row: LOG_NEW_LINE | trigger | INVOICE_LINE. The four leading drops clear every trigger the earlier boxes create, so the count is 1 whether or not the page shares one database across boxes. Verified; re-runnable. Separately verified that inserting DROP TRIGGER LOG_NEW_LINE; immediately above the SELECT leaves the catalog query returning 0 rows, and that placing it after the SELECT changes nothing visible.
DROP TRIGGER IF EXISTS LOG_NEW_LINE;
DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE;
DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
DROP TRIGGER IF EXISTS REDUCE_ON_HAND;

CREATE TRIGGER LOG_NEW_LINE
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    UPDATE ITEM SET ON_HAND = ON_HAND WHERE ITEM_ID = NEW.ITEM_ID;
END;

SELECT name, type, tbl_name
FROM sqlite_master
WHERE type = 'trigger';

-- Check 111
-- Expected: 1 row: 1 | L004 | 465. Run against the both_full seed; lease L004 exists and PAYMENT_ID 99 does not collide with the four seeded payments. Verified; re-runnable.
DROP TRIGGER IF EXISTS LOG_PAYMENT;
DROP TABLE IF EXISTS PAYMENT_LOG;
DELETE FROM PAYMENT WHERE PAYMENT_ID = 99;

CREATE TABLE PAYMENT_LOG (
    LOG_ID     INTEGER  PRIMARY KEY,
    LEASE_ID   CHAR(4),
    AMOUNT     DECIMAL(7,2),
    LOGGED_ON  DATE
);

CREATE TRIGGER LOG_PAYMENT
AFTER INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    INSERT INTO PAYMENT_LOG (LEASE_ID, AMOUNT, LOGGED_ON)
    VALUES (NEW.LEASE_ID, NEW.AMOUNT, DATE('now'));
END;

INSERT INTO PAYMENT (PAYMENT_ID, LEASE_ID, PAYMENT_DATE, AMOUNT)
VALUES (99, 'L004', '2026-09-01', 465.00);

SELECT LOG_ID, LEASE_ID, AMOUNT
FROM PAYMENT_LOG;

-- Check 112
-- Expected: 4 rows: 1120 | Access Pet Center | 3512.5 | 7500; 1225 | Downtown Aquarium & Pets | 1200 | 5000; 1310 | Companion Care Clinic | 0 | 10000; 1420 | Whiskers & Wags Boutique | 4820.75 | 6000. No column is empty. Run against the both_full seed. Verified.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- Check 113
-- Expected: Affects 2 rows: AV07 goes from 15 to 25 and FT88 from 30 to 40. Cited in 8-9e as the set-based replacement for the updatable cursor. Runs in the sandbox but is presented in prose rather than in a sandbox box.
UPDATE ITEM
SET ON_HAND = ON_HAND + 10
WHERE CATEGORY = 'Habitat';

-- Check 114
-- Expected: 0 rows. Verified against the seed data, which is why 8-9e uses CATEGORY = 'Habitat' rather than a below-reorder-level condition for the updatable cursor example.
SELECT ITEM_ID, DESCRIPTION, ON_HAND, REORDER_LEVEL
FROM ITEM
WHERE ON_HAND < REORDER_LEVEL;

-- Check 115
-- Expected: Creates the procedure. CALL GET_CUSTOMER('1225') returns one row: Downtown Aquarium & Pets | 1200.00. Restated in the lesson as the MySQL baseline for comparison. Not runnable in the page sandbox (SQLite has no CREATE PROCEDURE).
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //
CREATE PROCEDURE GET_CUSTOMER (IN I_CUSTOMER_NUM CHAR(4))
BEGIN
    DECLARE L_NAME    VARCHAR(35);
    DECLARE L_BALANCE DECIMAL(9,2);

    SELECT CUSTOMER_NAME, BALANCE
    INTO   L_NAME, L_BALANCE
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    SELECT L_NAME AS CUSTOMER_NAME, L_BALANCE AS BALANCE;
END //
DELIMITER ;

-- Check 116
-- Expected: One result row: CUSTOMER_NAME Downtown Aquarium & Pets, BALANCE 1200.00.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CALL GET_CUSTOMER('1225');

-- Check 117
-- Expected: Compiles. With SET SERVEROUTPUT ON, EXECUTE GET_CUSTOMER('1225') prints 'Downtown Aquarium & Pets 1200.00'; EXECUTE GET_CUSTOMER('1999') prints 'No customer numbered 1999'. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE OR REPLACE PROCEDURE GET_CUSTOMER (I_CUSTOMER_NUM IN CHAR) AS
    L_NAME     CUSTOMER.CUSTOMER_NAME%TYPE;
    L_BALANCE  CUSTOMER.BALANCE%TYPE;
BEGIN
    SELECT CUSTOMER_NAME, BALANCE
    INTO   L_NAME, L_BALANCE
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    DBMS_OUTPUT.PUT_LINE(L_NAME || '  ' || TO_CHAR(L_BALANCE, '99999.99'));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No customer numbered ' || I_CUSTOMER_NUM);
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('That condition matched more than one customer.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/

-- Check 118
-- Expected: Prints one buffered line: Downtown Aquarium & Pets followed by the formatted balance 1200.00.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
SET SERVEROUTPUT ON;
EXECUTE GET_CUSTOMER('1225');

-- Check 119
-- Expected: Compiles. EXECUTE ADD_TO_BALANCE('1225', 350) commits a balance of 1550.00. EXECUTE ADD_TO_BALANCE('1420', 2000) raises ORA-20002 and rolls back, leaving 4820.75 (4820.75 + 2000 = 6820.75 exceeds the 6000.00 limit). EXECUTE ADD_TO_BALANCE('1999', 10) raises ORA-20001. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE OR REPLACE PROCEDURE ADD_TO_BALANCE (
    I_CUSTOMER_NUM  IN CHAR,
    I_AMOUNT        IN NUMBER) AS
    OVER_LIMIT   EXCEPTION;
    L_BALANCE    CUSTOMER.BALANCE%TYPE;
    L_LIMIT      CUSTOMER.CREDIT_LIMIT%TYPE;
BEGIN
    UPDATE CUSTOMER
    SET    BALANCE = BALANCE + I_AMOUNT
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    SELECT BALANCE, CREDIT_LIMIT
    INTO   L_BALANCE, L_LIMIT
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    IF L_BALANCE > L_LIMIT THEN
        RAISE OVER_LIMIT;
    END IF;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001,
            'No customer numbered ' || I_CUSTOMER_NUM);
    WHEN OVER_LIMIT THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002,
            'That charge would push the balance past the credit limit.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, 'Unexpected error: ' || SQLERRM);
END;
/

-- Check 120
-- Expected: Compiles. EXECUTE REP_CUSTOMER_LIST('20') prints exactly two lines, '1120 Access Pet Center 3512.50' and '1310 Companion Care Clinic .00' (TO_CHAR with '99999.99' suppresses the leading zero). The underlying two-row result is verified in the sandbox. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE OR REPLACE PROCEDURE REP_CUSTOMER_LIST (I_REP_NUM IN CHAR) AS
    CURSOR CUSTGROUP IS
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
        FROM   CUSTOMER
        WHERE  REP_NUM = I_REP_NUM
        ORDER BY CUSTOMER_NUM;

    L_CUSTOMER_NUM   CUSTOMER.CUSTOMER_NUM%TYPE;
    L_CUSTOMER_NAME  CUSTOMER.CUSTOMER_NAME%TYPE;
    L_BALANCE        CUSTOMER.BALANCE%TYPE;
BEGIN
    OPEN CUSTGROUP;
    LOOP
        FETCH CUSTGROUP INTO L_CUSTOMER_NUM, L_CUSTOMER_NAME, L_BALANCE;
        EXIT WHEN CUSTGROUP%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(L_CUSTOMER_NUM || '  ' || L_CUSTOMER_NAME ||
                             '  ' || TO_CHAR(L_BALANCE, '99999.99'));
    END LOOP;
    CLOSE CUSTGROUP;
EXCEPTION
    WHEN OTHERS THEN
        IF CUSTGROUP%ISOPEN THEN
            CLOSE CUSTGROUP;
        END IF;
        RAISE_APPLICATION_ERROR(-20004, 'Listing failed: ' || SQLERRM);
END;
/

-- Check 121
-- Expected: Compiles. EXECUTE REP_CUSTOMER_LIST('20') prints '1120 Access Pet Center' and '1310 Companion Care Clinic'. Cursor FOR loop form; declares, opens, fetches, tests and closes implicitly. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE OR REPLACE PROCEDURE REP_CUSTOMER_LIST (I_REP_NUM IN CHAR) AS
BEGIN
    FOR C IN (SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
              FROM   CUSTOMER
              WHERE  REP_NUM = I_REP_NUM
              ORDER BY CUSTOMER_NUM)
    LOOP
        DBMS_OUTPUT.PUT_LINE(C.CUSTOMER_NUM || '  ' || C.CUSTOMER_NAME);
    END LOOP;
END;
/

-- Check 122
-- Expected: Compiles. Inserting ('50712','GR15',4,15.25) into INVOICE_LINE leaves ITEM.ON_HAND for GR15 at 18. Oracle spelling of the trigger verified in SQLite as the m8-10 side-effect sandbox; note the colons on :NEW. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE OR REPLACE TRIGGER REDUCE_ON_HAND
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    UPDATE ITEM
    SET ON_HAND = ON_HAND - :NEW.NUM_ORDERED
    WHERE ITEM_ID = :NEW.ITEM_ID;
END;
/

-- Check 123
-- Expected: Creates the trigger. Inserting ('50712','GR15',4,15.25) into INVOICE_LINE leaves ITEM.ON_HAND for GR15 at 18. MySQL spelling; identical body to the verified SQLite version apart from the DELIMITER wrapper. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //
CREATE TRIGGER REDUCE_ON_HAND
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    UPDATE ITEM
    SET ON_HAND = ON_HAND - NEW.NUM_ORDERED
    WHERE ITEM_ID = NEW.ITEM_ID;
END //
DELIMITER ;

-- Check 124
-- Expected: Creates the procedure. EXEC GET_CUSTOMER '1420' prints 'Whiskers & Wags Boutique 4820.75'; EXEC GET_CUSTOMER '1999' prints 'No customer numbered 1999'; a parameter matching two rows prints the multi-row message. @@ROWCOUNT is captured into @L_ROWS on the statement immediately after the assignment SELECT: written as IF @@ROWCOUNT = 0 ... ELSE IF @@ROWCOUNT > 1, the second test would read the count left by the first IF and the multi-row branch could never fire. The underlying single-row query is verified in the sandbox. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE PROCEDURE GET_CUSTOMER
    @I_CUSTOMER_NUM CHAR(4)
AS
DECLARE @L_NAME    VARCHAR(35);
DECLARE @L_BALANCE DECIMAL(9,2);
DECLARE @L_ROWS    INT;

SELECT @L_NAME    = CUSTOMER_NAME,
       @L_BALANCE = BALANCE
FROM   CUSTOMER
WHERE  CUSTOMER_NUM = @I_CUSTOMER_NUM;

SET @L_ROWS = @@ROWCOUNT;

IF @L_ROWS = 0
    PRINT 'No customer numbered ' + @I_CUSTOMER_NUM;
ELSE IF @L_ROWS > 1
    PRINT 'That condition matched more than one customer.';
ELSE
    PRINT @L_NAME + '  ' + CAST(@L_BALANCE AS VARCHAR(20));
GO

-- Check 125
-- Expected: Prints one line: Whiskers & Wags Boutique followed by 4820.75.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
EXEC GET_CUSTOMER '1420';

-- Check 126
-- Expected: Creates the procedure. @@ROWCOUNT is read once, on the statement immediately after the UPDATE, so no variable is needed. EXEC ADD_TO_BALANCE '1225', 350.00 commits and leaves BALANCE at 1550.00 (verified in the sandbox as a plain UPDATE). EXEC ADD_TO_BALANCE '1999', 350.00 throws 50001, rolls back, and prints the caught message. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE PROCEDURE ADD_TO_BALANCE
    @I_CUSTOMER_NUM CHAR(4),
    @I_AMOUNT       DECIMAL(9,2)
AS
BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE CUSTOMER
    SET    BALANCE = BALANCE + @I_AMOUNT
    WHERE  CUSTOMER_NUM = @I_CUSTOMER_NUM;

    IF @@ROWCOUNT = 0
        THROW 50001, 'No customer with that number. Nothing was changed.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT 'ADD_TO_BALANCE failed: ' + ERROR_MESSAGE();
END CATCH;
GO

-- Check 127
-- Expected: Commits; CUSTOMER 1225 BALANCE becomes 1550.00 against a CREDIT_LIMIT of 5000.00. Nothing is printed on success.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
EXEC ADD_TO_BALANCE '1225', 350.00;

-- Check 128
-- Expected: Creates the procedure. EXEC DELETE_ITEM 'DG04' fails the INVOICE_LINE foreign key (row 50710/DG04 verified present in the sandbox) and CATCH prints the message. EXEC DELETE_ITEM 'ZZ99' affects 0 rows and prints 'No item numbered ZZ99. Nothing was deleted.' Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE PROCEDURE DELETE_ITEM
    @I_ITEM_ID CHAR(4)
AS
BEGIN TRY
    DELETE FROM ITEM
    WHERE  ITEM_ID = @I_ITEM_ID;

    IF @@ROWCOUNT = 0
        PRINT 'No item numbered ' + @I_ITEM_ID + '. Nothing was deleted.';
    ELSE
        PRINT 'Item ' + @I_ITEM_ID + ' deleted.';
END TRY
BEGIN CATCH
    PRINT 'Could not delete ' + @I_ITEM_ID + ': ' + ERROR_MESSAGE();
END CATCH;
GO

-- Check 129
-- Expected: Prints 'Could not delete DG04: ' followed by the foreign key error text. ITEM still holds all five rows.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
EXEC DELETE_ITEM 'DG04';

-- Check 130
-- Expected: Creates the procedure. EXEC REP_CUSTOMER_LIST '20' prints exactly two lines: '1120 Access Pet Center 3512.50' and '1310 Companion Care Clinic 0.00'. The two-row driving query is verified in the sandbox. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE PROCEDURE REP_CUSTOMER_LIST
    @I_REP_NUM CHAR(2)
AS
DECLARE @L_CUSTOMER_NUM  CHAR(4);
DECLARE @L_CUSTOMER_NAME VARCHAR(35);
DECLARE @L_BALANCE       DECIMAL(9,2);

DECLARE CUSTGROUP CURSOR FOR
    SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
    FROM   CUSTOMER
    WHERE  REP_NUM = @I_REP_NUM
    ORDER BY CUSTOMER_NUM;

OPEN CUSTGROUP;

FETCH NEXT FROM CUSTGROUP
    INTO @L_CUSTOMER_NUM, @L_CUSTOMER_NAME, @L_BALANCE;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @L_CUSTOMER_NUM + '  ' + @L_CUSTOMER_NAME + '  ' +
          CAST(@L_BALANCE AS VARCHAR(20));

    FETCH NEXT FROM CUSTGROUP
        INTO @L_CUSTOMER_NUM, @L_CUSTOMER_NAME, @L_BALANCE;
END

CLOSE CUSTGROUP;
DEALLOCATE CUSTGROUP;
GO

-- Check 131
-- Expected: Creates the procedure. EXEC REP_INVOICE_LINES '20' prints two detail lines (50710 Access Pet Center Grain-Free Dry Food 30lb 127.50, and 50710 Access Pet Center Nylon Dog Leash 6ft 23.98) then 'Total for rep 20: 151.48'. Both the detail rows and the 151.48 total are verified in the sandbox. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE PROCEDURE REP_INVOICE_LINES
    @I_REP_NUM CHAR(2)
AS
DECLARE @L_INVOICE_NUM   CHAR(5);
DECLARE @L_CUSTOMER_NAME VARCHAR(35);
DECLARE @L_DESCRIPTION   VARCHAR(30);
DECLARE @L_LINE_TOTAL    DECIMAL(9,2);
DECLARE @L_RUNNING_TOTAL DECIMAL(9,2) = 0;

DECLARE LINEGROUP CURSOR FOR
    SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION,
           IL.NUM_ORDERED * IL.QUOTED_PRICE
    FROM   CUSTOMER C
           JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
           JOIN INVOICE_LINE IL ON I.INVOICE_NUM  = IL.INVOICE_NUM
           JOIN ITEM IT         ON IL.ITEM_ID     = IT.ITEM_ID
    WHERE  C.REP_NUM = @I_REP_NUM
    ORDER BY I.INVOICE_NUM, IT.DESCRIPTION;

OPEN LINEGROUP;

FETCH NEXT FROM LINEGROUP
    INTO @L_INVOICE_NUM, @L_CUSTOMER_NAME, @L_DESCRIPTION, @L_LINE_TOTAL;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @L_RUNNING_TOTAL = @L_RUNNING_TOTAL + @L_LINE_TOTAL;

    PRINT @L_INVOICE_NUM + '  ' + @L_CUSTOMER_NAME + '  ' +
          @L_DESCRIPTION + '  ' + CAST(@L_LINE_TOTAL AS VARCHAR(20));

    FETCH NEXT FROM LINEGROUP
        INTO @L_INVOICE_NUM, @L_CUSTOMER_NAME, @L_DESCRIPTION, @L_LINE_TOTAL;
END

CLOSE LINEGROUP;
DEALLOCATE LINEGROUP;

PRINT 'Total for rep ' + @I_REP_NUM + ': ' +
      CAST(@L_RUNNING_TOTAL AS VARCHAR(20));
GO

-- Check 132
-- Expected: Visits the two Habitat items and leaves AV07 at 25 (from 15) and FT88 at 40 (from 30). The two-row membership of the Habitat category is verified against the seed data. Equivalent to the single statement UPDATE ITEM SET ON_HAND = ON_HAND + 10 WHERE CATEGORY = 'Habitat'. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DECLARE @L_ITEM_ID CHAR(4);
DECLARE @L_ON_HAND SMALLINT;

DECLARE ITEMGROUP CURSOR FOR
    SELECT ITEM_ID, ON_HAND
    FROM   ITEM
    WHERE  CATEGORY = 'Habitat'
    FOR UPDATE OF ON_HAND;

OPEN ITEMGROUP;
FETCH NEXT FROM ITEMGROUP INTO @L_ITEM_ID, @L_ON_HAND;

WHILE @@FETCH_STATUS = 0
BEGIN
    UPDATE ITEM
    SET    ON_HAND = ON_HAND + 10
    WHERE  CURRENT OF ITEMGROUP;

    FETCH NEXT FROM ITEMGROUP INTO @L_ITEM_ID, @L_ON_HAND;
END

CLOSE ITEMGROUP;
DEALLOCATE ITEMGROUP;

-- Check 133
-- Expected: Creates the trigger. Fires once per statement, not per row. Inserting ('50712','GR15',4,15.25) leaves GR15 ON_HAND at 18, matching the verified SQLite result, and a multi-row insert touching the same item is handled correctly because inserted is aggregated first. Referenced by exercise 7. Not runnable in the page sandbox.
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
CREATE TRIGGER REDUCE_ON_HAND
ON INVOICE_LINE
AFTER INSERT
AS
UPDATE ITEM
SET    ON_HAND = ITEM.ON_HAND - T.QTY
FROM   ITEM
       JOIN (SELECT ITEM_ID, SUM(NUM_ORDERED) AS QTY
             FROM   inserted
             GROUP BY ITEM_ID) T
         ON ITEM.ITEM_ID = T.ITEM_ID;
GO

-- Check 134
-- Expected: Removes the trigger. In the sandbox, a following SELECT name FROM sqlite_master WHERE type = 'trigger' returns 0 rows. Verified. The order matters: the drop has to precede the catalog query for the empty listing to be visible.
DROP TRIGGER LOG_NEW_LINE;
