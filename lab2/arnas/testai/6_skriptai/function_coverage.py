#!/usr/bin/env python3
"""LD2 8.2.a (Arnas): friendsFeedQuery() ir FriendFeed.build() padengimas.

Šaltiniai:
  * LCOV failas iš `flutter test --branch-coverage`:
      DA   – ar Dart VM įvykdė eilutę (eilučių padengimas);
      BRDA – Dart VM blokų įėjimo taškai (funkcija, uždarinys, then/else blokas).
  * coverage_map.json iš lab2/arnas/tools/coverage_map (Dart AST):
      sakiniai (Statement be Block + `=>` kūnai) ir if sprendimai su sakiniais,
      kurie liudija true ir false baigtį.

Skaičiavimo taisyklės:
  * sakinys įvykdytas, jei pirma DA eilutė jo ribose turi > 0 vykdymų;
  * if baigtis pasiekta, jei įvykdytas ją liudijantis sakinys;
  * DA skaitiklio dydis nevertinamas – tik 0 arba > 0.
Kodas nekeičiamas ir neinstrumentuojamas.

Naudojimas (iš repozitorijos šaknies):
  python3 lab2/arnas/scripts/function_coverage.py summary <lcov.info>
  python3 lab2/arnas/scripts/function_coverage.py matrix <out.md> <testų failai...>
"""

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(subprocess.check_output(
    ['git', 'rev-parse', '--show-toplevel'], text=True).strip())
SOURCE = 'lib/pages/home/home_widget.dart'
TARGETS = ['friendsFeedQuery', 'FriendFeed.build']
MAP_TOOL = 'lab2/arnas/tools/coverage_map/bin/coverage_map.dart'


def coverage_map():
    out = subprocess.run(['dart', 'run', MAP_TOOL, SOURCE, *TARGETS],
                         cwd=ROOT, capture_output=True, text=True, check=True).stdout
    return json.loads(out[out.index('{'):])


def read_lcov(path):
    da, brda, current = {}, {}, None
    for line in Path(path).read_text().splitlines():
        if line.startswith('SF:'):
            current = line[3:].replace(str(ROOT) + '/', '')
        elif current == SOURCE and line.startswith('DA:'):
            n, hits = line[3:].split(',')[:2]
            da[int(n)] = da.get(int(n), 0) + int(hits)
        elif current == SOURCE and line.startswith('BRDA:'):
            n, _, _, hits = line[5:].split(',')
            brda[int(n)] = brda.get(int(n), 0) + (0 if hits == '-' else int(hits))
    if not da:
        sys.exit(f'{path}: nėra {SOURCE} įrašų')
    return da, brda


def analyse(lcov_path, cmap):
    da, brda = read_lcov(lcov_path)
    report = {}
    for name in TARGETS:
        f = cmap[name]
        start, end = f['start_line'], f['end_line']
        stmts = {}
        for s in f['statements']:
            lines = [n for n in sorted(da) if s['start_line'] <= n <= s['end_line']]
            if not lines:
                sys.exit(f'{name} {s["id"]}: sakinio ribose nėra DA eilutės')
            stmts[s['id']] = dict(s, da_line=lines[0], hit=da[lines[0]] > 0)
        decisions = []
        for d in f['decisions']:
            t = stmts[d['true_witness']]['hit']
            fl = stmts[d['false_witness']]['hit'] if d['false_witness'] else None
            decisions.append(dict(d, true_hit=t, false_hit=fl))
        report[name] = dict(
            range=(start, end),
            lines={n: h for n, h in da.items() if start <= n <= end},
            blocks={n: h for n, h in brda.items() if start <= n <= end},
            stmts=stmts, decisions=decisions)
    return report


def pct(covered, total):
    return f'{covered}/{total} ({100 * covered / total:.1f} %)'.replace('.', ',') if total else 'netaikoma (0)'


def summary(args):
    cmap = coverage_map()
    report = analyse(args.lcov, cmap)
    src = (ROOT / SOURCE).read_text().splitlines()
    print(f'LCOV: {args.lcov}')
    for name, r in report.items():
        start, end = r['range']
        print(f'\n== {name}  ({SOURCE}:{start}-{end}) ==')
        hit = sum(1 for h in r['lines'].values() if h)
        print(f'Eilutės (DA): {pct(hit, len(r["lines"]))}')
        for n, h in sorted(r['lines'].items()):
            print(f'  L{n:<4} {"įvykdyta" if h else "NEĮVYKDYTA":<10} {src[n - 1].strip()[:66]}')
        hit = sum(1 for h in r['blocks'].values() if h)
        print(f'VM šakų taškai (BRDA): {pct(hit, len(r["blocks"]))}  '
              f'nepasiekti: {[n for n, h in sorted(r["blocks"].items()) if not h] or "nėra"}')
        hit = sum(1 for s in r['stmts'].values() if s['hit'])
        print(f'Sakiniai (AST + DA): {pct(hit, len(r["stmts"]))}')
        for s in r['stmts'].values():
            print(f'  {s["id"]:<4} L{s["start_line"]:<4} DA L{s["da_line"]:<4} '
                  f'{"įvykdytas" if s["hit"] else "NEĮVYKDYTAS":<11} {s["kind"]:<28} {s["text"][:44]}')
        outcomes = [o for d in r['decisions'] for o in (d['true_hit'], d['false_hit'])]
        known = [o for o in outcomes if o is not None]
        print(f'Sprendimų baigtys (if true/false): {pct(sum(known), len(outcomes))}')
        for d in r['decisions']:
            fl = '?' if d['false_hit'] is None else ('pasiekta' if d['false_hit'] else 'NEPASIEKTA')
            print(f'  {d["id"]} L{d["line"]} if ({d["condition"]}): '
                  f'true {"pasiekta" if d["true_hit"] else "NEPASIEKTA"} ({d["true_witness"]}), '
                  f'false {fl} ({d["false_witness"]}; {d["false_rule"]})')
        if not r['decisions']:
            print('  Sprendimų nėra: vienintelis kelias įėjimas → išėjimas.')


def list_tests(test_file):
    out = subprocess.run(['flutter', 'test', '--no-pub', test_file, '-r', 'json'],
                         cwd=ROOT, capture_output=True, text=True).stdout
    names, hidden = {}, set()
    for line in out.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get('type') == 'testStart':
            names[event['test']['id']] = event['test']['name']
        elif event.get('type') == 'testDone' and event.get('hidden'):
            hidden.add(event['testID'])
    return [n for i, n in names.items() if i not in hidden]


def matrix(args):
    cmap = coverage_map()
    rows = []
    with tempfile.TemporaryDirectory() as tmp:
        for test_file in args.test_files:
            tests = list_tests(test_file)
            if not tests:
                sys.exit(f'{test_file}: nerasta testų (ar failas kompiliuojasi?)')
            for i, test in enumerate(tests, 1):
                lcov = f'{tmp}/{len(rows)}.info'
                print(f'[{test_file} {i}/{len(tests)}] {test}', file=sys.stderr)
                subprocess.run(['flutter', 'test', '--no-pub', test_file, '--plain-name', test,
                                '--branch-coverage', '--coverage-path', lcov],
                               cwd=ROOT, capture_output=True, text=True)
                rows.append((test, analyse(lcov, cmap) if Path(lcov).exists() else None))

    lines = [f'# Padengimo matrica: {", ".join(args.test_files)}', '',
             'Kiekvienas testas paleistas atskirai (`--plain-name`). '
             '✓ – sakinys įvykdytas arba sprendimo baigtis pasiekta.', '']
    for name in TARGETS:
        sids = [s['id'] for s in cmap[name]['statements']]
        dids = [d['id'] for d in cmap[name]['decisions']]
        cols = sids + [f'{d}{o}' for d in dids for o in ('T', 'F')]
        lines += [f'## {name}', '', '| Testas | ' + ' | '.join(cols) + ' |',
                  '|---|' + '---|' * len(cols)]
        for test, report in rows:
            if report is None:
                lines.append(f'| {test} | ' + ' | '.join('?' for _ in cols) + ' |')
                continue
            r = report[name]
            cells = ['✓' if r['stmts'][s]['hit'] else '' for s in sids]
            cells += ['✓' if o else '' for d in r['decisions'] for o in (d['true_hit'], d['false_hit'])]
            lines.append(f'| {test} | ' + ' | '.join(cells) + ' |')
        lines.append('')
    text = '\n'.join(lines)
    Path(args.out).write_text(text + '\n')
    print(text)


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(required=True)
    s = sub.add_parser('summary', help='funkcijų padengimas iš LCOV failo')
    s.add_argument('lcov')
    s.set_defaults(run=summary)
    m = sub.add_parser('matrix', help='kiekvieno testo padengti sakiniai ir baigtys')
    m.add_argument('out')
    m.add_argument('test_files', nargs='+')
    m.set_defaults(run=matrix)
    args = parser.parse_args()
    args.run(args)


if __name__ == '__main__':
    main()
