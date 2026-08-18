-- ======================================================================
-- Module 8 · Using Functions
-- ======================================================================
--
-- Sections: 8-2
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-2  Using Functions
-- ----------------------------------------------------------------------


-- >>> EXERCISE 3  (section 8-2, seed: kimtay_full)
-- Hint: Wrap the column in the function and give the result a column name with AS. Access Pet Center becomes ACCESS PET CENTER, and Maple Grove becomes maple grove.
-- Add an upper case name column and a lower case city column.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- >>> EXERCISE 4  (section 8-2, seed: kimtay_full)
-- Hint: Put both sides of the comparison in the same case: UPPER(CITY) on the left, a fully capitalized literal on the right. Capitalizing only one side still matches nothing. You should get customers 1120 and 1310.
-- Run this first. It matches nothing. Then fix it with UPPER.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, CITY
FROM CUSTOMER
WHERE CITY = 'maple grove'
ORDER BY CUSTOMER_NUM;

-- >>> EXERCISE 5  (section 8-2, seed: kimtay_full)
-- Hint: SUBSTR(ITEM_ID, 1, 2) starts at character 1 and takes 2. AV07 gives AV. LENGTH('Aviary Starter Cage') is 19.
-- Add the two-letter prefix of ITEM_ID and the length of DESCRIPTION.
SELECT ITEM_ID, DESCRIPTION
FROM ITEM
ORDER BY ITEM_ID;

-- >>> EXERCISE 6  (section 8-2, seed: kimtay_full)
-- Hint: Two rows come back: CF21 at 24 characters and GR15 at 25. Change 20 to 19 and FT88, at exactly 20, joins them.
-- Which item descriptions are longer than 20 characters?
SELECT ITEM_ID, DESCRIPTION, LENGTH(DESCRIPTION) AS NAME_LENGTH
FROM ITEM
WHERE LENGTH(DESCRIPTION) > 20
ORDER BY ITEM_ID;

-- >>> EXERCISE 7  (section 8-2, seed: kimtay_full)
-- Hint: The brackets make the blanks visible. 15 characters before, 11 after. The space between Maple and Grove survives, because TRIM only touches the ends.
SELECT '[' || '  Maple Grove  ' || ']' AS RAW_VALUE,
       '[' || TRIM('  Maple Grove  ') || ']' AS TRIMMED_VALUE,
       LENGTH('  Maple Grove  ') AS BEFORE_LEN,
       LENGTH(TRIM('  Maple Grove  ')) AS AFTER_LEN;

-- >>> EXERCISE 8  (section 8-2, seed: kimtay_full)
-- Hint: Take one character from each name and join them with ||, then wrap SUBSTR(LAST_NAME, 1, 3) in UPPER. Rep 20 gives VK and KAI.
-- Build INITIALS (first letter of each name) and CODE (first three
-- letters of the last name, in capitals).
SELECT REP_NUM, FIRST_NAME, LAST_NAME
FROM REP
ORDER BY REP_NUM;

-- >>> EXERCISE 9  (section 8-2, seed: kimtay_full)
-- Hint: Rep 35 is the one that matters. 39355 times 0.07 comes back as 2754.8500000000004, which is binary floating point showing through, and ROUND(COMMISSION * RATE, 2) reports it as 2754.85. Reps 20 and 65 were already clean at 1078 and 1188.2.
-- Add RAW_PAYOUT (COMMISSION * RATE) and PAYOUT (the same product
-- rounded to cents). Compare the two columns on rep 35.
SELECT REP_NUM, COMMISSION, RATE
FROM REP
ORDER BY REP_NUM;

-- >>> EXERCISE 10  (section 8-2, seed: kimtay_full)
-- Hint: Invoice 50710 has two lines: 3 at 42.50 is 127.5, and 2 at 11.99 is 23.98. Whole amounts print without a trailing zero, so 2 at 42.50 on invoice 50711 shows as 85.
-- Add LINE_TOTAL: NUM_ORDERED * QUOTED_PRICE, rounded to cents.
SELECT INVOICE_NUM, ITEM_ID, NUM_ORDERED, QUOTED_PRICE
FROM INVOICE_LINE
ORDER BY INVOICE_NUM, ITEM_ID;

-- >>> EXERCISE 11  (section 8-2, seed: kimtay_full)
-- Hint: Customer 1120 shows -3987.5 and 3987.5. Companion Care Clinic, with a zero balance, shows the widest gap at 10000.
-- Add the raw difference and its absolute value.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- >>> EXERCISE 12  (section 8-2, seed: kimtay_full)
-- Hint: Companion Care Clinic leads at 10000, and Whiskers and Wags Boutique trails at 1179.25.
SELECT CUSTOMER_NUM, CUSTOMER_NAME,
       ABS(CREDIT_LIMIT - BALANCE) AS AVAILABLE
FROM CUSTOMER
ORDER BY ABS(CREDIT_LIMIT - BALANCE) DESC;

-- Example 8-2.11
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- MySQL only. TRUNCATE does not exist in this sandbox and raises
-- "no such function: TRUNCATE".
-- SELECT: the stored price next to a version of it with the pennies cut off.
--   TRUNCATE(value, 0) chops at the decimal point - it does not round, so 64.99
--   becomes 64 rather than 65. Compare with ROUND if that matters.
SELECT ITEM_ID, PRICE, TRUNCATE(PRICE, 0) AS WHOLE_DOLLARS

-- FROM: the table being read. Row functions like this one run once per row, so
--   five rows in means five rows out - unlike an aggregate.
FROM ITEM

-- ORDER BY: sorted by item ID for a stable, readable listing.
ORDER BY ITEM_ID;

-- >>> EXERCISE 13  (section 8-2, seed: kimtay_full)
-- Hint: AV07 at 64.99 rounds to 65 but chops to 64. GR15 at 15.25 gives 15 either way. If a report must never overstate a price, those two columns are not interchangeable.
SELECT ITEM_ID, PRICE,
       ROUND(PRICE, 0) AS ROUNDED,
       CAST(PRICE AS INTEGER) AS CHOPPED
FROM ITEM
ORDER BY ITEM_ID;

-- Example 8-2.13
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- MySQL only. Every function in this statement is unavailable in the
-- sandbox. The four sandboxes below do the same four jobs.
-- CURDATE(): today's date, taken from the server. It needs no column and no
--   arguments, so it returns the same value on every row.
SELECT CURDATE() AS TODAY,

--   YEAR(): pulls one part out of a date. There are matching MONTH() and DAY().
       YEAR(INVOICE_DATE) AS INVOICE_YEAR,

--   DATEDIFF(): the number of days between two dates, later one first.
       DATEDIFF(CURDATE(), INVOICE_DATE) AS DAYS_OLD,

--   DATE_ADD(): moves a date forward by an interval - the way to work out a due
--     date without doing arithmetic on the number by hand.
       DATE_ADD(INVOICE_DATE, INTERVAL 30 DAY) AS DUE_DATE

-- FROM: the table supplying INVOICE_DATE to all three date functions.
FROM INVOICE

-- ORDER BY: sorted by invoice number so the ages line up in a predictable order.
ORDER BY INVOICE_NUM;

-- >>> EXERCISE 14  (section 8-2, seed: kimtay_full)
-- Hint: One row, two columns. TODAY is a plain YYYY-MM-DD value; RIGHT_NOW carries hours, minutes and seconds as well. The values change every time you run it.
SELECT DATE('now') AS TODAY,
       DATETIME('now') AS RIGHT_NOW;

-- >>> EXERCISE 15  (section 8-2, seed: kimtay_full)
-- Hint: All three KimTay invoices land in 2026, month 06, period 2026-06. The month comes back as the text 06, with the leading zero kept.
-- Add the year, the month, and a combined YYYY-MM period column.
SELECT INVOICE_NUM, INVOICE_DATE
FROM INVOICE
ORDER BY INVOICE_NUM;

-- >>> EXERCISE 16  (section 8-2, seed: kimtay_full)
-- Hint: Change '+15 days' to '+30 days'. Invoice 50710, dated 2026-06-14, is then due 2026-07-14, and 50712 is due 2026-07-15.
-- KimTay's terms are net 30, not net 15. Fix the modifier.
SELECT INVOICE_NUM, INVOICE_DATE,
       DATE(INVOICE_DATE, '+15 days') AS DUE_DATE
FROM INVOICE
ORDER BY INVOICE_NUM;

-- >>> EXERCISE 17  (section 8-2, seed: kimtay_full)
-- Hint: The raw numbers are around 2461205.5, which is meaningless on its own and exactly right as a difference. Subtract the invoice date from '2026-07-01' to get 17, 17 and 16 days.
-- Step 1: see the raw day numbers.
SELECT INVOICE_NUM, INVOICE_DATE,
       julianday(INVOICE_DATE) AS JULIAN
FROM INVOICE
ORDER BY INVOICE_NUM;

-- >>> EXERCISE 18  (section 8-2, seed: kimtay_full)
-- Hint: RAW_DAYS comes back with a long fraction, because 'now' includes the clock time. DAYS_OLD is the same value with the fraction thrown away. Both columns grow by one every day, so your numbers will be larger than a classmate's from last week. Swap 'now' for '2026-07-01' and the fraction disappears.
-- Age each invoice against right now instead of a fixed date.
SELECT INVOICE_NUM, INVOICE_DATE,
       julianday('now') - julianday(INVOICE_DATE) AS RAW_DAYS,
       CAST(julianday('now') - julianday(INVOICE_DATE) AS INTEGER) AS DAYS_OLD
FROM INVOICE
ORDER BY INVOICE_NUM;
