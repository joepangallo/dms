-- ======================================================================
-- Module 4 · Nulls
-- ======================================================================
--
-- Sections: 4-6
-- Load first: 00-setup-both.sql   (has every table this file touches)
--             individual seeds used here: staywell_full
--
-- Examples are the statements shown in the lesson. Exercises are the
-- starter queries from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================

-- ----------------------------------------------------------------------
-- Section 4-6 -- Nulls
-- ----------------------------------------------------------------------

-- Example 4-6.1
UPDATE STUDENT
SET HOME_STATE = NULL
WHERE STUDENT_ID = 'S003';

SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
ORDER BY STUDENT_ID;

-- Example 4-6.2
SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE = NULL;

-- Example 4-6.3
SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE IS NULL;

-- Example 4-6.4
SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE IS NOT NULL
ORDER BY STUDENT_ID;

-- Example 4-6.5
UPDATE ROOM
SET MONTHLY_RENT = NULL
WHERE PROPERTY_ID = 'P200' AND ROOM_NUM = '202';

SELECT PROPERTY_ID, ROOM_NUM, MONTHLY_RENT, MONTHLY_RENT * 9 AS NINE_MONTH_TOTAL
FROM ROOM
WHERE PROPERTY_ID = 'P200'
ORDER BY ROOM_NUM;

-- Example 4-6.6
SELECT STUDENT_ID, LAST_NAME, HOME_STATE
FROM STUDENT
WHERE HOME_STATE <> 'OH';

-- Example 4-6.7
SELECT COUNT(*) AS ROOMS_OVER_500
FROM ROOM
WHERE MONTHLY_RENT > 500.00;

SELECT COUNT(*) AS ROOMS_500_OR_LESS
FROM ROOM
WHERE MONTHLY_RENT <= 500.00;

-- Example 4-6.8
SELECT COUNT(*) AS ALL_ROOMS,
       COUNT(MONTHLY_RENT) AS RENTS_RECORDED,
       SUM(MONTHLY_RENT) AS TOTAL_RENT,
       AVG(MONTHLY_RENT) AS AVERAGE_RENT
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
