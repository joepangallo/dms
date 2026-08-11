-- ======================================================================
-- Module 4 · Module summary, key terms, review questions, case exercises
-- ======================================================================
--
-- Sections: Summary, Key Terms, Review, Case Exercises
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Module Summary
-- ----------------------------------------------------------------------


-- Example Summary.1
-- SELECT: the grouping column and a count, given a readable heading.
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS

-- FROM: the table being read.
FROM ITEM

-- WHERE: filters rows first - only items dearer than 12 reach a pile.
WHERE PRICE > 12

-- GROUP BY: one pile per category, built from the surviving rows.
GROUP BY CATEGORY

-- HAVING: filters the piles. >= 1 keeps every pile that exists, so it changes
--   nothing here - it is written to show where the clause goes.
HAVING COUNT(*) >= 1

-- ORDER BY: two keys - biggest count first, then category name to break ties.
ORDER BY NUM_ITEMS DESC, CATEGORY;

-- >>> EXERCISE 17  (section Summary, seed: kimtay_full)
-- Hint: Run it as written -- one row, Habitat with 2 items averaging 46.37. Then change HAVING COUNT(*) > 1 to >= 1 and the other three categories reappear, in the order Habitat, Food, Grooming, Accessory.
SELECT CATEGORY, COUNT(*) AS NUM_ITEMS, AVG(PRICE) AS AVG_PRICE
FROM ITEM
WHERE PRICE BETWEEN 10 AND 70
GROUP BY CATEGORY
HAVING COUNT(*) > 1
ORDER BY AVG_PRICE DESC;

-- ----------------------------------------------------------------------
-- Key Terms
-- ----------------------------------------------------------------------


-- >>> EXERCISE 18  (section Key Terms, seed: kimtay_full)
-- Hint: The starter returns four rows -- Accessory, Food, Grooming, Habitat. The worked answer groups instead of de-duplicating, so you also see that Habitat holds 2 items and the rest hold 1.
SELECT DISTINCT CATEGORY
FROM ITEM
ORDER BY CATEGORY;

-- ----------------------------------------------------------------------
-- Review Questions
-- ----------------------------------------------------------------------


-- >>> EXERCISE 19  (section Review, seed: both_full)
-- Hint: Both databases are loaded, so every review statement runs here -- all 11 tables: REP, CUSTOMER, ITEM, INVOICE, INVOICE_LINE, MANAGER, PROPERTY, ROOM, STUDENT, LEASE, PAYMENT.
-- Paste a statement from a review question here, then run it.
SELECT * FROM ITEM;

-- ----------------------------------------------------------------------
-- Case Exercises
-- ----------------------------------------------------------------------


-- >>> EXERCISE 20  (section Case Exercises, seed: both_full)
-- Hint: The starter lists all five items, priciest first. Add one clause to answer Exercise 1; the worked answer is one click away when you want to compare.
-- Both databases are loaded. Exercise 1 starter:
SELECT ITEM_ID, DESCRIPTION, PRICE
FROM ITEM
ORDER BY PRICE DESC;
