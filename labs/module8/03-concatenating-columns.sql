-- ======================================================================
-- Module 8 · Concatenating Columns
-- ======================================================================
--
-- Sections: 8-3
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-3  Concatenating Columns
-- ----------------------------------------------------------------------


-- >>> EXERCISE 19  (section 8-3, seed: kimtay_full)
-- Hint: A space is a value like any other. Pass ' ' as a middle argument: CONCAT(FIRST_NAME, ' ', LAST_NAME).
-- Valerie Kaiser comes back as ValerieKaiser. Add the missing space.
SELECT REP_NUM,
       CONCAT(FIRST_NAME, LAST_NAME) AS FULL_NAME
FROM REP
ORDER BY REP_NUM;

-- >>> EXERCISE 20  (section 8-3, seed: kimtay_full)
-- Hint: Chain the operator: column, separator, column, separator, column. The comma and the spaces are literals in quotes. Reps 20 and 35 both give Maple Grove, OH 44601.
-- Build MAILING_LINE in the form: Maple Grove, OH 44601
SELECT REP_NUM, CITY, STATE, ZIP
FROM REP
ORDER BY REP_NUM;

-- >>> EXERCISE 21  (section 8-3, seed: kimtay_full)
-- Hint: Nine arguments in all: the five columns and the four separators between them. Watch the comma after the street but the plain space before the state.
-- Build a one-line mailing label per customer:
-- Access Pet Center, 215 Foster Ave., Maple Grove OH 44601
SELECT CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP
FROM CUSTOMER
ORDER BY CUSTOMER_NUM;

-- >>> EXERCISE 22  (section 8-3, seed: kimtay_full)
-- Hint: CONCAT_RESULT is the text Rep: with the null skipped. PIPE_RESULT is null, and this sandbox prints a null cell as the word NULL, so you will see NULL there rather than a blank. SAFE_RESULT is Rep: unassigned, because COALESCE replaced the null before the join happened.
SELECT CONCAT('Rep: ', NULL) AS CONCAT_RESULT,
       'Rep: ' || NULL AS PIPE_RESULT,
       'Rep: ' || COALESCE(NULL, 'unassigned') AS SAFE_RESULT;

-- >>> EXERCISE 23  (section 8-3, seed: kimtay_full)
-- Hint: Four rows. Three customers look identical across all three label columns. Companion Care Clinic does not: PIPE_LABEL prints as NULL, CONCAT_LABEL trails off after the slash, and only SAFE_LABEL says what is going on.
SELECT C.CUSTOMER_NAME,
       C.CUSTOMER_NAME || ' / ' || I.INVOICE_NUM AS PIPE_LABEL,
       CONCAT(C.CUSTOMER_NAME, ' / ', I.INVOICE_NUM) AS CONCAT_LABEL,
       C.CUSTOMER_NAME || ' / ' || COALESCE(I.INVOICE_NUM, 'no invoice') AS SAFE_LABEL
FROM CUSTOMER C
LEFT JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
ORDER BY C.CUSTOMER_NUM;
