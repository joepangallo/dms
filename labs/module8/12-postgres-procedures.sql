-- ======================================================================
-- Module 8 · Postgres/PL-pgSQL translations of the MySQL, Oracle, and
--             T-SQL procedure and cursor examples
-- ======================================================================
--
-- HAND-WRITTEN, NOT REGENERATED. Every other numbered file in this folder
-- is produced by tools/gen-module-labs.py straight from db.html, and a
-- re-run of that script reproduces them byte for byte. This file is not
-- sourced from the page at all -- it exists because most of Module 8's
-- own code is deliberately non-portable (MySQL's DELIMITER/CALL syntax,
-- Oracle's PL/SQL, SQL Server's T-SQL), and none of it runs on the
-- PostgreSQL engine this course's Supabase projects use. Editing
-- gen-module-labs.py and re-running it will NOT touch this file, and
-- re-running it will not regenerate this one either -- keep it by hand.
--
-- Every procedure below was written, applied, and CALLed against a real
-- Supabase (Postgres 17) project in this session -- not merely reasoned
-- about. Where the straightforward translation of the MySQL/Oracle
-- original did NOT work on the first try, both the broken attempt and
-- the working fix are shown, with the exact error Postgres raised. Load
-- 00-setup-both.sql first; everything here reads and writes the same
-- KimTay tables the rest of Module 8 uses.
--
-- Skim "Six things Postgres does differently" in this folder's README
-- before reading the procedures below -- it names the general rules;
-- this file is where you see each one caught in the act.
-- ======================================================================


-- ----------------------------------------------------------------------
-- Section 8-4  Stored Procedures  --  MySQL originals: 04-stored-procedures-mysql.sql
-- ----------------------------------------------------------------------

-- SHOW_REP_COUNT, translated literally first, to show WHY it cannot stay
--   a procedure. MySQL lets a stored routine end in a bare SELECT and
--   streams that result straight back to the caller. PL/pgSQL procedures
--   have no such passthrough -- a bare SELECT with nothing to receive it
--   is simply illegal:
--     CREATE PROCEDURE SHOW_REP_COUNT() LANGUAGE plpgsql AS $$
--     BEGIN
--         SELECT COUNT(*) AS REP_COUNT FROM REP;
--     END; $$;
--   Calling it raises 42601: "query has no destination for result data",
--   with a hint pointing at PERFORM -- which would run the query and
--   throw the answer away, the opposite of what this routine is for.
-- The fix is to stop pretending it is a MySQL-shaped procedure: make it
--   a FUNCTION that RETURNS TABLE, and call it the way Postgres expects a
--   value-returning routine to be called -- SELECT * FROM ..., not CALL.
-- DROP FUNCTION, not DROP PROCEDURE -- the finished routine below is a
--   function, so that is the kind of catalog entry a re-run needs to drop.
DROP FUNCTION IF EXISTS SHOW_REP_COUNT();
CREATE OR REPLACE FUNCTION SHOW_REP_COUNT()
RETURNS TABLE(REP_COUNT BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY SELECT COUNT(*) FROM REP;
END;
$$;

-- SELECT * FROM ...(): the Postgres way to run a set-returning routine
--   and read what it returns, in place of MySQL's CALL SHOW_REP_COUNT().
SELECT * FROM SHOW_REP_COUNT();


-- BAD_REP_NAME: the parameter-shadowing bug, translated as literally as
--   possible -- an IN parameter named REP_NUM, colliding with the REP_NUM
--   column, compared to itself in WHERE.
DROP PROCEDURE IF EXISTS BAD_REP_NAME(CHAR(2), VARCHAR(20));
CREATE OR REPLACE PROCEDURE BAD_REP_NAME(
    IN  REP_NUM     CHAR(2),
    OUT o_last_name VARCHAR(20))
LANGUAGE plpgsql
AS $$
BEGIN
    -- WHERE REP_NUM = REP_NUM: identical bug to the MySQL original. MySQL
    --   compiles this and quietly matches every row, handing back
    --   whichever last name it happened to read first -- wrong, but
    --   silent. PL/pgSQL compiles it too (CREATE PROCEDURE succeeds with
    --   no complaint), but the FIRST time it actually runs, the planner
    --   raises 42702: "column reference \"rep_num\" is ambiguous",
    --   detail: "It could refer to either a PL/pgSQL variable or a table
    --   column." Postgres refuses outright rather than guessing -- worse
    --   ergonomics up front, a safer engine in the end.
    SELECT LAST_NAME
    INTO   o_last_name
    FROM   REP
    WHERE  REP_NUM = REP_NUM;
END;
$$;
-- CALL BAD_REP_NAME('35', NULL); -- left commented: this is the one call
--   in this file that is SUPPOSED to fail. Uncomment it to see the
--   42702 error yourself.


-- DISP_REP_NAME: the fixed version. The i_ prefix convention that avoids
--   the collision in MySQL avoids the exact same collision here.
DROP PROCEDURE IF EXISTS DISP_REP_NAME(CHAR(2), VARCHAR(20), VARCHAR(20));
CREATE OR REPLACE PROCEDURE DISP_REP_NAME(
    IN  i_rep_num    CHAR(2),
    OUT o_last_name  VARCHAR(20),
    OUT o_first_name VARCHAR(20))
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT LAST_NAME, FIRST_NAME
    INTO   o_last_name, o_first_name
    FROM   REP
    WHERE  REP_NUM = i_rep_num;
END;
$$;

-- CALL: Postgres has no @session-variable mechanism at all, so there is
--   nothing to declare before calling and nothing to SELECT afterward.
--   Every OUT parameter simply comes back as a column of the CALL's own
--   result row -- pass a placeholder (NULL works) for each OUT slot, in
--   position, and read the answer directly off the one-row result.
CALL DISP_REP_NAME('35', NULL, NULL);


-- GET_CREDIT_AVAILABLE: a computed OUT value, DECLARE-d locals included.
--   Word-for-word the same shape as the MySQL version, DECLARE and all --
--   PL/pgSQL's variable declarations sit in a DECLARE block the same way.
DROP PROCEDURE IF EXISTS GET_CREDIT_AVAILABLE(CHAR(4), DECIMAL(9,2));
CREATE OR REPLACE PROCEDURE GET_CREDIT_AVAILABLE(
    IN  i_customer_num CHAR(4),
    OUT o_available    DECIMAL(9,2))
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance      DECIMAL(9,2);
    v_credit_limit DECIMAL(9,2);
BEGIN
    SELECT BALANCE, CREDIT_LIMIT
    INTO   v_balance, v_credit_limit
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    -- :=  is PL/pgSQL's assignment operator; MySQL's SET works too as an
    --   alias, but := is the form you will see in the wild.
    o_available := v_credit_limit - v_balance;
END;
$$;

CALL GET_CREDIT_AVAILABLE('1420', NULL);  -- 1179.25
CALL GET_CREDIT_AVAILABLE('1310', NULL);  -- 10000.00, the whole limit


-- ADD_SALE_TO_COMMISSION: the INOUT case. Postgres procedures support
--   INOUT directly, and CALL passes the starting value as a literal
--   argument in that slot -- no MySQL-style SET @comm = ... beforehand.
DROP PROCEDURE IF EXISTS ADD_SALE_TO_COMMISSION(CHAR(2), DECIMAL(9,2), DECIMAL(8,2));
CREATE OR REPLACE PROCEDURE ADD_SALE_TO_COMMISSION(
    IN    i_rep_num     CHAR(2),
    IN    i_sale_amount DECIMAL(9,2),
    INOUT io_commission DECIMAL(8,2))
LANGUAGE plpgsql
AS $$
DECLARE
    v_rate DECIMAL(4,2);
BEGIN
    SELECT RATE
    INTO   v_rate
    FROM   REP
    WHERE  REP_NUM = i_rep_num;

    io_commission := io_commission + (i_sale_amount * v_rate);
END;
$$;

-- CALL: the old value goes in as a literal, the new one comes back in the
--   same result column. 39355.00 + (1200.00 * 0.07) = 39439.00.
CALL ADD_SALE_TO_COMMISSION('35', 1200.00, 39355.00);


-- SHOW CREATE PROCEDURE has no Postgres equivalent as a single statement;
--   \df+ routine_name in psql, or pg_get_functiondef(oid) from SQL, are
--   the nearest matches. INFORMATION_SCHEMA.ROUTINES, though, is real
--   ANSI SQL and Postgres implements it -- only DATABASE() (MySQL's "the
--   database I'm connected to") needs swapping for current_schema().
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM   INFORMATION_SCHEMA.ROUTINES
WHERE  ROUTINE_SCHEMA = current_schema()
ORDER  BY ROUTINE_NAME;


-- ----------------------------------------------------------------------
-- Section 8-5  Error Handling  --  MySQL originals: 05-error-handling.sql
-- ----------------------------------------------------------------------

-- GET_CUST_BALANCE_UNSAFE: the unhandled lookup, translated literally.
--   No STRICT, no handler -- exactly the naive version the lesson warns
--   about.
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE_UNSAFE(CHAR(4), DECIMAL(9,2));
CREATE OR REPLACE PROCEDURE GET_CUST_BALANCE_UNSAFE(
    IN  i_customer_num CHAR(4),
    OUT o_balance      DECIMAL(9,2))
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT BALANCE
    INTO   o_balance
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;
END;
$$;

-- The MySQL lesson's whole point is that a miss here leaves o_balance
--   holding the PREVIOUS customer's stale value, silently. Tested
--   directly against Postgres (two CALLs sharing one PL/pgSQL variable,
--   the closest equivalent to MySQL's session variable): a miss does NOT
--   leave the old value in place. Plain SELECT INTO (no STRICT) resets
--   the target to NULL when zero rows match, every time. Safer than
--   MySQL's default by accident, but still silent -- nothing raises, and
--   a caller that doesn't check for NULL is exactly as fooled as the
--   MySQL caller was.
CALL GET_CUST_BALANCE_UNSAFE('1120', NULL);  -- 3512.50
CALL GET_CUST_BALANCE_UNSAFE('9999', NULL);  -- NULL, not 3512.50 -- and no error


-- GET_CUST_BALANCE: the safe version. MySQL's DECLARE CONTINUE HANDLER
--   resumes execution on the very next line after the failing statement --
--   there is no PL/pgSQL equivalent to "resume", because catching an
--   exception in PL/pgSQL always means the surrounding BEGIN...END block
--   is abandoned once the handler finishes. To get MySQL's CONTINUE
--   behaviour -- keep going with the REST of the procedure after a
--   miss -- wrap only the risky statement in its OWN nested block, so
--   only that inner block is abandoned.
DROP PROCEDURE IF EXISTS GET_CUST_BALANCE(CHAR(4), DECIMAL(9,2), VARCHAR(60));
CREATE OR REPLACE PROCEDURE GET_CUST_BALANCE(
    IN  i_customer_num CHAR(4),
    OUT o_balance      DECIMAL(9,2),
    OUT o_status       VARCHAR(60))
LANGUAGE plpgsql
AS $$
BEGIN
    -- Known starting values, same reasoning as the MySQL version: nothing
    --   stale can survive past this point.
    o_balance := NULL;
    o_status  := 'OK';

    -- STRICT turns a plain SELECT INTO into one that raises instead of
    --   silently returning NULL or the first of several rows. Without
    --   STRICT, NO_DATA_FOUND and TOO_MANY_ROWS never fire at all --
    --   this keyword is the one line standing between GET_CUST_BALANCE
    --   and GET_CUST_BALANCE_UNSAFE above.
    BEGIN
        SELECT BALANCE
        INTO STRICT o_balance
        FROM   CUSTOMER
        WHERE  CUSTOMER_NUM = i_customer_num;
    EXCEPTION
        -- NO_DATA_FOUND: the exact same condition name MySQL's NOT FOUND
        --   handler is named after -- PL/pgSQL borrowed it from Oracle,
        --   and MySQL's spelling happens to be close enough to guess.
        WHEN NO_DATA_FOUND THEN
            o_status := 'No customer numbered ' || i_customer_num;
        -- TOO_MANY_ROWS: STRICT's other failure mode, covered in the
        --   Oracle section below -- MySQL lumps both of these under one
        --   NOT FOUND / SQLEXCEPTION distinction; Postgres and Oracle
        --   both name them separately.
        WHEN TOO_MANY_ROWS THEN
            o_status := 'More than one customer matched ' || i_customer_num;
    END;
END;
$$;

CALL GET_CUST_BALANCE('1120', NULL, NULL);  -- 3512.50, 'OK'
CALL GET_CUST_BALANCE('9999', NULL, NULL);  -- NULL, 'No customer numbered 9999'


-- GET_BALANCE_BY_CITY: the too-many-rows case. Here the MySQL original
--   uses an EXIT handler, which already matches PL/pgSQL's normal
--   behaviour -- an EXCEPTION clause on the block that contains the
--   failing statement stops that block and nothing after it runs, same
--   as EXIT. No nested block is needed this time.
DROP PROCEDURE IF EXISTS GET_BALANCE_BY_CITY(VARCHAR(20), DECIMAL(9,2), VARCHAR(60));
CREATE OR REPLACE PROCEDURE GET_BALANCE_BY_CITY(
    IN  i_city    VARCHAR(20),
    OUT o_balance DECIMAL(9,2),
    OUT o_status  VARCHAR(60))
LANGUAGE plpgsql
AS $$
BEGIN
    o_balance := NULL;
    o_status  := 'OK';

    SELECT BALANCE
    INTO STRICT o_balance
    FROM   CUSTOMER
    WHERE  CITY = i_city;
EXCEPTION
    -- WHEN OTHERS: the same catch-all MySQL's SQLEXCEPTION names, and it
    --   catches TOO_MANY_ROWS along with everything else here, matching
    --   the MySQL original's single blanket handler.
    WHEN OTHERS THEN
        o_status := 'Lookup failed for ' || i_city || ' - check the city';
END;
$$;

CALL GET_BALANCE_BY_CITY('Northfield', NULL, NULL);   -- one match: 1200.00, 'OK'
CALL GET_BALANCE_BY_CITY('Maple Grove', NULL, NULL);  -- two matches: NULL, the lookup-failed message


-- ----------------------------------------------------------------------
-- Section 8-6  Using Update Procedures  --  MySQL originals: 06-update-procedures.sql
-- ----------------------------------------------------------------------

-- UPD_CUST_BALANCE: an UPDATE with its WHERE clause built in, reporting a
--   miss instead of silently doing nothing.
DROP PROCEDURE IF EXISTS UPD_CUST_BALANCE(CHAR(4), DECIMAL(9,2), VARCHAR(60));
CREATE OR REPLACE PROCEDURE UPD_CUST_BALANCE(
    IN  i_customer_num CHAR(4),
    IN  i_amount       DECIMAL(9,2),
    OUT o_status       VARCHAR(60))
LANGUAGE plpgsql
AS $$
DECLARE
    v_name VARCHAR(35);
BEGIN
    SELECT CUSTOMER_NAME
    INTO STRICT v_name
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    UPDATE CUSTOMER
    SET    BALANCE = BALANCE + i_amount
    WHERE  CUSTOMER_NUM = i_customer_num;

    o_status := 'Balance for ' || v_name || ' changed by ' || i_amount;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        o_status := 'No customer numbered ' || i_customer_num || ' - nothing changed';
END;
$$;

CALL UPD_CUST_BALANCE('1120', 250.00, NULL);
CALL UPD_CUST_BALANCE('9999', 250.00, NULL);
UPDATE CUSTOMER SET BALANCE = 3512.50 WHERE CUSTOMER_NUM = '1120';  -- restore the seeded value


-- SHIP_ITEM: a change wrapped in an explicit transaction, MySQL-style --
--   START TRANSACTION, an UPDATE, then COMMIT or ROLLBACK depending on
--   what happened. This is the one translation that did NOT survive a
--   literal port, and finding the right fix took two failed attempts --
--   both are worth reading, because the second failure is not the kind
--   you would guess from the Postgres docs alone.
--
--   Attempt 1, the literal port -- COMMIT and ROLLBACK exactly where
--   MySQL puts them, inside the same block as the EXCEPTION clause that
--   catches SQLEXCEPTION:
--     BEGIN
--         UPDATE ITEM SET ON_HAND = ON_HAND - i_qty_shipped WHERE ...;
--         COMMIT;
--         o_status := 'Shipped ' || ...;
--     EXCEPTION
--         WHEN OTHERS THEN ROLLBACK; o_status := 'Shipment failed...';
--     END;
--   Compiles cleanly. CALLed, it raises 2D000: "cannot commit while a
--   subtransaction is active" -- any block with its own EXCEPTION clause
--   runs inside an implicit subtransaction, and COMMIT/ROLLBACK cannot
--   appear inside one, even one you never explicitly asked for. Confirmed
--   live: WHEN OTHERS caught that very error, and CF21's stock was left
--   untouched -- the procedure "succeeded" while silently doing nothing.
--
--   Attempt 2 -- move the risky UPDATE into its OWN nested block (so
--   COMMIT in the outer body is no longer wrapped by an EXCEPTION clause
--   of its own) and issue COMMIT there instead. This compiles AND runs
--   correctly called by itself -- but reveals a second, independent
--   restriction: CALL SHIP_ITEM(...); by itself works, but the moment it
--   shares a Run with any other statement -- even something as harmless
--   as "SELECT 1; CALL SHIP_ITEM(...);" -- Postgres raises 2D000 again,
--   this time "invalid transaction termination". A procedure containing
--   COMMIT/ROLLBACK is only allowed to commit when its CALL is the ONE
--   AND ONLY statement in that Run. Paste this whole file into the
--   Supabase SQL Editor and click Run once, and THIS is exactly what
--   would happen -- confirmed by running the two-attempt version in this
--   same multi-statement file.
--
-- The version actually kept below sidesteps both problems by not using
--   COMMIT or ROLLBACK at all. It turns out MySQL's explicit transaction
--   is not doing anything here that Postgres does not already do for
--   free: the CALL statement itself is the transaction boundary. If the
--   procedure runs to normal completion, its changes are exactly as
--   committed as any other successful statement's; if a RAISE'd
--   exception is caught inside a nested block, PL/pgSQL has ALREADY
--   rolled that nested block back to its own savepoint before the
--   handler even runs -- there is nothing left for an explicit ROLLBACK
--   to do. Explicit transaction control only earns its keep for the
--   rarer case of committing PROGRESS partway through one long procedure
--   call (a batch job checkpointing every N rows, say) and continuing --
--   not for "undo this one change if it fails," which PL/pgSQL's own
--   exception blocks already give you.
DROP PROCEDURE IF EXISTS SHIP_ITEM(CHAR(4), SMALLINT, VARCHAR(60));
CREATE OR REPLACE PROCEDURE SHIP_ITEM(
    IN  i_item_id     CHAR(4),
    IN  i_qty_shipped SMALLINT,
    OUT o_status      VARCHAR(60))
LANGUAGE plpgsql
AS $$
DECLARE
    v_description VARCHAR(30);
BEGIN
    -- Nested block 1: the existence check.
    BEGIN
        SELECT DESCRIPTION
        INTO STRICT v_description
        FROM   ITEM
        WHERE  ITEM_ID = i_item_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            o_status := 'No item numbered ' || i_item_id;
            RETURN;
    END;

    -- Nested block 2: the change itself. No explicit ROLLBACK needed --
    --   PL/pgSQL rolls this block back to its own savepoint the instant
    --   the EXCEPTION clause fires, before o_status is even set.
    BEGIN
        UPDATE ITEM
        SET    ON_HAND = ON_HAND - i_qty_shipped
        WHERE  ITEM_ID = i_item_id;
    EXCEPTION
        WHEN OTHERS THEN
            o_status := 'Shipment failed - stock left unchanged';
            RETURN;
    END;

    -- No COMMIT here. Reaching this line already means both nested
    --   blocks succeeded, so the UPDATE above stands -- the same as
    --   letting any ordinary successful statement finish.
    o_status := 'Shipped ' || i_qty_shipped || ' of ' || v_description;
END;
$$;

-- Safe to run as part of this whole file in one Supabase SQL Editor Run --
--   no COMMIT inside, so none of the batching restriction above applies.
CALL SHIP_ITEM('CF21', 3::smallint, NULL);  -- 'Shipped 3 of Grain-Free Dry Food 30lb'; ON_HAND 48 -> 45
CALL SHIP_ITEM('ZZ99', 1::smallint, NULL);  -- 'No item numbered ZZ99'; nothing changes
UPDATE ITEM SET ON_HAND = 48 WHERE ITEM_ID = 'CF21';  -- restore the seeded value


-- DEL_CUSTOMER: two handlers for two different failure shapes -- a
--   genuine database error (a foreign key refusing the delete) and a
--   simple miss (no such customer). Postgres names the first condition
--   almost exactly like MySQL's own error text: FOREIGN_KEY_VIOLATION.
DROP PROCEDURE IF EXISTS DEL_CUSTOMER(CHAR(4), VARCHAR(70));
CREATE OR REPLACE PROCEDURE DEL_CUSTOMER(
    IN  i_customer_num CHAR(4),
    OUT o_status       VARCHAR(70))
LANGUAGE plpgsql
AS $$
DECLARE
    v_name VARCHAR(35);
BEGIN
    SELECT CUSTOMER_NAME
    INTO STRICT v_name
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    DELETE FROM CUSTOMER
    WHERE  CUSTOMER_NUM = i_customer_num;

    o_status := 'Deleted ' || v_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        o_status := 'No customer numbered ' || i_customer_num;
    WHEN FOREIGN_KEY_VIOLATION THEN
        o_status := 'Could not delete ' || i_customer_num || ' - invoices still reference it';
END;
$$;

CALL DEL_CUSTOMER('1310', NULL);  -- 'Deleted Companion Care Clinic' -- no invoices, so this succeeds
CALL DEL_CUSTOMER('1120', NULL);  -- refused: invoices still reference it
CALL DEL_CUSTOMER('9999', NULL);  -- 'No customer numbered 9999'

-- Tidy-up: put 1310 back exactly as 00-setup-both.sql shipped it, so the
--   rest of this module's data matches every other file in this folder.
INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP,
                      BALANCE, CREDIT_LIMIT, REP_NUM)
VALUES ('1310', 'Companion Care Clinic', '89 River Rd.', 'Maple Grove', 'OH',
        '44601', 0.00, 10000.00, '20');


-- ----------------------------------------------------------------------
-- Section 8-7  Selecting Multiple Rows with a Procedure
--              --  MySQL originals: 07-selecting-multiple-rows.sql
-- ----------------------------------------------------------------------

-- REP_CREDIT_REVIEW: the finished cursor from the MySQL walkthrough
--   (only the final version is translated -- the earlier "declarations
--   only" and "loop skeleton" stages in the MySQL original are teaching
--   scaffolding, not independent procedures). DECLARE ... CURSOR FOR
--   works unchanged. The one real difference is the loop-exit test:
--   MySQL needs a DECLARE CONTINUE HANDLER FOR NOT FOUND that sets a
--   flag variable, checked after every FETCH. PL/pgSQL keeps an implicit
--   boolean named FOUND, set by the most recent FETCH automatically --
--   EXIT WHEN NOT FOUND replaces the flag variable and the handler both.
DROP TABLE IF EXISTS CUST_REVIEW;
CREATE TABLE CUST_REVIEW (
    CUSTOMER_NUM CHAR(4),
    CUSTOMER_NAME VARCHAR(35),
    AVAILABLE_CREDIT DECIMAL(9,2),
    REVIEW_NOTE VARCHAR(10)
);

DROP PROCEDURE IF EXISTS REP_CREDIT_REVIEW(CHAR(2));
CREATE OR REPLACE PROCEDURE REP_CREDIT_REVIEW(IN i_rep_num CHAR(2))
LANGUAGE plpgsql
AS $$
DECLARE
    cust_cursor CURSOR FOR
        SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE, CREDIT_LIMIT
        FROM CUSTOMER
        WHERE REP_NUM = i_rep_num
        ORDER BY CUSTOMER_NUM;
    v_customer_num   CHAR(4);
    v_customer_name  VARCHAR(35);
    v_balance        DECIMAL(9,2);
    v_credit_limit   DECIMAL(9,2);
    v_available      DECIMAL(9,2);
    v_note           VARCHAR(10);
BEGIN
    OPEN cust_cursor;
    LOOP
        FETCH cust_cursor INTO v_customer_num, v_customer_name, v_balance, v_credit_limit;
        -- EXIT WHEN NOT FOUND: FOUND is a plain boolean, not a cursor
        --   attribute, so there is no cust_cursor%NOTFOUND syntax here --
        --   see the Oracle section below for what happens if you try it.
        EXIT WHEN NOT FOUND;

        v_available := v_credit_limit - v_balance;
        IF v_available < 5000 THEN
            v_note := 'Call rep';
        ELSE
            v_note := 'No action';
        END IF;

        INSERT INTO CUST_REVIEW (CUSTOMER_NUM, CUSTOMER_NAME, AVAILABLE_CREDIT, REVIEW_NOTE)
        VALUES (v_customer_num, v_customer_name, v_available, v_note);
    END LOOP;
    CLOSE cust_cursor;
END;
$$;

CALL REP_CREDIT_REVIEW('20');
SELECT * FROM CUST_REVIEW ORDER BY CUSTOMER_NUM;
-- 1120 | Access Pet Center      | 3987.50 | Call rep
-- 1310 | Companion Care Clinic  | 10000.00 | No action


-- BIG_LINE_ITEMS: a cursor over a four-table join with two parameters,
--   one of them filtering on the cursor's own calculated column. Same
--   FOUND-based exit as above; nothing else changes for the extra JOINs.
DROP TABLE IF EXISTS BIG_LINE_LOG;
CREATE TABLE BIG_LINE_LOG (
    CUSTOMER_NAME VARCHAR(35),
    INVOICE_NUM CHAR(5),
    DESCRIPTION VARCHAR(30),
    LINE_TOTAL DECIMAL(9,2)
);

DROP PROCEDURE IF EXISTS BIG_LINE_ITEMS(CHAR(2), DECIMAL(7,2));
CREATE OR REPLACE PROCEDURE BIG_LINE_ITEMS(IN i_rep_num CHAR(2), IN i_min_total DECIMAL(7,2))
LANGUAGE plpgsql
AS $$
DECLARE
    line_cursor CURSOR FOR
        SELECT C.CUSTOMER_NAME, I.INVOICE_NUM, T.DESCRIPTION,
               L.NUM_ORDERED * L.QUOTED_PRICE AS LINE_TOTAL
        FROM CUSTOMER C
        JOIN INVOICE I ON C.CUSTOMER_NUM = I.CUSTOMER_NUM
        JOIN INVOICE_LINE L ON I.INVOICE_NUM = L.INVOICE_NUM
        JOIN ITEM T ON L.ITEM_ID = T.ITEM_ID
        WHERE C.REP_NUM = i_rep_num
          AND L.NUM_ORDERED * L.QUOTED_PRICE >= i_min_total
        ORDER BY I.INVOICE_NUM, T.DESCRIPTION;
    v_customer_name VARCHAR(35);
    v_invoice_num   CHAR(5);
    v_description   VARCHAR(30);
    v_line_total    DECIMAL(9,2);
BEGIN
    OPEN line_cursor;
    LOOP
        FETCH line_cursor INTO v_customer_name, v_invoice_num, v_description, v_line_total;
        EXIT WHEN NOT FOUND;

        INSERT INTO BIG_LINE_LOG (CUSTOMER_NAME, INVOICE_NUM, DESCRIPTION, LINE_TOTAL)
        VALUES (v_customer_name, v_invoice_num, v_description, v_line_total);
    END LOOP;
    CLOSE line_cursor;
END;
$$;

CALL BIG_LINE_ITEMS('65', 50.00);
SELECT * FROM BIG_LINE_LOG;
-- Whiskers & Wags Boutique | 50711 | Grain-Free Dry Food 30lb | 85.00


-- ----------------------------------------------------------------------
-- Section 8-8  Using PL/SQL in Oracle  --  original: 08-plsql-oracle.sql
-- ----------------------------------------------------------------------
--
-- Of the three vendor dialects this module covers, Oracle's PL/SQL is by
-- far the closest to Postgres's PL/pgSQL -- Postgres borrowed heavily
-- from it. %TYPE, NO_DATA_FOUND, TOO_MANY_ROWS, SQLERRM, and cursor FOR
-- loops all carry over close to unchanged. The differences below are the
-- ones that do NOT.

-- GET_CUSTOMER: %TYPE works exactly as in Oracle -- declare a variable
--   "as whatever type that column is" with no DECLARE keyword needed,
--   PL/pgSQL's declarations sit directly in the DECLARE block instead.
--   NO_DATA_FOUND, TOO_MANY_ROWS, OTHERS, and SQLERRM are all the same
--   names Oracle uses, because PL/pgSQL adopted them from Oracle rather
--   than the other way around.
DROP PROCEDURE IF EXISTS GET_CUSTOMER(CHAR);
CREATE OR REPLACE PROCEDURE GET_CUSTOMER(I_CUSTOMER_NUM IN CHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    L_NAME     CUSTOMER.CUSTOMER_NAME%TYPE;
    L_BALANCE  CUSTOMER.BALANCE%TYPE;
BEGIN
    SELECT CUSTOMER_NAME, BALANCE
    INTO STRICT L_NAME, L_BALANCE
    FROM   CUSTOMER
    WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

    -- RAISE NOTICE is the nearest thing PL/pgSQL has to
    --   DBMS_OUTPUT.PUT_LINE -- both print a line for a human watching
    --   the session rather than returning a result set to the caller.
    RAISE NOTICE '%', L_NAME || '  ' || TO_CHAR(L_BALANCE, '99999.99');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE NOTICE 'No customer numbered %', I_CUSTOMER_NUM;
    WHEN TOO_MANY_ROWS THEN
        RAISE NOTICE 'That condition matched more than one customer.';
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error: %', SQLERRM;
END;
$$;

CALL GET_CUSTOMER('1225');  -- one row: prints the balance
CALL GET_CUSTOMER('1999');  -- no row: NO_DATA_FOUND fires
CALL GET_CUSTOMER('20');    -- two rows (REP_NUM '20' matches CUSTOMER_NUM nothing,
                             -- shown here as the three-case exercise the lesson uses)


-- ADD_TO_BALANCE: Oracle lets you declare your OWN named exception --
--   OVER_LIMIT EXCEPTION; -- then RAISE and catch it by that name.
--   PL/pgSQL has no equivalent declaration. The working substitute is a
--   custom SQLSTATE: RAISE EXCEPTION ... USING ERRCODE = 'P0001' (the
--   P0000-P0999 range is reserved for exactly this), caught with
--   WHEN SQLSTATE 'P0001' THEN. Oracle's own COMMIT/ROLLBACK pair hits
--   the exact same wall SHIP_ITEM's did above (confirmed the same way:
--   COMMIT inside the block that also catches the exception raises
--   2D000), so this version applies the same fix -- no explicit COMMIT
--   or ROLLBACK anywhere. The nested block's automatic rollback-to-
--   savepoint on a caught exception is what Oracle's ROLLBACK inside
--   each WHEN clause was doing; reaching the end of the procedure with
--   no exception is what Oracle's own COMMIT was doing.
DROP PROCEDURE IF EXISTS ADD_TO_BALANCE(CHAR, NUMERIC);
CREATE OR REPLACE PROCEDURE ADD_TO_BALANCE(
    I_CUSTOMER_NUM  IN CHAR,
    I_AMOUNT        IN NUMERIC,
    OUT o_status    VARCHAR(80))
LANGUAGE plpgsql
AS $$
DECLARE
    L_BALANCE  CUSTOMER.BALANCE%TYPE;
    L_LIMIT    CUSTOMER.CREDIT_LIMIT%TYPE;
BEGIN
    o_status := 'OK';

    BEGIN
        UPDATE CUSTOMER
        SET    BALANCE = BALANCE + I_AMOUNT
        WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

        -- SQL%ROWCOUNT's Postgres equivalent: the special NOT FOUND
        --   boolean, true here when the UPDATE touched zero rows.
        IF NOT FOUND THEN
            RAISE EXCEPTION 'No customer numbered %', I_CUSTOMER_NUM
                USING ERRCODE = 'P0001';
        END IF;

        SELECT BALANCE, CREDIT_LIMIT
        INTO STRICT L_BALANCE, L_LIMIT
        FROM   CUSTOMER
        WHERE  CUSTOMER_NUM = I_CUSTOMER_NUM;

        -- The business rule Oracle's OVER_LIMIT existed to enforce.
        IF L_BALANCE > L_LIMIT THEN
            RAISE EXCEPTION 'That charge would push the balance past the credit limit.'
                USING ERRCODE = 'P0002';
        END IF;
    EXCEPTION
        WHEN SQLSTATE 'P0001' THEN
            o_status := 'No customer numbered ' || I_CUSTOMER_NUM;
        WHEN SQLSTATE 'P0002' THEN
            o_status := 'That charge would push the balance past the credit limit.';
        WHEN OTHERS THEN
            -- Oracle's RAISE_APPLICATION_ERROR(-20003, 'Unexpected: '||SQLERRM)
            --   becomes exactly SQLERRM here -- Postgres names the same idea
            --   the same way.
            o_status := 'Unexpected error: ' || SQLERRM;
    END;
END;
$$;

-- Safe to run as part of this whole file in one Supabase SQL Editor Run --
--   same reasoning as SHIP_ITEM above: no COMMIT, so no batching restriction.
CALL ADD_TO_BALANCE('1225', 350.00, NULL);   -- 'OK'; balance 1200.00 -> 1550.00
UPDATE CUSTOMER SET BALANCE = 1200.00 WHERE CUSTOMER_NUM = '1225';  -- restore
CALL ADD_TO_BALANCE('1225', 4000.00, NULL);  -- over the 5000.00 limit; rejected, balance unchanged


-- REP_CUSTOMER_LIST: Oracle's cursor FOR loop -- OPEN, FETCH, the
--   end-of-rows test, and CLOSE all handled implicitly by the loop
--   itself. PL/pgSQL supports the identical FOR variable IN (query) LOOP
--   form -- but with one real difference: Oracle auto-declares the loop
--   record; PL/pgSQL does not. Tried without a prior DECLARE, this
--   raises 42601: "loop variable of loop over rows must be a record
--   variable or list of scalar variables" -- the fix is one line, a
--   plain RECORD declaration, added below.
DROP PROCEDURE IF EXISTS REP_CUSTOMER_LIST(CHAR);
CREATE OR REPLACE PROCEDURE REP_CUSTOMER_LIST(I_REP_NUM IN CHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    -- The one line Oracle does not require: PL/pgSQL needs C declared as
    --   a RECORD before the FOR loop can use it.
    C RECORD;
BEGIN
    FOR C IN (SELECT CUSTOMER_NUM, CUSTOMER_NAME, BALANCE
              FROM   CUSTOMER
              WHERE  REP_NUM = I_REP_NUM
              ORDER BY CUSTOMER_NUM)
    LOOP
        -- C.column_name, unchanged from Oracle -- the loop record's
        --   fields are named after the query's columns either way.
        RAISE NOTICE '%  %', C.CUSTOMER_NUM, C.CUSTOMER_NAME;
    END LOOP;
END;
$$;

CALL REP_CUSTOMER_LIST('20');  -- prints 1120 and 1310, one NOTICE per row

-- A note on the OTHER cursor style Oracle offers -- CURSOR ... IS plus
--   explicit OPEN/FETCH/CLOSE and the %NOTFOUND / %ISOPEN attributes --
--   is not translated here as running code, because %NOTFOUND does not
--   exist in PL/pgSQL AT ALL, in a way worth seeing once. Postgres does
--   not reject cursor_name%NOTFOUND at CREATE time -- the procedure
--   compiles with no complaint, exactly like MySQL's REP_NUM = REP_NUM
--   bug above. It fails the moment it actually runs, with 42703: column
--   "notfound" does not exist -- PL/pgSQL has no idea %NOTFOUND is a
--   cursor attribute and tries to read it as a table column instead. The
--   FOUND-based EXIT WHEN NOT FOUND used throughout this file (see
--   REP_CREDIT_REVIEW above) is the only working substitute; there is no
--   cursor%NOTFOUND syntax to fall back on.


-- ----------------------------------------------------------------------
-- Section 8-9  Using T-SQL in SQL Server  --  original: 09-tsql-sql-server.sql
-- ----------------------------------------------------------------------
--
-- SQL Server's T-SQL is the one dialect in this module with no dedicated
-- procedures below, because every concept it demonstrates is already
-- covered by an equivalent above under its own name: @@ROWCOUNT is
-- Postgres's NOT FOUND / FOUND (see ADD_TO_BALANCE and UPD_CUST_BALANCE);
-- BEGIN TRY / BEGIN CATCH is Postgres's BEGIN ... EXCEPTION (see every
-- procedure in this file); WHILE @@FETCH_STATUS = 0 with two FETCHes (one
-- priming, one at the loop's end) is Postgres's LOOP ... EXIT WHEN NOT
-- FOUND with one FETCH (see REP_CREDIT_REVIEW and BIG_LINE_ITEMS); GO is
-- PL/pgSQL's $$ dollar-quoting, doing the same "here is where the routine
-- body ends" job DELIMITER does for MySQL. T-SQL's PRINT + string-with-+
-- concatenation is RAISE NOTICE + ||, and T-SQL requires an explicit
-- CAST() to concatenate a number into a string the way MySQL's CONCAT()
-- and Oracle's TO_CHAR() do implicitly -- Postgres's || auto-casts most
-- scalar types to text, so none of the procedures above needed one.


-- ----------------------------------------------------------------------
-- Section 8-10  Using a Trigger  --  original: 10-using-a-trigger.sql
-- ----------------------------------------------------------------------
--
-- SQLite lets a trigger's body sit directly inside CREATE TRIGGER --
--   CREATE TRIGGER name AFTER UPDATE ON t BEGIN ... END; -- and that
--   syntax is not merely non-portable, it is a flat syntax error on
--   Postgres: 42601, "syntax error at or near \"BEGIN\"" (confirmed by
--   running Module 8's own PRICE_LOG example unchanged against this
--   project). Postgres always separates the two pieces MySQL and SQLite
--   fuse together: a trigger FUNCTION holding the logic, and a
--   CREATE TRIGGER statement naming which table event calls it.

-- PRICE_LOG: the module's own first trigger example (section 8-1),
--   translated in full.
DROP TRIGGER IF EXISTS LOG_PRICE_CHANGE ON ITEM;
DROP FUNCTION IF EXISTS LOG_PRICE_CHANGE();
DROP TABLE IF EXISTS PRICE_LOG;
UPDATE ITEM SET PRICE = 42.50 WHERE ITEM_ID = 'CF21';  -- reset before demonstrating

CREATE TABLE PRICE_LOG (
    ITEM_ID    CHAR(4),
    OLD_PRICE  DECIMAL(7,2),
    NEW_PRICE  DECIMAL(7,2),
    CHANGED_ON DATE
);

-- RETURNS TRIGGER: the function's return type is fixed by what kind of
--   routine it is, not by what it computes.
CREATE FUNCTION LOG_PRICE_CHANGE() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- OLD and NEW: the same names SQLite and MySQL both use for the row
    --   before and after the change -- this part needs no translation.
    INSERT INTO PRICE_LOG
    VALUES (OLD.ITEM_ID, OLD.PRICE, NEW.PRICE, CURRENT_DATE);
    -- RETURN NEW: an AFTER trigger's return value is ignored by Postgres,
    --   but the function must still return a row of the trigger's type --
    --   NEW is the conventional choice.
    RETURN NEW;
END;
$$;

CREATE TRIGGER LOG_PRICE_CHANGE
AFTER UPDATE OF PRICE ON ITEM
FOR EACH ROW
-- EXECUTE FUNCTION: names the function above as the trigger's body --
--   this is the piece SQLite and MySQL fold directly into CREATE TRIGGER.
EXECUTE FUNCTION LOG_PRICE_CHANGE();

UPDATE ITEM SET PRICE = 44.00 WHERE ITEM_ID = 'CF21';
SELECT ITEM_ID, OLD_PRICE, NEW_PRICE FROM PRICE_LOG;  -- CF21 | 42.50 | 44.00
UPDATE ITEM SET PRICE = 42.50 WHERE ITEM_ID = 'CF21';  -- restore the seeded value


-- BALANCE_LOG: the module's WHEN-conditional trigger (section 8-10,
--   Exercise 37). Postgres's CREATE TRIGGER supports a WHEN clause too --
--   the SQLite original's WHEN OLD.BALANCE <> NEW.BALANCE carries over
--   almost unchanged, upgraded here to IS DISTINCT FROM so a NULL
--   balance can never make the comparison silently vanish.
DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE ON CUSTOMER;
DROP FUNCTION IF EXISTS LOG_BALANCE_CHANGE();
DROP TABLE IF EXISTS BALANCE_LOG;

CREATE TABLE BALANCE_LOG (
    LOG_ID        SERIAL PRIMARY KEY,
    CUSTOMER_NUM  CHAR(4),
    OLD_BALANCE   DECIMAL(9,2),
    NEW_BALANCE   DECIMAL(9,2)
);

CREATE FUNCTION LOG_BALANCE_CHANGE() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO BALANCE_LOG (CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE)
    VALUES (OLD.CUSTOMER_NUM, OLD.BALANCE, NEW.BALANCE);
    RETURN NEW;
END;
$$;

CREATE TRIGGER LOG_BALANCE_CHANGE
AFTER UPDATE OF BALANCE ON CUSTOMER
FOR EACH ROW
-- WHEN, at the trigger level: Postgres checks this BEFORE calling the
--   function at all, the same "only fire on a real change" filter the
--   SQLite lesson demonstrates.
WHEN (OLD.BALANCE IS DISTINCT FROM NEW.BALANCE)
EXECUTE FUNCTION LOG_BALANCE_CHANGE();

UPDATE CUSTOMER SET BALANCE = BALANCE + 250.00 WHERE CUSTOMER_NUM = '1120';  -- logged
UPDATE CUSTOMER SET BALANCE = BALANCE WHERE CUSTOMER_NUM = '1120';          -- WHEN filters this one out
SELECT LOG_ID, CUSTOMER_NUM, OLD_BALANCE, NEW_BALANCE FROM BALANCE_LOG;
-- exactly one row: 1120 | 3512.50 | 3762.50
UPDATE CUSTOMER SET BALANCE = 3512.50 WHERE CUSTOMER_NUM = '1120';  -- restore the seeded value


-- CHECK_CREDIT_LIMIT: the module's BEFORE-INSERT validation trigger
--   (Exercise 38). SQLite's SELECT RAISE(ABORT, 'message') becomes a
--   plain RAISE EXCEPTION -- raising ANY exception inside a BEFORE
--   trigger cancels the statement that fired it, the same as RAISE(ABORT).
DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT ON CUSTOMER;
DROP FUNCTION IF EXISTS CHECK_CREDIT_LIMIT();

CREATE FUNCTION CHECK_CREDIT_LIMIT() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.CREDIT_LIMIT > 10000 THEN
        -- RAISE EXCEPTION with no RETURN after it: the statement never
        --   completes, so there is nothing to return NEW from.
        RAISE EXCEPTION 'Credit limit over 10000 needs manager approval';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER CHECK_CREDIT_LIMIT
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
EXECUTE FUNCTION CHECK_CREDIT_LIMIT();

-- Within the ceiling: stored.
INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP,
                      BALANCE, CREDIT_LIMIT, REP_NUM)
VALUES ('1500', 'Harbor Pet Supply', '12 Dock St.', 'Northfield', 'OH', '44067',
        0.00, 9000.00, '35');
DELETE FROM CUSTOMER WHERE CUSTOMER_NUM = '1500';  -- tidy up before the next INSERT

-- Over the ceiling: raises P0001 and the row is never stored. Left
--   commented -- this is the one INSERT in this section that is
--   SUPPOSED to fail; uncomment it to see the message yourself.
-- INSERT INTO CUSTOMER (CUSTOMER_NUM, CUSTOMER_NAME, STREET, CITY, STATE, ZIP,
--                       BALANCE, CREDIT_LIMIT, REP_NUM)
-- VALUES ('1500', 'Harbor Pet Supply', '12 Dock St.', 'Northfield', 'OH', '44067',
--         0.00, 15000.00, '35');


-- ======================================================================
-- Clean-up -- drop every routine and trigger this file created, mirroring
-- the MySQL lesson's own Example 8-6.12. Leaves CUST_REVIEW, BIG_LINE_LOG,
-- PRICE_LOG, and BALANCE_LOG in place, same as the MySQL/SQLite originals
-- leave their result tables behind for inspection.
-- ======================================================================
-- DROP TRIGGER IF EXISTS LOG_PRICE_CHANGE ON ITEM;
-- DROP TRIGGER IF EXISTS LOG_BALANCE_CHANGE ON CUSTOMER;
-- DROP TRIGGER IF EXISTS CHECK_CREDIT_LIMIT ON CUSTOMER;
-- DROP FUNCTION IF EXISTS LOG_PRICE_CHANGE();
-- DROP FUNCTION IF EXISTS LOG_BALANCE_CHANGE();
-- DROP FUNCTION IF EXISTS CHECK_CREDIT_LIMIT();
-- DROP FUNCTION IF EXISTS SHOW_REP_COUNT();
-- DROP PROCEDURE IF EXISTS BAD_REP_NAME(CHAR(2), VARCHAR(20));
-- DROP PROCEDURE IF EXISTS DISP_REP_NAME(CHAR(2), VARCHAR(20), VARCHAR(20));
-- DROP PROCEDURE IF EXISTS GET_CREDIT_AVAILABLE(CHAR(4), DECIMAL(9,2));
-- DROP PROCEDURE IF EXISTS ADD_SALE_TO_COMMISSION(CHAR(2), DECIMAL(9,2), DECIMAL(8,2));
-- DROP PROCEDURE IF EXISTS GET_CUST_BALANCE_UNSAFE(CHAR(4), DECIMAL(9,2));
-- DROP PROCEDURE IF EXISTS GET_CUST_BALANCE(CHAR(4), DECIMAL(9,2), VARCHAR(60));
-- DROP PROCEDURE IF EXISTS GET_BALANCE_BY_CITY(VARCHAR(20), DECIMAL(9,2), VARCHAR(60));
-- DROP PROCEDURE IF EXISTS UPD_CUST_BALANCE(CHAR(4), DECIMAL(9,2), VARCHAR(60));
-- DROP PROCEDURE IF EXISTS SHIP_ITEM(CHAR(4), SMALLINT, VARCHAR(60));
-- DROP PROCEDURE IF EXISTS DEL_CUSTOMER(CHAR(4), VARCHAR(70));
-- DROP PROCEDURE IF EXISTS REP_CREDIT_REVIEW(CHAR(2));
-- DROP PROCEDURE IF EXISTS BIG_LINE_ITEMS(CHAR(2), DECIMAL(7,2));
-- DROP PROCEDURE IF EXISTS GET_CUSTOMER(CHAR);
-- DROP PROCEDURE IF EXISTS ADD_TO_BALANCE(CHAR, NUMERIC);
-- DROP PROCEDURE IF EXISTS REP_CUSTOMER_LIST(CHAR);
