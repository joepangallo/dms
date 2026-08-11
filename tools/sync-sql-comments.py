#!/usr/bin/env python3
"""Keep the SQL commentary in content/*.json in step with db.html.

Run with no arguments to CHECK - it reports any block whose SQL differs between
the content JSON and the rendered page. Run with --apply to copy the page's
version (comments included) into the JSON.

Use it after editing SQL comments directly in db.html, so that a later
re-render cannot silently drop them.

The page and the JSON hold the same statements; only the page has the comments.

Only blocks of type "code" (their `text`) and type "sandbox" (their `solution`)
are considered, so prose that happens to quote a query is never touched.
Matching is by comment-stripped SQL, never by position, and a value is replaced
only when exactly one page block carries that SQL - so an edit can only add
comments, never change a statement.
"""
import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGES = ['module4', 'module5', 'module6', 'module7', 'module8', 'supabase']
APPLY = '--apply' in sys.argv

src = open(os.path.join(ROOT, 'db.html'), encoding='utf-8').read()


def page(pid):
    a = src.index(f'<section class="page" id="{pid}"')
    nxt = re.search(r'<section class="page" id="', src[a + 10:])
    return src[a:a + 10 + nxt.start()] if nxt else src[a:]


def norm(t):
    out = []
    for line in (t or '').split('\n'):
        s = line.strip()
        if not s or s.startswith('--') or s.startswith('#'):
            continue
        out.append(re.sub(r'\s+', ' ', s))
    return '\n'.join(out)


def norm2(t):
    """As norm(), but also drops a trailing -- comment from each line."""
    return '\n'.join(re.sub(r'\s*--.*$', '', l).rstrip() for l in norm(t).split('\n')).strip()


def index(texts, f):
    by = {}
    for t in texts:
        by.setdefault(f(t), []).append(t)
    return {k: v[0] for k, v in by.items() if len(set(v)) == 1}


def walk(o, out):
    if isinstance(o, dict):
        if o.get('type') in ('code', 'sandbox'):
            out.append(o)
        for v in o.values():
            walk(v, out)
    elif isinstance(o, list):
        for v in o:
            walk(v, out)


total = 0
for pid in PAGES:
    path = os.path.join(ROOT, 'content', f'{pid}.json')
    if not os.path.exists(path):
        continue
    raw = open(path, encoding='utf-8').read()
    data = json.loads(raw)
    seg = page(pid)

    h_code = [html.unescape(re.sub(r'</?code>', '', x))
              for x in re.findall(r'<pre class="code-block">(.*?)</pre>', seg, re.S)]
    h_sol = [html.unescape(x) for x in re.findall(r'data-solution="([^"]*)"', seg)]

    blocks = []
    walk(data, blocks)
    n = 0
    miss = []
    for b in blocks:
        field = 'text' if b['type'] == 'code' else 'solution'
        pool = h_code if b['type'] == 'code' else h_sol
        old = b.get(field) or ''
        if not old.strip():
            continue
        new = index(pool, norm).get(norm(old)) or index(pool, norm2).get(norm2(old))
        if new is None:
            miss.append(old.strip().splitlines()[0][:74])
            continue
        if new.strip() != old.strip():
            b[field] = new.strip()
            n += 1

    out = json.dumps(data, ensure_ascii=False, indent=1) + '\n'
    # how much of the diff is incidental re-encoding rather than our edits?
    base = json.dumps(json.loads(raw), ensure_ascii=False, indent=1) + '\n'
    incidental = sum(1 for a, b_ in zip(raw.split('\n'), base.split('\n')) if a != b_)
    print(f'{pid:9s} updated {n:3d}   unmatched {len(miss)}   incidental re-encoding: {incidental} line(s)')
    for m in miss:
        print(f'            - {m}')
    total += n
    if APPLY and n:
        open(path, 'w', encoding='utf-8').write(out)

print(f'\ntotal blocks updated: {total}')
print('APPLIED' if APPLY else 'dry run - pass --apply to write')
