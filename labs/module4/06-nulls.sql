-- ======================================================================
-- Module 4 · Nulls
-- ======================================================================
--
-- Sections: 4-6
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 4-6  Nulls
-- ----------------------------------------------------------------------


-- Example 4-6.1
-- UPDATE: names the table whose rows are about to change.
UPDATE STUDENT

-- SET: which column gets a new value, and what that value is. NULL is a keyword,
--   not text - writing 'NULL' in quotes would store the four letters N-U-L-L.
SET HOME_STATE = NULL

-- WHERE: which rows are affected. Leave this line off and every student in the
--   table loses their home state, so read it before running the statement.
WHERE STUDENT_ID = 'S003';

-- SELECT: the check. Look at the table after any change you make.
SELECT STUDENT_ID, LAST_NAME, HOME_STATE

-- FROM: the table just updated.
FROM STUDENT

-- ORDER BY: sorts the four rows so the cleared one is easy to find. S003 now
--   prints as NULL, which is this page's way of showing "no value recorded".
ORDER BY STUDENT_ID;

-- Example 4-6.2
-- GOAL: a deliberate error, and the one every beginner writes.
-- SELECT: three columns.
SELECT STUDENT_ID, LAST_NAME, HOME_STATE

-- FROM: the table being read.
FROM STUDENT

-- WHERE: BROKEN, though it reads like plain English. NULL is not a value, it is
--   the absence of one, so "equals NULL" cannot be answered true or false - it
--   comes back unknown. WHERE keeps a row only when the condition is TRUE, and
--   unknown is not true, so every row is discarded, including the very row you
--   were hunting for. No error message appears; you simply get nothing.
WHERE HOME_STATE = NULL;

-- Example 4-6.3
-- SELECT: three columns.
SELECT STUDENT_ID, LAST_NAME, HOME_STATE

-- FROM: the table being read.
FROM STUDENT

-- WHERE: IS NULL is the only test that works, because it asks about the presence
--   of a value rather than comparing values. It is a phrase in its own right -
--   there is no = anywhere in it.
WHERE HOME_STATE IS NULL;

-- Example 4-6.4
-- SELECT: three columns.
SELECT STUDENT_ID, LAST_NAME, HOME_STATE

-- FROM: the table being read.
FROM STUDENT

-- WHERE: IS NOT NULL is the mirror image - keep the rows that DO have a value.
--   Together, IS NULL and IS NOT NULL account for every row in the table, which
--   ordinary comparisons like <> never do.
WHERE HOME_STATE IS NOT NULL

-- ORDER BY: sorts what comes back.
ORDER BY STUDENT_ID;

-- Example 4-6.5
-- UPDATE: the table being changed.
UPDATE ROOM

-- SET: clear the rent, because next year's figure has not been decided yet. A
--   null is the honest record of "not known"; 0 would be a lie about the price.
SET MONTHLY_RENT = NULL

-- WHERE: two conditions, because ROOM's primary key is made of two columns.
--   Both are needed to identify exactly one room.
WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

-- SELECT: the stored rent alongside a calculation that uses it. Any arithmetic
--   touching a null produces a null, so the cleared room shows NULL in the rent
--   column and NULL again in the total - the unknown spreads.
SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT, MONTHLY_RENT * 9 AS NINE_MONTH_TOTAL

-- FROM: the table just updated.
FROM ROOM

-- WHERE: narrows the report to the one property.
WHERE PROPERTY_ID = 'P200'

-- ORDER BY: sorts the three rooms by number.
ORDER BY ROOM_NUM;

-- Example 4-6.6
-- SELECT: three columns.
SELECT STUDENT_ID, LAST_NAME, HOME_STATE

-- FROM: the table being read.
FROM STUDENT

-- WHERE: an ordinary comparison with nothing to do with nulls - and it still
--   drops the null row. S003 is missing not because that student is known to
--   live in Ohio, but because "unknown is not equal to OH" cannot be answered,
--   and WHERE keeps only what is definitely true.
WHERE HOME_STATE <> 'OH';

-- Example 4-6.7
-- SELECT: count the rooms above the line.
SELECT COUNT(*) AS ROOMS_OVER_500

-- FROM: the table being counted.
FROM ROOM

-- WHERE: the first half of what looks like a complete split of the data.
WHERE MONTHLY_RENT > 500.00;

-- SELECT: count the rooms at or below the line.
SELECT COUNT(*) AS ROOMS_500_OR_LESS

-- FROM: the same table.
FROM ROOM

-- WHERE: the opposite condition. The two counts come to 3 and 1, but ROOM holds
--   5 rows - the unpriced room fell out of BOTH halves, because a comparison
--   against a null is unknown either way. Whenever two opposite filters fail to
--   add up to the row count, look for nulls.
WHERE MONTHLY_RENT <= 500.00;

-- Example 4-6.8
-- SELECT: four numbers that only agree with each other when there are no nulls.
--   COUNT(*) counts rows, so it reports all five rooms.
SELECT COUNT(*) AS ALL_ROOMS,

--   COUNT(column) counts values, so it reports the four rooms that have a rent.
       COUNT(MONTHLY_RENT) AS RENTS_RECORDED,

--   SUM skips the null and adds those same four values.
       SUM(MONTHLY_RENT) AS TOTAL_RENT,

--   AVG divides the total by 4, not by 5. That is the trap: the average is of the
--     rooms that have a rent, which is not the same as the average across all
--     rooms - and no error is raised to tell you which one you got.
       AVG(MONTHLY_RENT) AS AVERAGE_RENT

-- FROM: the table all four are computed over.
FROM ROOM;

-- >>> EXERCISE 15  (section 4-6, seed: staywell_full)
-- Hint: Run it unchanged first. The page answers "Statement ran. 1 row affected." -- that 1 belongs to the UPDATE, and the absence of any result table is the SELECT matching nothing. Now swap the comparison for the null-aware test and you get a real grid: one row, S003, with NULL in HOME_STATE.
-- Step 1: clear one home state so there is a null to study.
UPDATE STUDENT
SET HOME_STATE = NULL
WHERE STUDENT_ID = 'S003';

-- Step 2: this is meant to list the students whose home state is missing.
-- Run the box exactly as written first. No result table will appear at all,
-- because the condition below matches nothing. Then repair the condition.
SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE = NULL;
