#!/usr/bin/env python3
"""Generate labs/moduleN/*.sql from db.html (annotated SQL) + content/moduleN.json (checks).

Run from anywhere:  python3 tools/gen-module-labs.py [module4|module5]

Sourced from db.html rather than the content JSON because Module 5's SQL carries
line-by-line commentary that lives only in the rendered page. The setup files
(00-*.sql) are copied from labs/module4 by hand and are not regenerated here.
"""
import html
import json
import os
import re
import sqlite3
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MODULES = {
    'module4': {
        'next': 'module5',
        'title': 'Module 4',
        'label': {'m4-1': '4-1', 'm4-2': '4-2', 'm4-3': '4-3', 'm4-4': '4-4', 'm4-5': '4-5',
                  'm4-6': '4-6', 'm4-7': '4-7', 'm4-summary': 'Summary', 'm4-terms': 'Key Terms',
                  'm4-review': 'Review', 'm4-exercises': 'Case Exercises'},
        'titles': {'m4-1': '4-1  Constructing Simple Queries', 'm4-2': '4-2  Sorting',
                   'm4-3': '4-3  Using Functions', 'm4-4': '4-4  Nesting Queries',
                   'm4-5': '4-5  Grouping', 'm4-6': '4-6  Nulls',
                   'm4-7': '4-7  Summary of SQL Clauses, Functions, and Operators',
                   'm4-summary': 'Module Summary', 'm4-terms': 'Key Terms',
                   'm4-review': 'Review Questions', 'm4-exercises': 'Case Exercises'},
        'lessons': [
            ('01-simple-queries.sql', ['m4-1'], 'Constructing Simple Queries'),
            ('02-sorting.sql', ['m4-2'], 'Sorting'),
            ('03-functions.sql', ['m4-3'], 'Using Functions'),
            ('04-nesting-queries.sql', ['m4-4'], 'Nesting Queries'),
            ('05-grouping.sql', ['m4-5'], 'Grouping'),
            ('06-nulls.sql', ['m4-6'], 'Nulls'),
            ('07-clause-summary.sql', ['m4-7'], 'Summary of SQL Clauses, Functions, and Operators'),
            ('08-review-and-cases.sql', ['m4-summary', 'm4-terms', 'm4-review', 'm4-exercises'],
             'Module summary, key terms, review questions, case exercises'),
        ],
    },
    'module5': {
        'next': 'module6',
        'title': 'Module 5',
        'label': {'m5-1': '5-1', 'm5-2': '5-2', 'm5-2b': '5-2e-5-2h', 'm5-3': '5-3',
                  'm5-4': '5-4', 'm5-5': '5-5', 'm5-summary': 'Summary',
                  'm5-terms': 'Key Terms', 'm5-review': 'Review', 'm5-exercises': 'Case Exercises'},
        'titles': {'m5-1': '5-1  Querying Multiple Tables',
                   'm5-2': '5-2  Comparing Joins, IN, and EXISTS',
                   'm5-2b': '5-2e to 5-2h  Aliases, Self-Joins, and Joining Several Tables',
                   'm5-3': '5-3  Set Operations', 'm5-4': '5-4  All and Any',
                   'm5-5': '5-5  Special Operations', 'm5-summary': 'Module Summary',
                   'm5-terms': 'Key Terms', 'm5-review': 'Review Questions',
                   'm5-exercises': 'Case Exercises'},
        'lessons': [
            ('01-querying-multiple-tables.sql', ['m5-1'], 'Querying Multiple Tables'),
            ('02-joins-in-exists.sql', ['m5-2'], 'Comparing Joins, IN, and EXISTS'),
            ('03-aliases-and-self-joins.sql', ['m5-2b'], 'Aliases, Self-Joins, and Joining Several Tables'),
            ('04-set-operations.sql', ['m5-3'], 'Set Operations'),
            ('05-all-and-any.sql', ['m5-4'], 'All and Any'),
            ('06-special-operations.sql', ['m5-5'], 'Special Operations'),
            ('07-review-and-cases.sql', ['m5-summary', 'm5-terms', 'm5-review', 'm5-exercises'],
             'Module summary, key terms, review questions, case exercises'),
        ],
    },
    'module8': {
        'next': 'supabase',
        'title': 'Module 8',
        'label': {'m8-1': '8-1', 'm8-2': '8-2', 'm8-3': '8-3', 'm8-4': '8-4', 'm8-5': '8-5',
                  'm8-6': '8-6', 'm8-7': '8-7', 'm8-8': '8-8', 'm8-9': '8-9', 'm8-10': '8-10',
                  'm8-summary': 'Summary', 'm8-terms': 'Key Terms', 'm8-review': 'Review',
                  'm8-exercises': 'Case Exercises'},
        'titles': {'m8-1': '8-1  Using SQL in a Programming Environment',
                   'm8-2': '8-2  Using Functions',
                   'm8-3': '8-3  Concatenating Columns',
                   'm8-4': '8-4  Stored Procedures Using MySQL',
                   'm8-5': '8-5  Error Handling',
                   'm8-6': '8-6  Using Update Procedures',
                   'm8-7': '8-7  Selecting Multiple Rows with a Procedure',
                   'm8-8': '8-8  Using PL/SQL in Oracle',
                   'm8-9': '8-9  Using T-SQL in SQL Server',
                   'm8-10': '8-10  Using a Trigger',
                   'm8-summary': 'Module Summary', 'm8-terms': 'Key Terms',
                   'm8-review': 'Review Questions', 'm8-exercises': 'Case Exercises'},
        'lessons': [
            ('01-sql-in-programs.sql', ['m8-1'], 'Using SQL in a Programming Environment'),
            ('02-functions.sql', ['m8-2'], 'Using Functions'),
            ('03-concatenating-columns.sql', ['m8-3'], 'Concatenating Columns'),
            ('04-stored-procedures-mysql.sql', ['m8-4'], 'Stored Procedures Using MySQL'),
            ('05-error-handling.sql', ['m8-5'], 'Error Handling'),
            ('06-update-procedures.sql', ['m8-6'], 'Using Update Procedures'),
            ('07-selecting-multiple-rows.sql', ['m8-7'], 'Selecting Multiple Rows with a Procedure'),
            ('08-plsql-oracle.sql', ['m8-8'], 'Using PL/SQL in Oracle'),
            ('09-tsql-sql-server.sql', ['m8-9'], 'Using T-SQL in SQL Server'),
            ('10-using-a-trigger.sql', ['m8-10'], 'Using a Trigger'),
            ('11-review-and-cases.sql', ['m8-summary', 'm8-terms', 'm8-review', 'm8-exercises'],
             'Module summary, key terms, review questions, case exercises'),
        ],
    },
}

MOD = (sys.argv[1] if len(sys.argv) > 1 else 'module5')
if MOD not in MODULES:
    raise SystemExit(f'usage: gen-module-labs.py [{" | ".join(MODULES)}]')
CFG = MODULES[MOD]
OUT = os.path.join(ROOT, 'labs', MOD)
os.makedirs(OUT, exist_ok=True)

src = open(os.path.join(ROOT, 'db.html'), encoding='utf-8').read()
seg = src[src.index(f'<section class="page" id="{MOD}"'):src.index(f'<section class="page" id="{CFG["next"]}"')]

seeds = json.loads(src[src.index('window.SANDBOX_SEEDS = ') + len('window.SANDBOX_SEEDS = '):
                       src.index('</script>', src.index('window.SANDBOX_SEEDS = '))].strip().rstrip(';'))

def runs_clean(sql, seed_key, need_semicolon=True):
    """True when this script executes without error against its own seed."""
    # A starter must also TERMINATE. Several stop mid-statement on purpose, and
    # standalone they parse fine - but in a lab file the next statement would be
    # glued onto them, so they have to be treated as unfinished.
    if need_semicolon:
        # Ignore any trailing instruction comment ("Your turn: ...") before
        # asking whether the last statement was actually terminated.
        tail = sql.rstrip().split('\n')
        while tail and (not tail[-1].strip() or tail[-1].lstrip().startswith('--')):
            tail.pop()
        if not tail or not '\n'.join(tail).rstrip().endswith(';'):
            return False
    db = sqlite3.connect(':memory:')
    try:
        db.executescript(seeds.get(seed_key, ''))
        db.executescript(sql)
        return True
    except Exception:
        return False
    finally:
        db.close()


# ---------------------------------------------------------------- sections
SEC = [(m.group(1), m.start()) for m in re.finditer(r'<section class="lesson-section" id="([^"]+)"', seg)]
SEC.append(('__end__', len(seg)))


def section_of(pos):
    for i in range(len(SEC) - 1):
        if SEC[i][1] <= pos < SEC[i + 1][1]:
            return SEC[i][0]
    return '?'


TITLES = CFG["titles"]

# Short label for headers and cross-references. The lesson sections carry a
# numbered id; the closing sections do not, so they get a word instead of the
# first token of their title.
LABEL = CFG["label"]
LESSON_SECS = {k for k in TITLES if re.match(r'^m\d+-\d', k)}


# ---------------------------------------------------------------- harvest
items = []  # (pos, kind, payload)

for m in re.finditer(r'<pre class="code-block">(.*?)</pre>', seg, re.S):
    body = html.unescape(re.sub(r'</?code>', '', m.group(1))).strip()
    items.append((m.start(), 'code', {'sql': body}))

SB = re.compile(
    r'<div class="sandbox"[^>]*data-seed="([^"]*)"[^>]*data-starter="([^"]*)"[^>]*data-solution="([^"]*)"(.*?)</div>\s*(?=<)',
    re.S)
for m in re.finditer(r'<div class="sandbox"[^>]*data-seed="([^"]*)"\s+data-starter="([^"]*)"\s+data-solution="([^"]*)"', seg, re.S):
    tail = seg[m.end():m.end() + 6000]
    hint = re.search(r'<div class="sandbox-hint">(.*?)</div>', tail, re.S)
    hint_txt = ''
    if hint:
        hint_txt = html.unescape(re.sub(r'<[^>]+>', '', hint.group(1))).strip()
        hint_txt = re.sub(r'\s+', ' ', hint_txt)
    items.append((m.start(), 'sandbox', {
        'seed': m.group(1),
        'starter': html.unescape(m.group(2)).strip(),
        'solution': html.unescape(m.group(3)).strip(),
        'hint': hint_txt,
    }))

items.sort(key=lambda t: t[0])
for pos, kind, p in items:
    p['section'] = section_of(pos)

codes = [p for _, k, p in items if k == 'code']
boxes = [p for _, k, p in items if k == 'sandbox']
print(f'harvested {len(codes)} code blocks, {len(boxes)} sandboxes')

# number them per section, and number exercises globally
ex_no = 0
for p in items and [q for _, _, q in items]:
    pass
n_by_sec = {}
for _, kind, p in items:
    s = p['section']
    n_by_sec[s] = n_by_sec.get(s, 0) + 1
    p['n'] = n_by_sec[s]
    if kind == 'sandbox':
        ex_no += 1
        p['ex'] = ex_no

# ---------------------------------------------------------------- checks
data = json.load(open(os.path.join(ROOT, 'content', f'{MOD}.json')))
groups = [(g['key'], g.get('sqlChecks', [])) for g in data['groups']]
print('sqlChecks:', sum(len(c) for _, c in groups))

# ---------------------------------------------------------------- writing
def banner(title, sub_lines):
    out = ['-- ' + '=' * 70,
           f'-- {CFG["title"]} · {title}',
           '-- ' + '=' * 70,
           '--']
    out += ['-- ' + l if l else '--' for l in sub_lines]
    out.append('-- ' + '=' * 70)
    return '\n'.join(out) + '\n'


def rule(title):
    return '\n-- ' + '-' * 70 + f'\n-- {title}\n-- ' + '-' * 70 + '\n'


def comment_block(text, indent='--   '):
    return '\n'.join(indent + l if l.strip() else indent.rstrip() for l in text.split('\n'))


LESSONS = CFG["lessons"]

# statements the module shows deliberately broken
INVALID = [
    'no such column: CUSTOMER.CUSTOMER_NUM',
    'ambiguous column name: CUSTOMER_NUM',
    'do not have the same number of result columns',
    'near &quot;ALL&quot;',
    'near "ALL"',
    'ALL (SELECT',
    'ANY (SELECT',
]


def is_invalid(sql):
    s = sql
    if re.search(r'\bGOAL:\s*a (second )?deliberate error', s, re.I): return True
    if 'This one fails' in s: return True
    if re.search(r'&gt; ALL \(SELECT|> ALL \(SELECT', s): return True
    if re.search(r'&gt; ANY \(SELECT|> ANY \(SELECT', s): return True
    if 'BROKEN' in s: return True
    return False


for fname, secs, title in LESSONS:
    lines = [banner(title, [
        f'Sections: {", ".join(LABEL[s] for s in secs)}',
        'Load first: 00-setup-both.sql   (has every table this file touches)',
        '',
        'Examples are the statements shown in the lesson, with the page\'s own',
        'line-by-line commentary kept intact. Exercises are the starter queries',
        'from the live sandboxes -- edit them and re-run.',
        'Solutions are in 90-exercise-solutions.sql.',
    ])]
    for s in secs:
        picked = [(k, p) for _, k, p in items if p['section'] == s]
        if not picked:
            continue
        lines.append(rule(f'Section {TITLES[s]}' if s in LESSON_SECS else TITLES[s]))
        for kind, p in picked:
            if kind == 'code':
                tag = f"-- Example {s.replace('m','').replace('-','-')}.{p['n']}"
                lines.append(f"\n-- Example {LABEL[s]}.{p['n']}")
                # Mark by observed behaviour, not by reading the prose: a comment
                # can say "deliberate error" about the line below it while the
                # statement as a whole still runs.
                if not runs_clean(p['sql'], 'both_full', need_semicolon=False):
                    lines.append('-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.')
                lines.append(p['sql'])
            else:
                ok = runs_clean(p['starter'], p['seed'])
                lines.append(f"\n-- >>> EXERCISE {p['ex']}  (section {LABEL[s]}, seed: {p['seed']})")
                if p['hint']:
                    lines.append(f"-- Hint: {p['hint']}")
                if ok:
                    lines.append(p['starter'])
                else:
                    lines.append('-- The starter below is deliberately unfinished -- it has a blank to fill in,')
                    lines.append('-- or stops mid-statement. It is commented out so this file still runs')
                    lines.append('-- straight through. Uncomment it, complete it, then run it.')
                    lines.append(comment_block(p['starter'], '-- '))
                    p['unfinished'] = True
    open(os.path.join(OUT, fname), 'w').write('\n'.join(lines).rstrip() + '\n')
    print('wrote', fname)

# ---------------------------------------------------------------- solutions
lines = [banner('Solutions to the sandbox exercises', [
    'One entry per exercise, in the same order as the numbered lesson files.',
    'Each shows the starter the student begins from and the finished query,',
    'with the line-by-line commentary the page carries.',
])]
for _, kind, p in items:
    if kind != 'sandbox':
        continue
    lines.append(rule(f"Exercise {p['ex']}  --  section {LABEL[p['section']]}  --  seed: {p['seed']}"))
    if p['hint']:
        lines.append(f"-- Hint given: {p['hint']}\n")
    lines.append('-- Starter:')
    if p.get('unfinished'):
        lines.append('--   (deliberately unfinished -- a blank to fill in, or stops mid-statement)')
    lines.append(comment_block(p['starter']))
    lines.append('')
    if p['solution'].strip():
        lines.append('-- Solution:')
        lines.append(p['solution'])
    else:
        lines.append('-- No canned solution: this sandbox is an open scratchpad.')
open(os.path.join(OUT, '90-exercise-solutions.sql'), 'w').write('\n'.join(lines).rstrip() + '\n')
print('wrote 90-exercise-solutions.sql')

# ---------------------------------------------------------------- verification
total = sum(len(c) for _, c in groups)
lines = [banner('Verification queries and expected results', [
    'Every statement the module asserts a result for, with that expected result',
    'as a comment. Use it to confirm a database was seeded correctly, or to',
    'check a lab environment after changing engines.',
    '',
    'Load first: 00-setup-both.sql',
    '',
    'Statements marked INTENTIONALLY INVALID are expected to raise an error.',
])]
# Which checks actually fail? The file is cumulative - later checks depend on
# rows earlier ones insert - so replay the whole sequence against one database
# and record what raises, rather than guessing from the expected-result prose.
_probe = sqlite3.connect(':memory:')
_probe.executescript(seeds['both_full'])
FAILS = set()
_i = 0
for _k, _cs in groups:
    for _c in _cs:
        _i += 1
        try:
            _probe.executescript(_c['sql'])
        except Exception:
            FAILS.add(_i)
_probe.close()
print(f'checks that raise: {len(FAILS)}')

n = 0
for key, checks in groups:
    lines.append(rule(f'Group {key}  --  {len(checks)} checks'))
    for c in checks:
        n += 1
        lines.append(f'\n-- Check {n}')
        exp = re.sub(r'\s+', ' ', c.get('expect', '')).strip()
        if exp:
            lines.append(f'-- Expected: {exp}')
        if n in FAILS:
            lines.append('-- !! INTENTIONALLY INVALID -- this statement is SUPPOSED to fail.')
        lines.append(c['sql'].strip())
open(os.path.join(OUT, '91-verification-queries.sql'), 'w').write('\n'.join(lines).rstrip() + '\n')
print(f'wrote 91-verification-queries.sql ({n} checks)')
