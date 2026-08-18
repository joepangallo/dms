-- ======================================================================
-- Module 8 · Solutions to the sandbox exercises
-- ======================================================================
--
-- One entry per exercise, in the same order as the numbered lesson files.
-- Each shows the starter the student begins from and the finished query,
-- with the line-by-line commentary the page carries.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Exercise 1  --  section 8-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Nothing new here. Read the two rows that come back and notice that they are ordinary result rows, not anything special because a program asked for them.

-- Starter:
--   -- The statement a program sends when a clerk picks rep 20.
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE REP_NUM = '20'
--   ORDER BY CUSTOMER_NUM;

-- Solution:
-- The SELECT a stored procedure would wrap. Nothing about it changes because it
-- lives inside a procedure - only where the text is kept changes.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
-- In the procedure this literal is replaced by a parameter, which is the whole
-- point: one stored query answering the question for any rep.
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 2  --  section 8-1  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: One row comes back: CF21, 42.5, 44. The UPDATE at the bottom never mentions PRICE_LOG, yet the row is there, because OLD and NEW inside the trigger are the row before and after the change. The reset UPDATE near the top runs before the trigger exists, so it logs nothing and simply guarantees the same answer on a second Run.

-- Starter:
--   DROP TRIGGER IF EXISTS LOG_PRICE_CHANGE;
--   DROP TABLE IF EXISTS PRICE_LOG;
--
--   -- Put CF21 back at its seeded price. The sandbox keeps whatever you did
--   -- last time until you press Reset, so this line is what makes the box
--   -- give the same answer on every Run.
--   UPDATE ITEM SET PRICE = 42.50 WHERE ITEM_ID = 'CF21';
--
--   CREATE TABLE PRICE_LOG (
--       ITEM_ID    CHAR(4),
--       OLD_PRICE  DECIMAL(7,2),
--       NEW_PRICE  DECIMAL(7,2),
--       CHANGED_ON DATE
--   );
--
--   CREATE TRIGGER LOG_PRICE_CHANGE
--   AFTER UPDATE OF PRICE ON ITEM
--   BEGIN
--       INSERT INTO PRICE_LOG
--       VALUES (OLD.ITEM_ID, OLD.PRICE, NEW.PRICE, DATE('now'));
--   END;
--
--   -- A plain UPDATE. It says nothing about logging.
--   UPDATE ITEM SET PRICE = 44.00 WHERE ITEM_ID = 'CF21';
--
--   SELECT ITEM_ID, OLD_PRICE, NEW_PRICE FROM PRICE_LOG;

-- Solution:
-- Housekeeping, so the box can be run more than once.
DROP TRIGGER IF EXISTS LOG_PRICE_CHANGE;
DROP TABLE IF EXISTS PRICE_LOG;

-- Put the seeded price back, so the change below is always the same size.
UPDATE ITEM SET PRICE = 42.50 WHERE ITEM_ID = 'CF21';

-- The audit table. Nothing ever writes to it by hand.
CREATE TABLE PRICE_LOG (
    ITEM_ID    CHAR(4),
    OLD_PRICE  DECIMAL(7,2),
    NEW_PRICE  DECIMAL(7,2),
    CHANGED_ON DATE
);

-- CREATE TRIGGER: code the database runs BY ITSELF when something happens.
CREATE TRIGGER LOG_PRICE_CHANGE
-- AFTER UPDATE OF PRICE ON ITEM: the event. It fires only when that one column
-- is updated on that one table, and only after the change has succeeded.
AFTER UPDATE OF PRICE ON ITEM
-- BEGIN ... END wraps the body, exactly as in a stored procedure.
BEGIN
    INSERT INTO PRICE_LOG
    -- OLD and NEW are supplied by the trigger: the row as it was, and as it now
    -- is. They are the reason a trigger can record what changed.
    VALUES (OLD.ITEM_ID, OLD.PRICE, NEW.PRICE, DATE('now'));
END;

-- One ordinary UPDATE. Nothing here mentions PRICE_LOG at all.
UPDATE ITEM SET PRICE = 44.00 WHERE ITEM_ID = 'CF21';

-- And yet the log has a row: the trigger ran on its own. That is the point, and
-- also the danger - work happens that the statement does not show.
SELECT ITEM_ID, OLD_PRICE, NEW_PRICE FROM PRICE_LOG;

-- ----------------------------------------------------------------------
-- Exercise 3  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Wrap the column in the function and give the result a column name with AS. Access Pet Center becomes ACCESS PET CENTER, and Maple Grove becomes maple grove.

-- Starter:
--   -- Add an upper case name column and a lower case city column.
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
--   FROM CUSTOMER
--   ORDER BY CUSTOMER_NUM;

-- Solution:
-- UPPER and LOWER are ROW functions: they run once per row, so five rows in
-- means five rows out. Compare that with an aggregate, which returns one row.
SELECT CUSTOMER_NUM,
       UPPER(CUSTOMER_NAME) AS UPPER_NAME,
       -- The stored value is untouched; only the output is changed.
       LOWER(CITY) AS LOWER_CITY
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 4  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Put both sides of the comparison in the same case: UPPER(CITY) on the left, a fully capitalized literal on the right. Capitalizing only one side still matches nothing. You should get customers 1120 and 1310.

-- Starter:
--   -- Run this first. It matches nothing. Then fix it with UPPER.
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
--   FROM CUSTOMER
--   WHERE CITY = 'maple grove'
--   ORDER BY CUSTOMER_NUM;

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
-- Applying UPPER to the COLUMN makes the comparison case-insensitive, so
-- 'Maple Grove' and 'MAPLE GROVE' both match. The cost is that the engine must
-- compute the function for every row before it can compare, which stops any
-- index on CITY from being used.
WHERE UPPER(CITY) = 'MAPLE GROVE'
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 5  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: SUBSTR(ITEM_ID, 1, 2) starts at character 1 and takes 2. AV07 gives AV. LENGTH('Aviary Starter Cage') is 19.

-- Starter:
--   -- Add the two-letter prefix of ITEM_ID and the length of DESCRIPTION.
--   SELECT ITEM_ID, DESCRIPTION
--   FROM ITEM
--   ORDER BY ITEM_ID;

-- Solution:
SELECT ITEM_ID,
       -- SUBSTR(value, start, length): start counts from 1, not 0, so this takes
       -- the first two characters.
       SUBSTR(ITEM_ID, 1, 2) AS PREFIX,
       -- LENGTH counts characters in the value, ignoring the column's declared width.
       LENGTH(DESCRIPTION) AS NAME_LENGTH
FROM ITEM
ORDER BY ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 6  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two rows come back: CF21 at 24 characters and GR15 at 25. Change 20 to 19 and FT88, at exactly 20, joins them.

-- Starter:
--   -- Which item descriptions are longer than 20 characters?
--   SELECT ITEM_ID, DESCRIPTION, LENGTH(DESCRIPTION) AS NAME_LENGTH
--   FROM ITEM
--   WHERE LENGTH(DESCRIPTION) > 20
--   ORDER BY ITEM_ID;

-- Solution:
SELECT ITEM_ID, DESCRIPTION, LENGTH(DESCRIPTION) AS NAME_LENGTH
FROM ITEM
-- A function is legal in a WHERE clause as long as it is a ROW function - it
-- produces one value per row, so the condition can be tested row by row. An
-- aggregate here would be an error, because it needs the whole table first.
WHERE LENGTH(DESCRIPTION) > 20
ORDER BY ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 7  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The brackets make the blanks visible. 15 characters before, 11 after. The space between Maple and Grove survives, because TRIM only touches the ends.

-- Starter:
--   SELECT '[' || '  Maple Grove  ' || ']' AS RAW_VALUE,
--          '[' || TRIM('  Maple Grove  ') || ']' AS TRIMMED_VALUE,
--          LENGTH('  Maple Grove  ') AS BEFORE_LEN,
--          LENGTH(TRIM('  Maple Grove  ')) AS AFTER_LEN;

-- Solution:
-- Square brackets are just text, added so the spaces are visible on screen.
SELECT '[' || '  Maple Grove  ' || ']' AS RAW_VALUE,
       -- TRIM removes leading and trailing spaces, never the ones in the middle.
       '[' || TRIM('  Maple Grove  ') || ']' AS TRIMMED_VALUE,
       -- The two lengths are the proof: the spaces really were part of the value.
       LENGTH('  Maple Grove  ') AS BEFORE_LEN,
       LENGTH(TRIM('  Maple Grove  ')) AS AFTER_LEN;

-- ----------------------------------------------------------------------
-- Exercise 8  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Take one character from each name and join them with ||, then wrap SUBSTR(LAST_NAME, 1, 3) in UPPER. Rep 20 gives VK and KAI.

-- Starter:
--   -- Build INITIALS (first letter of each name) and CODE (first three
--   -- letters of the last name, in capitals).
--   SELECT REP_NUM, FIRST_NAME, LAST_NAME
--   FROM REP
--   ORDER BY REP_NUM;

-- Solution:
SELECT REP_NUM,
       -- Functions nest: SUBSTR takes the first letter of each name, and || glues
       -- the two results together into a pair of initials.
       SUBSTR(FIRST_NAME, 1, 1) || SUBSTR(LAST_NAME, 1, 1) AS INITIALS,
       -- Nested the other way round: take three characters, then upper-case the
       -- result. The inner function always runs first.
       UPPER(SUBSTR(LAST_NAME, 1, 3)) AS CODE
FROM REP
ORDER BY REP_NUM;

-- ----------------------------------------------------------------------
-- Exercise 9  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Rep 35 is the one that matters. 39355 times 0.07 comes back as 2754.8500000000004, which is binary floating point showing through, and ROUND(COMMISSION * RATE, 2) reports it as 2754.85. Reps 20 and 65 were already clean at 1078 and 1188.2.

-- Starter:
--   -- Add RAW_PAYOUT (COMMISSION * RATE) and PAYOUT (the same product
--   -- rounded to cents). Compare the two columns on rep 35.
--   SELECT REP_NUM, COMMISSION, RATE
--   FROM REP
--   ORDER BY REP_NUM;

-- Solution:
SELECT REP_NUM, COMMISSION, RATE,
       -- The raw multiplication, showing every decimal place the engine produced.
       COMMISSION * RATE AS RAW_PAYOUT,
       -- ROUND(value, 2) cuts it to two decimals. Rounding at the point of
       -- DISPLAY is right; rounding money before you finish calculating is not.
       ROUND(COMMISSION * RATE, 2) AS PAYOUT
FROM REP
ORDER BY REP_NUM;

-- ----------------------------------------------------------------------
-- Exercise 10  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Invoice 50710 has two lines: 3 at 42.50 is 127.5, and 2 at 11.99 is 23.98. Whole amounts print without a trailing zero, so 2 at 42.50 on invoice 50711 shows as 85.

-- Starter:
--   -- Add LINE_TOTAL: NUM_ORDERED * QUOTED_PRICE, rounded to cents.
--   SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE
--   FROM INVOICE_LINE
--   ORDER BY INVOICE_NUM, ITEM_ID;

-- Solution:
SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE,
       -- The line total, computed per row and rounded to money.
       ROUND(NUM_ORDERED * QUOTED_PRICE, 2) AS LINE_TOTAL
FROM INVOICE_LINE
ORDER BY INVOICE_NUM, ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 11  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Customer 1120 shows -3987.5 and 3987.5. Companion Care Clinic, with a zero balance, shows the widest gap at 10000.

-- Starter:
--   -- Add the raw difference and its absolute value.
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
--   FROM CUSTOMER
--   ORDER BY CUSTOMER_NUM;

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME,
       -- The signed difference: negative for a customer who is under their limit.
       BALANCE - CREDIT_LIMIT AS DIFF,
       -- ABS drops the sign, giving the SIZE of the gap regardless of direction.
       -- Useful when you care how far apart two numbers are, not which is bigger.
       ABS(BALANCE - CREDIT_LIMIT) AS GAP
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 12  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Companion Care Clinic leads at 10000, and Whiskers and Wags Boutique trails at 1179.25.

-- Starter:
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME,
--          ABS(CREDIT_LIMIT - BALANCE) AS AVAILABLE
--   FROM CUSTOMER
--   ORDER BY ABS(CREDIT_LIMIT - BALANCE) DESC;

-- Solution:
SELECT CUSTOMER_NUM, CUSTOMER_NAME,
       ABS(CREDIT_LIMIT - BALANCE) AS AVAILABLE
FROM CUSTOMER
-- The expression is repeated here rather than reusing the alias. ORDER BY does
-- accept an alias, so ORDER BY AVAILABLE DESC would work too and read better.
ORDER BY ABS(CREDIT_LIMIT - BALANCE) DESC;

-- ----------------------------------------------------------------------
-- Exercise 13  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: AV07 at 64.99 rounds to 65 but chops to 64. GR15 at 15.25 gives 15 either way. If a report must never overstate a price, those two columns are not interchangeable.

-- Starter:
--   SELECT ITEM_ID, PRICE,
--          ROUND(PRICE, 0) AS ROUNDED,
--          CAST(PRICE AS INTEGER) AS CHOPPED
--   FROM ITEM
--   ORDER BY ITEM_ID;

-- Solution:
SELECT ITEM_ID, PRICE,
       -- ROUND goes to the NEAREST whole number, so 64.99 becomes 65.
       ROUND(PRICE, 0) AS ROUNDED,
       -- CAST to INTEGER simply CHOPS the decimal part off, so 64.99 becomes 64.
       -- Two different answers from the same value - pick deliberately.
       CAST(PRICE AS INTEGER) AS CHOPPED
FROM ITEM
ORDER BY ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 14  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: One row, two columns. TODAY is a plain YYYY-MM-DD value; RIGHT_NOW carries hours, minutes and seconds as well. The values change every time you run it.

-- Starter:
--   SELECT DATE('now') AS TODAY,
--          DATETIME('now') AS RIGHT_NOW;

-- Solution:
-- No FROM clause at all: these functions ask the server about itself, so there
-- is no table to read.
SELECT DATE('now') AS TODAY,
       -- DATETIME adds the time of day. DATE gives the calendar date alone.
       DATETIME('now') AS RIGHT_NOW;

-- ----------------------------------------------------------------------
-- Exercise 15  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: All three KimTay invoices land in 2026, month 06, period 2026-06. The month comes back as the text 06, with the leading zero kept.

-- Starter:
--   -- Add the year, the month, and a combined YYYY-MM period column.
--   SELECT INVOICE_NUM, INVOICE_DATE
--   FROM INVOICE
--   ORDER BY INVOICE_NUM;

-- Solution:
SELECT INVOICE_NUM, INVOICE_DATE,
       -- strftime pulls a piece out of a date. %Y is the four-digit year.
       strftime('%Y', INVOICE_DATE) AS INVOICE_YEAR,
       -- %m is the two-digit month.
       strftime('%m', INVOICE_DATE) AS INVOICE_MONTH,
       -- Combining them gives a period label to group monthly reports by.
       strftime('%Y-%m', INVOICE_DATE) AS PERIOD
FROM INVOICE
ORDER BY INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Exercise 16  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Change '+15 days' to '+30 days'. Invoice 50710, dated 2026-06-14, is then due 2026-07-14, and 50712 is due 2026-07-15.

-- Starter:
--   -- KimTay's terms are net 30, not net 15. Fix the modifier.
--   SELECT INVOICE_NUM, INVOICE_DATE,
--          DATE(INVOICE_DATE, '+15 days') AS DUE_DATE
--   FROM INVOICE
--   ORDER BY INVOICE_NUM;

-- Solution:
SELECT INVOICE_NUM, INVOICE_DATE,
       -- DATE(value, modifier) shifts a date. The engine handles month ends and
       -- leap years, which is exactly why you never do this arithmetic by hand.
       DATE(INVOICE_DATE, '+30 days') AS DUE_DATE
FROM INVOICE
ORDER BY INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Exercise 17  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The raw numbers are around 2461205.5, which is meaningless on its own and exactly right as a difference. Subtract the invoice date from '2026-07-01' to get 17, 17 and 16 days.

-- Starter:
--   -- Step 1: see the raw day numbers.
--   SELECT INVOICE_NUM, INVOICE_DATE,
--          julianday(INVOICE_DATE) AS JULIAN
--   FROM INVOICE
--   ORDER BY INVOICE_NUM;

-- Solution:
SELECT INVOICE_NUM, INVOICE_DATE,
       -- julianday turns a date into a single number of days, so subtracting two
       -- of them gives the days between. A fixed date is used here so the answer
       -- is the same whenever the query is run.
       julianday('2026-07-01') - julianday(INVOICE_DATE) AS DAYS_OLD
FROM INVOICE
ORDER BY INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Exercise 18  --  section 8-2  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: RAW_DAYS comes back with a long fraction, because 'now' includes the clock time. DAYS_OLD is the same value with the fraction thrown away. Both columns grow by one every day, so your numbers will be larger than a classmate's from last week. Swap 'now' for '2026-07-01' and the fraction disappears.

-- Starter:
--   -- Age each invoice against right now instead of a fixed date.
--   SELECT INVOICE_NUM, INVOICE_DATE,
--          julianday('now') - julianday(INVOICE_DATE) AS RAW_DAYS,
--          CAST(julianday('now') - julianday(INVOICE_DATE) AS INTEGER) AS DAYS_OLD
--   FROM INVOICE
--   ORDER BY INVOICE_NUM;

-- Solution:
SELECT INVOICE_NUM, INVOICE_DATE,
       -- Against 'now' the result carries a fraction, because now includes a time
       -- of day and midnight on the invoice date does not.
       julianday('now') - julianday(INVOICE_DATE) AS RAW_DAYS,
       -- CAST to INTEGER chops that fraction off, giving whole days elapsed.
       CAST(julianday('now') - julianday(INVOICE_DATE) AS INTEGER) AS DAYS_OLD
FROM INVOICE
ORDER BY INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Exercise 19  --  section 8-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: A space is a value like any other. Pass ' ' as a middle argument: CONCAT(FIRST_NAME, ' ', LAST_NAME).

-- Starter:
--   -- Valerie Kaiser comes back as ValerieKaiser. Add the missing space.
--   SELECT REP_NUM,
--          CONCAT(FIRST_NAME, LAST_NAME) AS FULL_NAME
--   FROM REP
--   ORDER BY REP_NUM;

-- Solution:
SELECT REP_NUM,
       -- CONCAT takes the pieces as arguments. It is the MySQL spelling, and
       -- SQLite has accepted it since version 3.44.
       CONCAT(FIRST_NAME, ' ', LAST_NAME) AS FULL_NAME
FROM REP
ORDER BY REP_NUM;

-- ----------------------------------------------------------------------
-- Exercise 20  --  section 8-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Chain the operator: column, separator, column, separator, column. The comma and the spaces are literals in quotes. Reps 20 and 35 both give Maple Grove, OH 44601.

-- Starter:
--   -- Build MAILING_LINE in the form: Maple Grove, OH 44601
--   SELECT REP_NUM, CITY, STATE, ZIP
--   FROM REP
--   ORDER BY REP_NUM;

-- Solution:
SELECT REP_NUM,
       -- || is the STANDARD SQL concatenation operator, used between the pieces
       -- rather than around them. SQLite and Oracle both accept it; MySQL does
       -- not, which makes string joining one of the least portable corners of SQL.
       CITY || ', ' || STATE || ' ' || ZIP AS MAILING_LINE
FROM REP
ORDER BY REP_NUM;

-- ----------------------------------------------------------------------
-- Exercise 21  --  section 8-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Nine arguments in all: the five columns and the four separators between them. Watch the comma after the street but the plain space before the state.

-- Starter:
--   -- Build a one-line mailing label per customer:
--   -- Access Pet Center, 215 Foster Ave., Maple Grove OH 44601
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP
--   FROM CUSTOMER
--   ORDER BY CUSTOMER_NUM;

-- Solution:
SELECT CUSTOMER_NUM,
       -- One CONCAT call can take as many arguments as you need. The literal
       -- commas and spaces are supplied as their own arguments.
       CONCAT(CUSTOMER_NAME, ', ', STREET, ', ', CITY, ' ', STATE, ' ', ZIP) AS MAILING_LABEL
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 22  --  section 8-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: CONCAT_RESULT is the text Rep: with the null skipped. PIPE_RESULT is null, and this sandbox prints a null cell as the word NULL, so you will see NULL there rather than a blank. SAFE_RESULT is Rep: unassigned, because COALESCE replaced the null before the join happened.

-- Starter:
--   SELECT CONCAT('Rep: ', NULL) AS CONCAT_RESULT,
--          'Rep: ' || NULL AS PIPE_RESULT,
--          'Rep: ' || COALESCE(NULL, 'unassigned') AS SAFE_RESULT;

-- Solution:
-- The three ways a null behaves when you join strings, side by side.
-- CONCAT treats a null as an empty string, so the label survives.
SELECT CONCAT('Rep: ', NULL) AS CONCAT_RESULT,
       -- || is stricter: a null anywhere makes the WHOLE result null, so the
       -- text you wrote disappears too.
       'Rep: ' || NULL AS PIPE_RESULT,
       -- COALESCE returns its first argument that is not null, which is how you
       -- substitute a readable stand-in before the null can spread.
       'Rep: ' || COALESCE(NULL, 'unassigned') AS SAFE_RESULT;

-- ----------------------------------------------------------------------
-- Exercise 23  --  section 8-3  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Four rows. Three customers look identical across all three label columns. Companion Care Clinic does not: PIPE_LABEL prints as NULL, CONCAT_LABEL trails off after the slash, and only SAFE_LABEL says what is going on.

-- Starter:
--   SELECT C.CUSTOMER_NAME,
--          C.CUSTOMER_NAME || ' / ' || I.INVOICE_NUM AS PIPE_LABEL,
--          CONCAT(C.CUSTOMER_NAME, ' / ', I.INVOICE_NUM) AS CONCAT_LABEL,
--          C.CUSTOMER_NAME || ' / ' || COALESCE(I.INVOICE_NUM, 'no invoice') AS SAFE_LABEL
--   FROM CUSTOMER C
--   LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
--   ORDER BY C.CUSTOMER_NUM;

-- Solution:
SELECT C.CUSTOMER_NAME,
       -- For the unmatched customer the LEFT JOIN supplies a null invoice number,
       -- and || turns the entire label null.
       C.CUSTOMER_NAME || ' / ' || I.INVOICE_NUM AS PIPE_LABEL,
       -- CONCAT keeps the name and simply leaves a gap where the null was.
       CONCAT(C.CUSTOMER_NAME, ' / ', I.INVOICE_NUM) AS CONCAT_LABEL,
       -- COALESCE is the version to actually ship: it says what the gap means.
       C.CUSTOMER_NAME || ' / ' || COALESCE(I.INVOICE_NUM, 'no invoice') AS SAFE_LABEL
FROM CUSTOMER C
-- LEFT JOIN keeps the customer with no invoice, which is what creates the null.
LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
ORDER BY C.CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 24  --  section 8-7  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two rows come back: 1120 Access Pet Center and 1310 Companion Care Clinic. Ask yourself which one a single set of variables could hold.

-- Starter:
--   -- Rep 20's territory: the CUSTOMER rows whose REP_NUM is '20'.
--   -- Run this and count the rows. That count is why a cursor exists.
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
--   FROM CUSTOMER
--   WHERE REP_NUM = '20'
--   ORDER BY CUSTOMER_NUM;

-- Solution:
-- The four columns a stored procedure would read INTO its local variables.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
-- The procedure's parameter goes here in place of the literal.
WHERE REP_NUM = '20'
-- ORDER BY matters more than usual for a cursor: it fixes the order the rows
-- will be handed over, one at a time.
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 25  --  section 8-7  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Rep 20 gives two rows, both on invoice 50710: Grain-Free Dry Food 30lb at 127.5 and Nylon Dog Leash 6ft at 23.98. Rep 65 also gives two rows, both on invoice 50711: Grain-Free Dry Food 30lb at 85.0 and Small Animal Grooming Kit at 15.25. Drop the ITEM join and the query fails, because DESCRIPTION has nowhere to come from.

-- Starter:
--   -- The cursor's query with i_rep_num written out as '20'.
--   -- Run it, then change '20' to '65' and predict the rows before you run it again.
--   SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
--          L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
--   FROM CUSTOMER C
--   JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
--   JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
--   JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
--   WHERE C.REP_NUM = '20'
--   ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Solution:
-- The query a cursor would walk, written as a plain SELECT first. Run it before
-- wrapping it in a cursor, so you know exactly what rows the loop will see.
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
       -- Three stored columns and one calculated one.
       L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
-- Hop 1: customer to invoice.
JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
-- Hop 2: invoice to line item.
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
-- Hop 3: line item to item.
JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
-- The parameter the procedure would accept.
WHERE C.REP_NUM = '65'
ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- ----------------------------------------------------------------------
-- Exercise 26  --  section 8-7  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: One row: invoice 50711, Grain-Free Dry Food 30lb, 2 at 42.50, a line total of 85.0. Change 50 to 10 and a second line appears, Small Animal Grooming Kit at 15.25.

-- Starter:
--   -- The cursor query behind BIG_LINE_ITEMS('65', 50.00),
--   -- with the parameters written out as literals.
--   SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
--          L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
--   FROM CUSTOMER C
--   JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
--   JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
--   JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
--   WHERE C.REP_NUM = '65'
--     AND L.NUM_ORDERED * L.QUOTED_PRICE >= 50
--   ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Solution:
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
       L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
WHERE C.REP_NUM = '65'
  -- The second filter tests the CALCULATION, not a stored column. Doing it here
  -- rather than inside the loop means fewer rows are ever fetched - the database
  -- discards rows far more cheaply than your loop can.
  AND L.NUM_ORDERED * L.QUOTED_PRICE >= 50
ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- ----------------------------------------------------------------------
-- Exercise 27  --  section 8-7  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Three rows, one per invoice: 50710 at 151.48, 50711 at 100.25, 50712 at 120.49. A cursor over this query would loop three times.

-- Starter:
--   -- One row per invoice: this is what a cursor over a GROUP BY hands the loop.
--   SELECT I.INVOICE_NUM, C.CUSTOMER_NAME,
--          SUM(L.NUM_ORDERED * L.QUOTED_PRICE) AS INVOICE_TOTAL
--   FROM INVOICE I
--   JOIN CUSTOMER C ON I.CUSTOMER_NUM = C.CUSTOMER_NUM
--   JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
--   GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME
--   ORDER BY I.INVOICE_NUM;

-- Solution:
-- A cursor can walk a GROUPED query just as happily as a plain one: each row it
-- hands back simply summarises several underlying rows.
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME,
       SUM(L.NUM_ORDERED * L.QUOTED_PRICE) AS INVOICE_TOTAL
FROM INVOICE I
-- Hop 1: invoice to customer, for the name.
JOIN CUSTOMER C ON I.CUSTOMER_NUM = C.CUSTOMER_NUM
-- Hop 2: invoice to its line items, for the money.
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
-- One row per invoice, so the loop would walk invoices rather than lines.
GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME
ORDER BY I.INVOICE_NUM;

-- ----------------------------------------------------------------------
-- Exercise 28  --  section 8-7  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: You should get the same two rows the procedure produced: 1120 with 3987.5 and 'Call rep', 1310 with 10000 and 'No action'. The leading DROP TABLE IF EXISTS is what lets you press Run a second time without an error.

-- Starter:
--   DROP TABLE IF EXISTS CUST_REVIEW;
--
--   CREATE TABLE CUST_REVIEW
--       (CUSTOMER_NUM CHAR(4),
--        CUSTOMER_NAME VARCHAR(35),
--        AVAILABLE_CREDIT DECIMAL(9,2),
--        REVIEW_NOTE VARCHAR(10));
--
--   INSERT INTO CUST_REVIEW
--          (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE, 'Call rep'
--   FROM CUSTOMER
--   WHERE REP_NUM = '20' AND CREDIT_LIMIT - BALANCE < 5000;
--
--   INSERT INTO CUST_REVIEW
--          (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE, 'No action'
--   FROM CUSTOMER
--   WHERE REP_NUM = '20' AND CREDIT_LIMIT - BALANCE >= 5000;
--
--   SELECT * FROM CUST_REVIEW ORDER BY CUSTOMER_NUM;

-- Solution:
DROP TABLE IF EXISTS CUST_REVIEW;

-- Somewhere for the results to go, exactly as the cursor version used.
CREATE TABLE CUST_REVIEW
    (CUSTOMER_NUM CHAR(4),
     CUSTOMER_NAME VARCHAR(35),
     AVAILABLE_CREDIT DECIMAL(9,2),
     REVIEW_NOTE VARCHAR(10));

-- The whole cursor loop, replaced by two set-based INSERTs. This one writes the
-- rows that would have taken the IF branch...
INSERT INTO CUST_REVIEW
       (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
-- The literal in the SELECT list supplies the same value on every row it writes.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE, 'Call rep'
FROM CUSTOMER
WHERE REP_NUM = '20' AND CREDIT_LIMIT - BALANCE < 5000;

-- ...and this one writes the rows that would have taken the ELSE branch. The
-- two WHERE clauses are the IF, turned inside out.
INSERT INTO CUST_REVIEW
       (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT - BALANCE, 'No action'
FROM CUSTOMER
WHERE REP_NUM = '20' AND CREDIT_LIMIT - BALANCE >= 5000;

-- Same result as the cursor, in two statements instead of thirty lines - and far
-- faster, because the database does the looping internally.
SELECT * FROM CUST_REVIEW ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 29  --  section 8-8  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Three queries, three shapes of answer: one row, no rows, two rows. SQLite reports all three as ordinary results. Oracle gives the last two names and expects you to handle them. Case 2 shows an empty area rather than a table, because no row qualified.

-- Starter:
--   -- Case 1: exactly one row comes back. This is the case the procedure was written for.
--   SELECT CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE CUSTOMER_NUM = '1225';
--
--   -- Case 2: no row comes back. In PL/SQL this raises NO_DATA_FOUND.
--   SELECT CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE CUSTOMER_NUM = '1999';
--
--   -- Case 3: two rows come back. In PL/SQL this raises TOO_MANY_ROWS.
--   SELECT CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE REP_NUM = '20';

-- Solution:
-- Case 1: exactly one row comes back. This is the case the procedure was written for.
-- Filtering on the PRIMARY KEY is what guarantees at most one row.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1225';

-- Case 2: no row comes back. In PL/SQL this raises NO_DATA_FOUND.
-- The key is valid in shape but matches nothing, and an empty result is not an
-- error to SQL - only to a procedure that expected to fill a variable.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1999';

-- Case 3: two rows come back. In PL/SQL this raises TOO_MANY_ROWS.
-- The difference is the column: REP_NUM is not a key, so it can match many rows,
-- and SELECT ... INTO has no way to choose between them.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE REP_NUM = '20';

-- ----------------------------------------------------------------------
-- Exercise 30  --  section 8-8  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two rows come back: 1120 Access Pet Center and 1310 Companion Care Clinic. A cursor does not change what this query returns. It changes who reads the rows and how many at a time. Try changing '20' to '65' to see a one-row list.

-- Starter:
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE REP_NUM = '20'
--   ORDER BY CUSTOMER_NUM;

-- Solution:
-- The SELECT a stored procedure would wrap. Nothing about it changes because it
-- lives inside a procedure - only where the text is kept changes.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
-- In the procedure this literal is replaced by a parameter, which is the whole
-- point: one stored query answering the question for any rep.
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 31  --  section 8-9  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: This is the query the T-SQL procedure runs; the procedure adds a parameter and two variables around it. One row comes back: Whiskers & Wags Boutique with a balance of 4820.75. Change 1420 to 1999 and the box shows an empty result, which is the case the @@ROWCOUNT test is there to catch.

-- Starter:
--   SELECT CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE CUSTOMER_NUM = '1420';

-- Solution:
-- The single-row lookup a procedure would perform with SELECT ... INTO. Filtering
-- on the primary key is what makes it safe: at most one row can ever come back.
SELECT CUSTOMER_NAME, BALANCE
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1420';

-- ----------------------------------------------------------------------
-- Exercise 32  --  section 8-9  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Downtown Aquarium & Pets ends at 1550.00 against a credit limit of 5000.00. The first UPDATE exists so that pressing Run a second time gives the same answer rather than 1900.00. The stored procedure adds the parameter, the transaction, and the @@ROWCOUNT test around the middle statement.

-- Starter:
--   -- Put the balance back to its seeded value so this box can be run again.
--   UPDATE CUSTOMER
--   SET BALANCE = 1200.00
--   WHERE CUSTOMER_NUM = '1225';
--
--   -- The one statement the stored procedure wraps.
--   UPDATE CUSTOMER
--   SET BALANCE = BALANCE + 350.00
--   WHERE CUSTOMER_NUM = '1225';
--
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
--   FROM CUSTOMER
--   WHERE CUSTOMER_NUM = '1225';

-- Solution:
-- Put the balance back to its seeded value so this box can be run again.
UPDATE CUSTOMER
SET BALANCE = 1200.00
WHERE CUSTOMER_NUM = '1225';

-- The one statement the stored procedure wraps.
-- The new value is computed from the old one, so running it twice adds 700, not
-- 350 - which is why the reset above matters.
UPDATE CUSTOMER
SET BALANCE = BALANCE + 350.00
WHERE CUSTOMER_NUM = '1225';

-- Read the row back with the limit alongside, so you can see whether the charge
-- pushed the balance past it - the check the procedure performs for you.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1225';

-- ----------------------------------------------------------------------
-- Exercise 33  --  section 8-9  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The first result shows invoice 50710 ordering two of DG04, which is exactly why the real table refuses the delete. The second result has four rows instead of five: the working copy carried no foreign key over from ITEM, so nothing stopped the delete there. Checking before deleting is the habit worth keeping.

-- Starter:
--   -- Step 1: find out what still points at DG04.
--   SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED
--   FROM INVOICE_LINE
--   WHERE ITEM_ID = 'DG04';
--
--   -- Step 2: delete it from a working copy, where no foreign key is watching.
--   DROP TABLE IF EXISTS ITEM_WORK;
--   CREATE TABLE ITEM_WORK AS SELECT * FROM ITEM;
--
--   DELETE FROM ITEM_WORK
--   WHERE ITEM_ID = 'DG04';
--
--   SELECT ITEM_ID, DESCRIPTION, ON_HAND
--   FROM ITEM_WORK
--   ORDER BY ITEM_ID;

-- Solution:
-- Step 1: find out what still points at DG04.
-- This is the query behind the error message: these are the rows a foreign key
-- would be protecting if the delete were attempted.
SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED
FROM INVOICE_LINE
WHERE ITEM_ID = 'DG04';

-- Step 2: delete it from a working copy, where no foreign key is watching.
DROP TABLE IF EXISTS ITEM_WORK;
-- CREATE TABLE ... AS copies the columns and rows but NOT the constraints, which
-- is exactly why the delete below is allowed to succeed here.
CREATE TABLE ITEM_WORK AS SELECT * FROM ITEM;

DELETE FROM ITEM_WORK
WHERE ITEM_ID = 'DG04';

-- Four rows in the copy, five still in the real ITEM table.
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM_WORK
ORDER BY ITEM_ID;

-- ----------------------------------------------------------------------
-- Exercise 34  --  section 8-9  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two rows, in the order the cursor would visit them: 1120 first, then 1310. The ORDER BY is what makes a cursor's visiting order predictable. Without it the engine may hand back rows in any order it likes, and a report built on that order becomes unreliable.

-- Starter:
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
--   FROM CUSTOMER
--   WHERE REP_NUM = '20'
--   ORDER BY CUSTOMER_NUM;

-- Solution:
-- The SELECT a stored procedure would wrap. Nothing about it changes because it
-- lives inside a procedure - only where the text is kept changes.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
FROM CUSTOMER
-- In the procedure this literal is replaced by a parameter, which is the whole
-- point: one stored query answering the question for any rep.
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 35  --  section 8-9  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Two lines on invoice 50710 for Access Pet Center: 127.50 and 23.98. The second query is the same total the cursor builds up in @L_RUNNING_TOTAL, done in one statement instead of a loop. When SUM can answer the question, SUM is the better answer. Companion Care Clinic has no invoice, so it contributes nothing.

-- Starter:
--   SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION,
--          IL.NUM_ORDERED * IL.QUOTED_PRICE AS LINE_TOTAL
--   FROM CUSTOMER C
--        JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
--        JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
--        JOIN ITEM IT         ON IL.ITEM_ID = IT.ITEM_ID
--   WHERE C.REP_NUM = '20'
--   ORDER BY I.INVOICE_NUM, IT.DESCRIPTION;
--
--   SELECT SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS REP_TOTAL
--   FROM CUSTOMER C
--        JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
--        JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
--   WHERE C.REP_NUM = '20';

-- Solution:
-- The detail listing a cursor would print one line at a time.
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME, IT.DESCRIPTION,
       IL.NUM_ORDERED * IL.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
     -- Three hops across four tables.
     JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
     JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
     JOIN ITEM IT         ON IL.ITEM_ID = IT.ITEM_ID
WHERE C.REP_NUM = '20'
ORDER BY I.INVOICE_NUM, IT.DESCRIPTION;

-- And the running total the loop would accumulate in a variable, obtained here
-- in one statement. ITEM is not joined this time, because no description is
-- displayed - a total needs fewer tables than a detail line.
SELECT SUM(IL.NUM_ORDERED * IL.QUOTED_PRICE) AS REP_TOTAL
FROM CUSTOMER C
     JOIN INVOICE I       ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
     JOIN INVOICE_LINE IL ON I.INVOICE_NUM = IL.INVOICE_NUM
WHERE C.REP_NUM = '20';

-- ----------------------------------------------------------------------
-- Exercise 36  --  section 8-10  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: One row comes back: 50712, GR15, 4, and whatever date you pressed Run. Read statement 3 again and notice it says nothing about INVOICE_LINE_LOG. That is the whole point of a trigger, and also the whole danger. Delete statement 2, press Run again, and the log comes back empty.

-- Starter:
--   -- Housekeeping first, so this whole box can be run more than once.
--   DROP TRIGGER IF EXISTS LOG_NEW_LINE;
--   DROP TABLE IF EXISTS INVOICE_LINE_LOG;
--   DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';
--
--   -- 1. The audit table. Nothing writes to it by hand, ever.
--   CREATE TABLE INVOICE_LINE_LOG (
--       LOG_ID       INTEGER  PRIMARY KEY,
--       INVOICE_NUM  CHAR(5),
--       ITEM_ID      CHAR(4),
--       NUM_ORDERED  SMALLINT,
--       LOGGED_ON    DATE
--   );
--
--   -- 2. The trigger. It fires after each new INVOICE_LINE row lands.
--   CREATE TRIGGER LOG_NEW_LINE
--   AFTER INSERT ON INVOICE_LINE
--   FOR EACH ROW
--   BEGIN
--       INSERT INTO INVOICE_LINE_LOG (INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON)
--       VALUES (NEW.INVOICE_NUM, NEW.ITEM_ID, NEW.NUM_ORDERED, DATE('now'));
--   END;
--
--   -- 3. One ordinary INSERT. Nothing here mentions the log table.
--   INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
--   VALUES ('50712', 'GR15', 4, 15.25);
--
--   -- 4. Proof the trigger ran.
--   SELECT LOG_ID, INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON
--   FROM INVOICE_LINE_LOG;

-- Solution:
-- Housekeeping first, so this whole box can be run more than once.
DROP TRIGGER IF EXISTS LOG_NEW_LINE;
DROP TABLE IF EXISTS INVOICE_LINE_LOG;
DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';

-- 1. The audit table. Nothing writes to it by hand, ever.
CREATE TABLE INVOICE_LINE_LOG (
    -- INTEGER PRIMARY KEY in SQLite numbers itself, so the trigger never supplies it.
    LOG_ID       INTEGER  PRIMARY KEY,
    INVOICE_NUM  CHAR(5),
    ITEM_ID      CHAR(4),
    NUM_ORDERED  SMALLINT,
    LOGGED_ON    DATE
);

-- 2. The trigger. It fires after each new INVOICE_LINE row lands.
CREATE TRIGGER LOG_NEW_LINE
-- The event: after an insert on this table, and only after it succeeds.
AFTER INSERT ON INVOICE_LINE
-- FOR EACH ROW: run the body once per row inserted, not once per statement.
FOR EACH ROW
BEGIN
    INSERT INTO INVOICE_LINE_LOG (INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON)
    -- NEW holds the row being inserted. On an INSERT there is no OLD, because
    -- the row did not exist a moment ago.
    VALUES (NEW.INVOICE_NUM, NEW.ITEM_ID, NEW.NUM_ORDERED, DATE('now'));
END;

-- 3. One ordinary INSERT. Nothing here mentions the log table.
INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
VALUES ('50712', 'GR15', 4, 15.25);

-- 4. Proof the trigger ran.
-- Two statements were executed and two rows were written, in two tables.
SELECT LOG_ID, INVOICE_NUM, ITEM_ID, NUM_ORDERED, LOGGED_ON
FROM INVOICE_LINE_LOG;

-- ----------------------------------------------------------------------
-- Exercise 37  --  section 8-10  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: Exactly one log row: 1120, 3512.5, 3762.5. Two UPDATE statements ran but only one was a real change, and the WHEN clause is what kept the second one out of the log. Delete the WHEN line and press Run again to see the noise it was filtering.

-- Starter:
--   DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE;
--   DROP TABLE IF EXISTS BALANCE_LOG;
--   UPDATE CUSTOMER SET BALANCE = 3512.50 WHERE CUSTOMER_NUM = '1120';
--
--   CREATE TABLE BALANCE_LOG (
--       LOG_ID        INTEGER  PRIMARY KEY,
--       CUSTOMER_NUM  CHAR(4),
--       OLD_BALANCE   DECIMAL(9,2),
--       NEW_BALANCE   DECIMAL(9,2)
--   );
--
--   CREATE TRIGGER LOG_BALANCE_CHANGE
--   AFTER UPDATE OF BALANCE ON CUSTOMER
--   FOR EACH ROW
--   WHEN OLD.BALANCE <> NEW.BALANCE
--   BEGIN
--       INSERT INTO BALANCE_LOG (CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE)
--       VALUES (OLD.CUSTOMER_NUM, OLD.BALANCE, NEW.BALANCE);
--   END;
--
--   -- A real change. This one is logged.
--   UPDATE CUSTOMER
--   SET BALANCE = BALANCE + 250.00
--   WHERE CUSTOMER_NUM = '1120';
--
--   -- A change that changes nothing. The WHEN clause skips it.
--   UPDATE CUSTOMER
--   SET BALANCE = BALANCE
--   WHERE CUSTOMER_NUM = '1120';
--
--   SELECT LOG_ID, CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE
--   FROM BALANCE_LOG;

-- Solution:
-- Housekeeping, including resetting the balance so the box can be re-run.
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
-- OF BALANCE narrows the event: changing any other column does not fire this.
AFTER UPDATE OF BALANCE ON CUSTOMER
FOR EACH ROW
-- WHEN adds a condition the row must meet before the body runs. Here it filters
-- out updates that set the balance to the value it already had.
WHEN OLD.BALANCE <> NEW.BALANCE
BEGIN
    INSERT INTO BALANCE_LOG (CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE)
    -- On an UPDATE both OLD and NEW exist, which is what makes a before-and-after
    -- audit possible.
    VALUES (OLD.CUSTOMER_NUM, OLD.BALANCE, NEW.BALANCE);
END;

-- A real change. This one is logged.
UPDATE CUSTOMER
SET BALANCE = BALANCE + 250.00
WHERE CUSTOMER_NUM = '1120';

-- A change that changes nothing. The WHEN clause skips it.
-- The UPDATE still runs and still touches the row; only the trigger body is
-- skipped, which keeps the audit free of no-op entries.
UPDATE CUSTOMER
SET BALANCE = BALANCE
WHERE CUSTOMER_NUM = '1120';

-- One row, not two.
SELECT LOG_ID, CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE
FROM BALANCE_LOG;

-- ----------------------------------------------------------------------
-- Exercise 38  --  section 8-10  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: As written the insert succeeds and Harbor Pet Supply appears with a credit limit of 9000. Now change 9000.00 to 15000.00 and press Run again: the WHEN clause turns true, RAISE(ABORT) cancels the statement, and the box reports the message instead of a table. Nothing was stored, which is what BEFORE buys you.

-- Starter:
--   DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
--   DELETE FROM CUSTOMER WHERE CUSTOMER_NUM = '1500';
--
--   CREATE TRIGGER CHECK_CREDIT_LIMIT
--   BEFORE INSERT ON CUSTOMER
--   FOR EACH ROW
--   WHEN NEW.CREDIT_LIMIT > 10000
--   BEGIN
--       SELECT RAISE(ABORT, 'Credit limit over 10000 needs manager approval');
--   END;
--
--   -- Within the ceiling, so this one is stored.
--   INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP,
--                         BALANCE, CREDIT_LIMIT, REP_NUM)
--   VALUES ('1500', 'Harbor Pet Supply', '12 Dock St.', 'Northfield', 'OH', '44067',
--           0.00, 9000.00, '35');
--
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT
--   FROM CUSTOMER
--   WHERE CUSTOMER_NUM = '1500';

-- Solution:
DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
DELETE FROM CUSTOMER WHERE CUSTOMER_NUM = '1500';

CREATE TRIGGER CHECK_CREDIT_LIMIT
-- BEFORE, not AFTER: the trigger has to run while the insert can still be
-- stopped. An AFTER trigger fires once the row is already in.
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
-- Only rows over the ceiling are worth checking, so WHEN filters the rest out.
WHEN NEW.CREDIT_LIMIT > 10000
BEGIN
    -- RAISE(ABORT, message) cancels the statement and reports your own wording.
    -- This is a business rule enforced in the database rather than in an
    -- application, so it holds no matter which program does the inserting.
    SELECT RAISE(ABORT, 'Credit limit over 10000 needs manager approval');
END;

-- Within the ceiling, so this one is stored.
-- The WHEN condition is false, the trigger body never runs, and the insert
-- proceeds exactly as though no trigger existed.
INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP,
                      BALANCE, CREDIT_LIMIT, REP_NUM)
VALUES ('1500', 'Harbor Pet Supply', '12 Dock St.', 'Northfield', 'OH', '44067',
        0.00, 9000.00, '35');

SELECT CUSTOMER_NUM, CUSTOMER_NAME, CREDIT_LIMIT
FROM CUSTOMER
WHERE CUSTOMER_NUM = '1500';

-- ----------------------------------------------------------------------
-- Exercise 39  --  section 8-10  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: The Small Animal Grooming Kit ends at 18, down from its seeded 22. The INSERT names INVOICE_LINE and only INVOICE_LINE, yet a row in ITEM changed. The UPDATE at the top resets ON_HAND to 22 so the box gives 18 every time rather than 14, then 10, then 6.

-- Starter:
--   DROP TRIGGER IF EXISTS REDUCE_ON_HAND;
--   DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';
--   UPDATE ITEM SET ON_HAND = 22 WHERE ITEM_ID = 'GR15';
--
--   CREATE TRIGGER REDUCE_ON_HAND
--   AFTER INSERT ON INVOICE_LINE
--   FOR EACH ROW
--   BEGIN
--       UPDATE ITEM
--       SET ON_HAND = ON_HAND - NEW.NUM_ORDERED
--       WHERE ITEM_ID = NEW.ITEM_ID;
--   END;
--
--   INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
--   VALUES ('50712', 'GR15', 4, 15.25);
--
--   SELECT ITEM_ID, DESCRIPTION, ON_HAND
--   FROM ITEM
--   WHERE ITEM_ID = 'GR15';

-- Solution:
-- Housekeeping: remove the line and put the stock back, so the box re-runs cleanly.
DROP TRIGGER IF EXISTS REDUCE_ON_HAND;
DELETE FROM INVOICE_LINE WHERE INVOICE_NUM = '50712' AND ITEM_ID = 'GR15';
UPDATE ITEM SET ON_HAND = 22 WHERE ITEM_ID = 'GR15';

CREATE TRIGGER REDUCE_ON_HAND
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    -- A trigger that CHANGES another table rather than just recording something.
    -- Selling an item automatically takes it out of stock.
    UPDATE ITEM
    SET ON_HAND = ON_HAND - NEW.NUM_ORDERED
    -- NEW supplies both the quantity and which item to reduce.
    WHERE ITEM_ID = NEW.ITEM_ID;
END;

-- One INSERT into INVOICE_LINE...
INSERT INTO INVOICE_LINE (INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE)
VALUES ('50712', 'GR15', 4, 15.25);

-- ...and ITEM changed too, from 22 to 18, with nothing in the statement above
-- mentioning ITEM at all. Powerful, and the reason triggers must be documented.
SELECT ITEM_ID, DESCRIPTION, ON_HAND
FROM ITEM
WHERE ITEM_ID = 'GR15';

-- ----------------------------------------------------------------------
-- Exercise 40  --  section 8-10  --  seed: kimtay_full
-- ----------------------------------------------------------------------

-- Hint given: One row: LOG_NEW_LINE, trigger, INVOICE_LINE. That third column is the one that matters when you are trying to work out why a table keeps changing on its own. To watch the listing empty out, add DROP TRIGGER LOG_NEW_LINE; immediately ABOVE the SELECT and press Run again. Putting it after the SELECT changes nothing you can see, because the catalog is read before the drop happens.

-- Starter:
--   -- Clear anything the earlier boxes on this page may have left behind,
--   -- so the listing below is exactly what this box created.
--   DROP TRIGGER IF EXISTS LOG_NEW_LINE;
--   DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE;
--   DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
--   DROP TRIGGER IF EXISTS REDUCE_ON_HAND;
--
--   CREATE TRIGGER LOG_NEW_LINE
--   AFTER INSERT ON INVOICE_LINE
--   FOR EACH ROW
--   BEGIN
--       UPDATE ITEM SET ON_HAND = ON_HAND WHERE ITEM_ID = NEW.ITEM_ID;
--   END;
--
--   -- Every trigger this database holds, and the table each one guards.
--   SELECT name, type, tbl_name
--   FROM sqlite_master
--   WHERE type = 'trigger';

-- Solution:
-- Clear anything the earlier boxes on this page may have left behind,
-- so the listing below is exactly what this box created.
DROP TRIGGER IF EXISTS LOG_NEW_LINE;
DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE;
DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT;
DROP TRIGGER IF EXISTS REDUCE_ON_HAND;

-- One harmless trigger, created only so the catalogue query below has something
-- to find. Its body updates a column to the value it already holds.
CREATE TRIGGER LOG_NEW_LINE
AFTER INSERT ON INVOICE_LINE
FOR EACH ROW
BEGIN
    UPDATE ITEM SET ON_HAND = ON_HAND WHERE ITEM_ID = NEW.ITEM_ID;
END;

-- Every trigger this database holds, and the table each one guards.
-- Triggers live in the same catalogue as tables, views and indexes. Running this
-- is how you discover the automatic behaviour a database already has, which is
-- the first thing to check when a table changes without an obvious cause.
SELECT name, type, tbl_name
FROM sqlite_master
WHERE type = 'trigger';

-- ----------------------------------------------------------------------
-- Exercise 41  --  section Review  --  seed: both_full
-- ----------------------------------------------------------------------

-- Hint given: Four customers come back, from 1120 to 1420. Every column of every row is filled in; nothing in the shipped data is missing. Companion Care Clinic sits at 1310 with a balance of 0 and no invoice anywhere in the database, which makes it the row to reach for whenever a question is about something that has no match. Replace the query with anything you want to check.

-- Starter:
--   -- Both databases are loaded. Paste a review answer here and press Run.
--   -- Starter: the SELECT that a cursor over KimTay's customers would drive.
--   SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
--   FROM CUSTOMER
--   ORDER BY CUSTOMER_NUM;

-- Solution:
-- Both databases are loaded. Paste a review answer here and press Run.
-- Starter: the SELECT that a cursor over KimTay's customers would drive.
-- Four columns, so a procedure walking this would declare four local variables
-- of matching types to FETCH each row into.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
-- ORDER BY fixes the sequence the rows would be handed over in.
ORDER BY CUSTOMER_NUM;

-- ----------------------------------------------------------------------
-- Exercise 42  --  section Case Exercises  --  seed: both_full
-- ----------------------------------------------------------------------

-- Hint given: One log row: L004 for 465.00. The INSERT names only PAYMENT, and PAYMENT_LOG filled itself in. Try adding a second INSERT with PAYMENT_ID 98 for lease L003 at 725.00 and predict the result before you press Run. Remember to add a matching DELETE at the top if you want the box to stay re-runnable.

-- Starter:
--   -- StayWell wants a permanent record of every payment as it arrives.
--   DROP TRIGGER IF EXISTS LOG_PAYMENT;
--   DROP TABLE IF EXISTS PAYMENT_LOG;
--   DELETE FROM PAYMENT WHERE PAYMENT_ID = 99;
--
--   CREATE TABLE PAYMENT_LOG (
--       LOG_ID     INTEGER  PRIMARY KEY,
--       LEASE_ID   CHAR(4),
--       AMOUNT     DECIMAL(7,2),
--       LOGGED_ON  DATE
--   );
--
--   CREATE TRIGGER LOG_PAYMENT
--   AFTER INSERT ON PAYMENT
--   FOR EACH ROW
--   BEGIN
--       INSERT INTO PAYMENT_LOG (LEASE_ID, AMOUNT, LOGGED_ON)
--       VALUES (NEW.LEASE_ID, NEW.AMOUNT, DATE('now'));
--   END;
--
--   INSERT INTO PAYMENT (PAYMENT_ID, LEASE_ID, PAYMENT_DATE, AMOUNT)
--   VALUES (99, 'L004', '2026-09-01', 465.00);
--
--   SELECT LOG_ID, LEASE_ID, AMOUNT
--   FROM PAYMENT_LOG;

-- Solution:
-- StayWell wants a permanent record of every payment as it arrives.
-- Housekeeping, so the box can be run more than once.
DROP TRIGGER IF EXISTS LOG_PAYMENT;
DROP TABLE IF EXISTS PAYMENT_LOG;
DELETE FROM PAYMENT WHERE PAYMENT_ID = 99;

-- The audit table, with a key that numbers itself.
CREATE TABLE PAYMENT_LOG (
    LOG_ID     INTEGER  PRIMARY KEY,
    LEASE_ID   CHAR(4),
    AMOUNT     DECIMAL(7,2),
    LOGGED_ON  DATE
);

CREATE TRIGGER LOG_PAYMENT
-- The event: after a payment row is stored.
AFTER INSERT ON PAYMENT
-- Once per row inserted.
FOR EACH ROW
BEGIN
    INSERT INTO PAYMENT_LOG (LEASE_ID, AMOUNT, LOGGED_ON)
    -- NEW is the payment that just landed; DATE('now') stamps when it was seen.
    VALUES (NEW.LEASE_ID, NEW.AMOUNT, DATE('now'));
END;

-- One ordinary INSERT, with no mention of the log anywhere in it.
INSERT INTO PAYMENT (PAYMENT_ID, LEASE_ID, PAYMENT_DATE, AMOUNT)
VALUES (99, 'L004', '2026-09-01', 465.00);

-- And the log has a row, written by the database on its own.
SELECT LOG_ID, LEASE_ID, AMOUNT
FROM PAYMENT_LOG;
