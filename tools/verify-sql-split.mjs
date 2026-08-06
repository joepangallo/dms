#!/usr/bin/env node
/* Unit tests for the SQL statement splitter that drives the Module 3
   walkthrough. The splitter has to cut a script into steps WITHOUT running
   any of it, so the class can see the whole plan before statement one --
   which means it, not SQLite, is responsible for knowing that a semicolon
   inside 'O''Brien; Inc.', inside a -- note, or inside a trigger body does
   not end a statement.

   Runs the real functions lifted out of db.html, so it cannot drift from
   what the page actually ships. Exits non-zero on any failure. */

import { readFileSync } from 'node:fs';

const src = readFileSync(new URL('../db.html', import.meta.url), 'utf8');

/* Lift a function out of the page by brace-matching from its declaration. */
function grab(name) {
  const start = src.indexOf('function ' + name + '(');
  if (start < 0) throw new Error(`db.html no longer defines ${name}()`);
  let depth = 0, j = src.indexOf('{', start);
  for (; j < src.length; j++) {
    if (src[j] === '{') depth++;
    else if (src[j] === '}' && --depth === 0) { j++; break; }
  }
  return src.slice(start, j);
}

const api = new Function(
  grab('stripSqlComments') + grab('isRunnableSql') + grab('splitSqlStatements') + grab('splitLeadNote') +
  '; return { splitSqlStatements, splitLeadNote, stripSqlComments, isRunnableSql };'
)();

const fails = [];
const eq = (name, got, want) => {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  console.log(`${ok ? '  ok  ' : '  FAIL'} ${name}${ok ? '' : `  got ${JSON.stringify(got)} want ${JSON.stringify(want)}`}`);
  if (!ok) fails.push(name);
};
const count = (name, sql, want) => eq(name, api.splitSqlStatements(sql).length, want);

console.log('\nsplitting: the ordinary cases');
count('one statement', 'SELECT 1;', 1);
count('no trailing semicolon', 'SELECT 1', 1);
count('two statements', 'SELECT 1; SELECT 2;', 2);
count('multiline statement stays whole', 'CREATE TABLE T (\n  A INT,\n  B INT\n);', 1);
count('blank lines between statements', 'SELECT 1;\n\n\nSELECT 2;\n\n', 2);
count('a real lesson script',
  '-- Create the REP table\nCREATE TABLE REP (A INT);\n\n-- Add the reps\n' +
  "INSERT INTO REP VALUES (1);\nINSERT INTO REP VALUES (2);\n\nSELECT * FROM REP;", 4);

console.log('\nsplitting: semicolons that must NOT split');
count('inside a string literal', "SELECT 'a;b' AS x;", 1);
count('inside an escaped quote', "INSERT INTO T VALUES ('O''Brien; Inc.');", 1);
count('inside a line comment', '-- note; here\nSELECT 1;', 1);
count('inside a block comment', '/* a ; b */ SELECT 1;', 1);
count('inside a quoted identifier', 'SELECT "co;l" FROM T;', 1);
count('inside a trigger body', 'CREATE TRIGGER T AFTER UPDATE ON I BEGIN INSERT INTO L VALUES (1); END;', 1);
count('trigger body with two statements',
  'CREATE TRIGGER T AFTER UPDATE ON I BEGIN INSERT INTO L VALUES (1); INSERT INTO L VALUES (2); END;\nSELECT 1;', 2);
count('a trigger followed by ordinary SQL',
  'CREATE TRIGGER T AFTER UPDATE ON I BEGIN INSERT INTO L VALUES (1); END;\nUPDATE I SET P = 2;', 2);
count('DROP TRIGGER is an ordinary statement', 'DROP TRIGGER IF EXISTS T;\nSELECT 1;', 2);

console.log('\nsplitting: nothing to run');
count('empty', '', 0);
count('whitespace only', '   \n\t ', 0);
count('comments only', '-- just a note\n-- another', 0);
count('an unclosed block comment is still a comment', '/* oops SELECT 1;', 0);
count('bare semicolons are punctuation', '; ;  ;', 0);
count('doubled semicolons make two steps, not three', 'SELECT 1;;SELECT 2;', 2);
count('a comment after the last statement is not a step', 'SELECT 1;\n-- done', 1);

console.log('\nsplitting: malformed input still yields something runnable');
count('unterminated string literal', "SELECT 'oops", 1);
count('unterminated statement', 'CREATE TABLE T (', 1);

console.log('\nleading comments become the step narration');
eq('one comment line', api.splitLeadNote('-- Create the REP table\nCREATE TABLE REP (X INT);'),
  { note: 'Create the REP table', code: 'CREATE TABLE REP (X INT);' });
eq('two comment lines', api.splitLeadNote('-- one\n-- two\nSELECT 1;'),
  { note: 'one two', code: 'SELECT 1;' });
eq('a block comment', api.splitLeadNote('/* boxed */ SELECT 1;'),
  { note: 'boxed', code: 'SELECT 1;' });
eq('no comment at all', api.splitLeadNote('SELECT 1;'),
  { note: '', code: 'SELECT 1;' });
eq('a trailing comment is not narration', api.splitLeadNote('SELECT 1; -- afterwards'),
  { note: '', code: 'SELECT 1; -- afterwards' });

console.log('\nrunnability test');
eq('comment is not runnable', api.isRunnableSql('-- hello'), false);
eq('semicolon is not runnable', api.isRunnableSql(';'), false);
eq('SQL is runnable', api.isRunnableSql('SELECT 1;'), true);

console.log(`\n${fails.length ? `FAILED (${fails.length})` : 'ALL CHECKS PASSED'}`);
fails.forEach((f) => console.log(' - ' + f));
process.exit(fails.length ? 1 : 0);
