-- ======================================================================
-- Module 8 · Selecting Multiple Rows with a Procedure
-- ======================================================================
--
-- Sections: 8-7
-- Load first: 00-setup-both.sql   (has every table this file touches)
--
-- Examples are the statements shown in the lesson, with the page's own
-- line-by-line commentary kept intact. Exercises are the starter queries
-- from the live sandboxes -- edit them and re-run.
-- Solutions are in 90-exercise-solutions.sql.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-7  Selecting Multiple Rows with a Procedure
-- ----------------------------------------------------------------------


-- Example 8-7.1
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- SELECT ... INTO: the one-row form you have already used. It works only when
--   the query returns exactly one row, which is why it is safe on a primary key
--   lookup and dangerous on anything else.
SELECT BALANCE, CREDIT_LIMIT

    -- INTO: two columns land in two variables, matched by position.
    INTO v_balance, v_credit_limit

    -- FROM: the customer table this lookup reads.
    FROM CUSTOMER

    -- Filtering on the key is what guarantees the single row.
    WHERE CUSTOMER_NUM = i_customer_num;

-- >>> EXERCISE 24  (section 8-7, seed: kimtay_full)
-- Hint: Two rows come back: 1120 Access Pet Center and 1310 Companion Care Clinic. Ask yourself which one a single set of variables could hold.
-- Rep 20's territory: the CUSTOMER rows whose REP_NUM is '20'.
-- Run this and count the rows. That count is why a cursor exists.
SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
FROM CUSTOMER
WHERE REP_NUM = '20'
ORDER BY CUSTOMER_NUM;

-- Example 8-7.3
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DECLARE ... CURSOR FOR: a cursor is a query held ready, so the procedure can
--   walk its rows ONE AT A TIME. This line only defines it - nothing runs yet,
--   and the SELECT below is not executed until OPEN.
DECLARE cust_cursor CURSOR FOR

    -- The query the cursor will walk. Four columns, so four variables will be
    --   needed to receive each row.
    SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT

    -- FROM: the customer table the cursor's query reads.
    FROM CUSTOMER

    -- A cursor query may use a parameter exactly like any other query.
    WHERE REP_NUM = i_rep_num

    -- ORDER BY matters more than usual here: it fixes the order the rows will be
    --   handed to you in, one by one.
    ORDER BY CUSTOMER_NUM;

-- Example 8-7.4
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- OPEN: runs the cursor's query and positions it just BEFORE the first row.
--   Nothing has been read yet; the cursor is simply ready to start.
OPEN cust_cursor;

-- Example 8-7.5
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- FETCH ... INTO: moves the cursor on by one row and copies that row's values
--   into the listed variables. The variables must match the cursor's SELECT list
--   in number, order and type. One FETCH gets exactly one row, which is why a
--   loop is needed to reach them all.
FETCH cust_cursor INTO v_customer_num, v_customer_name,
                       v_balance, v_credit_limit;

-- Example 8-7.6
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DECLARE ... DEFAULT: a flag variable, starting at 0 meaning "not finished".
DECLARE v_done INT DEFAULT 0;

-- CONTINUE HANDLER FOR NOT FOUND: when a FETCH runs past the last row, NOT FOUND
--   is raised. This handler sets the flag and lets execution carry on, which is
--   how the loop learns that the rows have run out.
DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

-- LOOP with a LABEL: cust_loop names the loop so it can be left by name.
cust_loop: LOOP

    -- Read the next row into the variables.
    FETCH cust_cursor INTO v_customer_num, v_customer_name,
                           v_balance, v_credit_limit;

    -- Test the flag IMMEDIATELY after the fetch. If the fetch failed, the
    --   variables still hold the PREVIOUS row, so processing them here would
    --   duplicate the last row - a classic off-by-one in cursor code.
    IF v_done = 1 THEN

        -- LEAVE: jumps out of the named loop. Without it this runs forever.
        LEAVE cust_loop;
    -- END IF: when the flag is still 0, there is no LEAVE, so control falls
    --   straight through to the row-processing step below.
    END IF;

    -- work on the row that was retrieved goes here
-- END LOOP: sends control back to the top for the next row.
END LOOP cust_loop;

-- Example 8-7.7
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CLOSE: releases the cursor and the resources the server was holding for it.
--   Always close what you open, so a long-running procedure does not accumulate
--   open cursors.
CLOSE cust_cursor;

-- Example 8-7.8
-- DROP TABLE IF EXISTS: clear out any table left behind by an earlier run, so
--   this script can be re-run from the top.
DROP TABLE IF EXISTS CUST_REVIEW;

-- CREATE TABLE: somewhere for the procedure to write its results. A stored
--   procedure that loops over rows usually has to put its output somewhere, and
--   a small result table is the simplest place.
CREATE TABLE CUST_REVIEW
    (CUSTOMER_NUM CHAR(4),
     CUSTOMER_NAME VARCHAR(35),

     -- The computed figure the procedure will work out per customer.
     AVAILABLE_CREDIT DECIMAL(9,2),

     -- The verdict, chosen by an IF inside the loop.
     REVIEW_NOTE VARCHAR(10));

-- Example 8-7.9
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: makes the script re-runnable. Without it, the
--   second run fails because REP_CREDIT_REVIEW already exists.
DROP PROCEDURE IF EXISTS REP_CREDIT_REVIEW //

-- CREATE PROCEDURE: stage one of building a cursor procedure - declarations only,
--   with an OPEN and CLOSE and nothing in between. Build it in stages like this
--   and each piece can be checked before the next is added.
CREATE PROCEDURE REP_CREDIT_REVIEW (IN i_rep_num CHAR(2))
BEGIN

    -- The finished flag.
    DECLARE v_done INT DEFAULT 0;

    -- One variable per column the cursor returns, declared with matching types.
    DECLARE v_customer_num CHAR(4);
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_balance DECIMAL(9,2);
    DECLARE v_credit_limit DECIMAL(9,2);

    -- Two more for values the procedure will calculate rather than fetch.
    DECLARE v_available DECIMAL(9,2);
    DECLARE v_note VARCHAR(10);

    -- The cursor declaration. MySQL demands a strict order inside a procedure:
    --   variables first, then cursors, then handlers. Get it wrong and the
    --   procedure will not compile.
    DECLARE cust_cursor CURSOR FOR

        -- The same four columns walked through earlier in this section.
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT

        -- FROM: the customer table this procedure reviews.
        FROM CUSTOMER

        -- WHERE: the rep parameter, so one procedure serves every rep.
        WHERE REP_NUM = i_rep_num

        -- ORDER BY: keeps the fetch order predictable, as before.
        ORDER BY CUSTOMER_NUM;

    -- The handler comes last of the three, and arms the finished flag.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- Open and close with nothing between them: this version does no work, but it
    --   proves the declarations are correct.
    OPEN cust_cursor;
    CLOSE cust_cursor;
END //

DELIMITER ;

-- Example 8-7.10
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- OPEN: run the query and get ready to read.
    OPEN cust_cursor;

    -- The loop skeleton: fetch, test, leave. Stage two adds the walking, still
    --   without doing anything to the rows.
    cust_loop: LOOP

        -- FETCH: read the next row into the variables, same call as before.
        FETCH cust_cursor INTO v_customer_num, v_customer_name,
                               v_balance, v_credit_limit;

        -- The exit test goes straight after the FETCH and before any processing.
        IF v_done = 1 THEN
            LEAVE cust_loop;
        -- END IF: with the flag still 0, there is no row work yet in this stage,
        --   so control falls straight through to the bottom of the loop.
        END IF;
    -- END LOOP: sends control back to the top for the next FETCH; stage three
    --   will add row-processing work before this line.
    END LOOP cust_loop;

    -- CLOSE: tidy up once the rows are exhausted.
    CLOSE cust_cursor;

-- Example 8-7.11
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
DELIMITER //

-- DROP PROCEDURE IF EXISTS: makes the script re-runnable, same reason as
--   every earlier version of this procedure.
DROP PROCEDURE IF EXISTS REP_CREDIT_REVIEW //

-- CREATE PROCEDURE: the finished version - declarations, cursor, loop, and real
--   work inside the loop.
CREATE PROCEDURE REP_CREDIT_REVIEW (IN i_rep_num CHAR(2))
BEGIN

    -- The finished flag, starting at 0.
    DECLARE v_done INT DEFAULT 0;

    -- One variable per cursor column...
    DECLARE v_customer_num CHAR(4);
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_balance DECIMAL(9,2);
    DECLARE v_credit_limit DECIMAL(9,2);

    -- ...plus two for the values computed inside the loop.
    DECLARE v_available DECIMAL(9,2);
    DECLARE v_note VARCHAR(10);

    -- The cursor: the set of rows to be walked, one at a time.
    DECLARE cust_cursor CURSOR FOR

        -- The same four columns as the earlier stages, ready for the FETCH below.
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT

        -- FROM: the customer table, same as every version of this cursor.
        FROM CUSTOMER

        -- WHERE: this call's rep parameter.
        WHERE REP_NUM = i_rep_num

        -- ORDER BY: keeps the walk order predictable, as before.
        ORDER BY CUSTOMER_NUM;

    -- The handler that trips the flag when the rows run out.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- Run the query and position before the first row.
    OPEN cust_cursor;

    -- The walking loop.
    cust_loop: LOOP

        -- Read one row into the variables.
        FETCH cust_cursor INTO v_customer_num, v_customer_name,
                               v_balance, v_credit_limit;

        -- Stop as soon as the fetch fails, before processing stale values.
        IF v_done = 1 THEN
            LEAVE cust_loop;
        -- END IF: with the flag still 0, control falls through to the row work
        --   below instead of leaving the loop.
        END IF;

        -- Row-at-a-time work, part 1: a calculation.
        SET v_available = v_credit_limit - v_balance;

        -- Row-at-a-time work, part 2: a DECISION. This is what a cursor buys you -
        --   plain SQL can compute the number, but choosing different actions per
        --   row is procedural logic.
        IF v_available < 5000 THEN
            -- SET: under $5,000 of available credit, so this row gets flagged
            --   for a follow-up call.
            SET v_note = 'Call rep';
        -- ELSE: everyone else clears the $5,000 threshold, so no follow-up is
        --   logged.
        ELSE
            SET v_note = 'No action';
        -- END IF: the verdict now sits in v_note, ready for the INSERT below.
        END IF;

        -- Row-at-a-time work, part 3: write the verdict out. One INSERT per pass
        --   of the loop, so one result row per customer.
        INSERT INTO CUST_REVIEW
               (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
        VALUES (v_customer_num, v_customer_name, v_available, v_note);
    -- END LOOP: sends control back to the top for the next customer.
    END LOOP cust_loop;

    -- Release the cursor.
    CLOSE cust_cursor;
END //

DELIMITER ;

-- Example 8-7.12
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- CALL: run the review for one rep. The procedure returns nothing directly -
--   its output is the rows it wrote into CUST_REVIEW.
CALL REP_CREDIT_REVIEW('20');

-- SELECT: read the results table to see what the loop produced, one row per
--   customer the cursor walked.
SELECT * FROM CUST_REVIEW

-- ORDER BY: the same customer order the cursor walked, for an easy check.
ORDER BY CUSTOMER_NUM;

-- Example 8-7.13
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DECLARE ... CURSOR FOR: a cursor's query can be as complex as any other. This
--   one joins four tables, and the procedure still walks the result one row at a
--   time exactly as before.
DECLARE line_cursor CURSOR FOR

    -- Three stored columns and one calculated column. A cursor column does not
    --   have to correspond to anything stored.
    SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
           L.NUM_ORDERED * L.QUOTED_PRICE

    -- FROM: the customer table, aliased C for the joins below.
    FROM CUSTOMER C

    -- Hop 1 - customer to invoice.
    JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM

    -- Hop 2 - invoice to line item.
    JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM

    -- Hop 3 - line item to item.
    JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID

    -- The parameter filters the joined rows.
    WHERE C.REP_NUM = i_rep_num

    -- Fixes the order the rows will be fetched in.
    ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- >>> EXERCISE 25  (section 8-7, seed: kimtay_full)
-- Hint: Rep 20 gives two rows, both on invoice 50710: Grain-Free Dry Food 30lb at 127.5 and Nylon Dog Leash 6ft at 23.98. Rep 65 also gives two rows, both on invoice 50711: Grain-Free Dry Food 30lb at 85.0 and Small Animal Grooming Kit at 15.25. Drop the ITEM join and the query fails, because DESCRIPTION has nowhere to come from.
-- The cursor's query with i_rep_num written out as '20'.
-- Run it, then change '20' to '65' and predict the rows before you run it again.
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
       L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
WHERE C.REP_NUM = '20'
ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Example 8-7.15
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DROP TABLE IF EXISTS: make the script re-runnable.
DROP TABLE IF EXISTS BIG_LINE_LOG;

-- CREATE TABLE: the destination for whatever the procedure finds. Its columns
--   match the four the cursor returns.
CREATE TABLE BIG_LINE_LOG
    (CUSTOMER_NAME VARCHAR(35),
     INVOICE_NUM CHAR(5),
     DESCRIPTION VARCHAR(30),
     LINE_TOTAL DECIMAL(9,2));

DELIMITER //

-- DROP PROCEDURE IF EXISTS: makes the script re-runnable. Without it, the
--   second run fails because BIG_LINE_ITEMS already exists.
DROP PROCEDURE IF EXISTS BIG_LINE_ITEMS //

-- CREATE PROCEDURE: two parameters this time, and both are used inside the
--   cursor's query rather than in the loop.
CREATE PROCEDURE BIG_LINE_ITEMS (IN i_rep_num CHAR(2),
                                 IN i_min_total DECIMAL(7,2))
BEGIN

    -- The finished flag.
    DECLARE v_done INT DEFAULT 0;

    -- One variable per cursor column, in the same order.
    DECLARE v_customer_name VARCHAR(35);
    DECLARE v_invoice_num CHAR(5);
    DECLARE v_description VARCHAR(30);
    DECLARE v_line_total DECIMAL(9,2);

    -- The cursor over a four-table join.
    DECLARE line_cursor CURSOR FOR

        -- The same three stored columns and one calculated column as the
        --   walkthrough above.
        SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
               L.NUM_ORDERED * L.QUOTED_PRICE

        -- FROM: the customer table, aliased C, same starting point as before.
        FROM CUSTOMER C

        -- Hop 1 - customer to invoice.
        JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM

        -- Hop 2 - invoice to line item.
        JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM

        -- Hop 3 - line item to item.
        JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID

        -- WHERE: the rep parameter, same as the earlier cursors.
        WHERE C.REP_NUM = i_rep_num

        -- The second parameter filters on the CALCULATION, not on a stored
        --   column. Doing the filtering here rather than inside the loop means
        --   fewer rows are ever fetched - the database is better at discarding
        --   rows than your loop is.
          AND L.NUM_ORDERED * L.QUOTED_PRICE >= i_min_total

        -- ORDER BY: fixes the fetch order for the loop, same as the earlier
        --   cursors.
        ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

    -- The handler that ends the loop.
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- Run the query.
    OPEN line_cursor;

    -- Walk the rows.
    line_loop: LOOP

        -- FETCH: read the next row into the four variables, matched by position.
        FETCH line_cursor INTO v_customer_name, v_invoice_num,
                               v_description, v_line_total;

        -- Test the flag right after the FETCH, before the possibly stale values
        --   get used.
        IF v_done = 1 THEN
            LEAVE line_loop;
        -- END IF: with the flag still 0, control falls through to the row work
        --   below.
        END IF;

        -- The only work per row: copy it into the log table. Because the cursor
        --   already filtered, no IF is needed here.
        INSERT INTO BIG_LINE_LOG
               (CUSTOMER_NAME, INVOICE_NUM, DESCRIPTION, LINE_TOTAL)
        VALUES (v_customer_name, v_invoice_num, v_description, v_line_total);
    -- END LOOP: sends control back to the top for the next line item.
    END LOOP line_loop;

    -- Tidy up.
    CLOSE line_cursor;
END //

DELIMITER ;

-- CALL: rep 65, lines worth 50.00 or more. Change either argument and the same
--   procedure answers a different question.
CALL BIG_LINE_ITEMS('65', 50.00);

-- >>> EXERCISE 26  (section 8-7, seed: kimtay_full)
-- Hint: One row: invoice 50711, Grain-Free Dry Food 30lb, 2 at 42.50, a line total of 85.0. Change 50 to 10 and a second line appears, Small Animal Grooming Kit at 15.25.
-- The cursor query behind BIG_LINE_ITEMS('65', 50.00),
-- with the parameters written out as literals.
SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
       L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
FROM CUSTOMER C
JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
WHERE C.REP_NUM = '65'
  AND L.NUM_ORDERED * L.QUOTED_PRICE >= 50
ORDER BY I.INVOICE_NUM, T.DESCRIPTION;

-- Example 8-7.17
-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.
-- DECLARE ... CURSOR FOR: a cursor over a GROUPED query. Each row the cursor
--   hands back is a summary of several underlying rows, which is fine - the
--   cursor neither knows nor cares how its query was built.
DECLARE invoice_cursor CURSOR FOR

    -- Two grouping columns and one aggregate.
    SELECT I.INVOICE_NUM, C.CUSTOMER_NAME,
           SUM(L.NUM_ORDERED * L.QUOTED_PRICE)

    -- FROM: the invoice table this grouped query starts from.
    FROM INVOICE I

    -- Hop 1 - invoice to customer, for the name.
    JOIN CUSTOMER C ON I.CUSTOMER_NUM = C.CUSTOMER_NUM

    -- Hop 2 - invoice to its line items, for the money.
    JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM

    -- GROUP BY: one row per invoice, so the cursor walks invoices rather than
    --   lines. Every non-aggregated column in the SELECT list appears here.
    GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME

    -- ORDER BY: fixes the invoice order the cursor will walk, same as any
    --   other cursor query.
    ORDER BY I.INVOICE_NUM;

-- >>> EXERCISE 27  (section 8-7, seed: kimtay_full)
-- Hint: Three rows, one per invoice: 50710 at 151.48, 50711 at 100.25, 50712 at 120.49. A cursor over this query would loop three times.
-- One row per invoice: this is what a cursor over a GROUP BY hands the loop.
SELECT I.INVOICE_NUM, C.CUSTOMER_NAME,
       SUM(L.NUM_ORDERED * L.QUOTED_PRICE) AS INVOICE_TOTAL
FROM INVOICE I
JOIN CUSTOMER C ON I.CUSTOMER_NUM = C.CUSTOMER_NUM
JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
GROUP BY I.INVOICE_NUM, C.CUSTOMER_NAME
ORDER BY I.INVOICE_NUM;

-- >>> EXERCISE 28  (section 8-7, seed: kimtay_full)
-- Hint: You should get the same two rows the procedure produced: 1120 with 3987.5 and 'Call rep', 1310 with 10000 and 'No action'. The leading DROP TABLE IF EXISTS is what lets you press Run a second time without an error.
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
