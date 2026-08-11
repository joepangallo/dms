#!/usr/bin/env python3
"""Generate labs/module5/*.sql from db.html (annotated SQL) + content/module5.json (checks).

Mirrors the layout of labs/module4. Run from anywhere:  python3 tools/gen-module5-labs.py

Sourced from db.html rather than the content JSON because Module 5's SQL carries
line-by-line commentary that lives only in the rendered page. The setup files
(00-*.sql) are copied from labs/module4 by hand and are not regenerated here.
"""
import html
import json
import os
import re
import sqlite3

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'labs', 'module5')
os.makedirs(OUT, exist_ok=True)

src = open(os.path.join(ROOT, 'db.html'), encoding='utf-8').read()
seg = src[src.index('<section class="page" id="module5"'):src.index('<section class="page" id="module6"')]

seeds = json.loads(src[src.index('window.SANDBOX_SEEDS = ') + len('window.SANDBOX_SEEDS = '):
                       src.index('</script>', src.index('window.SANDBOX_SEEDS = '))].strip().rstrip(';'))

def runs_clean(sql, seed_key):
    """True when this script executes without error against its own seed."""
    # A starter must also TERMINATE. Several stop mid-statement on purpose, and
    # standalone they parse fine - but in a lab file the next statement would be
    # glued onto them, so they have to be treated as unfinished.
    if not sql.rstrip().endswith(';'):
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


TITLES = {
    'm5-1': '5-1  Querying Multiple Tables',
    'm5-2': '5-2  Comparing Joins, IN, and EXISTS',
    'm5-2b': '5-2e to 5-2h  Aliases, Self-Joins, and Joining Several Tables',
    'm5-3': '5-3  Set Operations',
    'm5-4': '5-4  All and Any',
    'm5-5': '5-5  Special Operations',
    'm5-summary': 'Module Summary',
    'm5-terms': 'Key Terms',
    'm5-review': 'Review Questions',
    'm5-exercises': 'Case Exercises',
}

# Short label for headers and cross-references. The lesson sections carry a
# numbered id; the closing sections do not, so they get a word instead of the
# first token of their title.
LABEL = {
    'm5-1': '5-1', 'm5-2': '5-2', 'm5-2b': '5-2e-5-2h',
    'm5-3': '5-3', 'm5-4': '5-4', 'm5-5': '5-5',
    'm5-summary': 'Summary', 'm5-terms': 'Key Terms',
    'm5-review': 'Review', 'm5-exercises': 'Case Exercises',
}
LESSON_SECS = {'m5-1', 'm5-2', 'm5-2b', 'm5-3', 'm5-4', 'm5-5'}


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
data = json.load(open(os.path.join(ROOT, 'content', 'module5.json')))
groups = [(g['key'], g.get('sqlChecks', [])) for g in data['groups']]
print('sqlChecks:', sum(len(c) for _, c in groups))

# ---------------------------------------------------------------- writing
def banner(title, sub_lines):
    out = ['-- ' + '=' * 70,
           f'-- Module 5 · {title}',
           '-- ' + '=' * 70,
           '--']
    out += ['-- ' + l if l else '--' for l in sub_lines]
    out.append('-- ' + '=' * 70)
    return '\n'.join(out) + '\n'


def rule(title):
    return '\n-- ' + '-' * 70 + f'\n-- {title}\n-- ' + '-' * 70 + '\n'


def comment_block(text, indent='--   '):
    return '\n'.join(indent + l if l.strip() else indent.rstrip() for l in text.split('\n'))


LESSONS = [
    ('01-querying-multiple-tables.sql', ['m5-1'], 'Querying Multiple Tables'),
    ('02-joins-in-exists.sql', ['m5-2'], 'Comparing Joins, IN, and EXISTS'),
    ('03-aliases-and-self-joins.sql', ['m5-2b'], 'Aliases, Self-Joins, and Joining Several Tables'),
    ('04-set-operations.sql', ['m5-3'], 'Set Operations'),
    ('05-all-and-any.sql', ['m5-4'], 'All and Any'),
    ('06-special-operations.sql', ['m5-5'], 'Special Operations'),
    ('07-review-and-cases.sql', ['m5-summary', 'm5-terms', 'm5-review', 'm5-exercises'],
     'Module summary, key terms, review questions, case exercises'),
]

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
                if is_invalid(p['sql']):
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
