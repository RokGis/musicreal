#!/usr/bin/env python3
"""LD2 6.1 (Arnas): prižiūrimumo indekso (MI) patikrinimas.

1. Formulės patikrinimas: iš Dart Code Linter 4.4.2 JSON paimamos Halstead
   apimtis V, ciklomatinis sudėtingumas CC ir SLOC, MI perskaičiuojamas pagal
   DCL formulę ir palyginamas su įrankio pateikta verte:
     MI = ceil(clamp((171 − 5,2·ln(max(1,V)) − 0,23·CC − 16,2·ln(max(1,SLOC))) / 171 × 100, 0, 100))
2. Visos programos MI: visų lib/ funkcijų indeksų pasiskirstymas iš to paties
   įrankio ataskaitos.

Įvestis (sukuria measure_complexity.sh):
  results/metrics/dcl.json      – lib/pages/home analizė
  results/metrics/dcl_lib.json  – viso lib/ analizė
Naudojimas (iš repozitorijos šaknies):
  python3 lab2/arnas/scripts/mi_check.py | tee lab2/arnas/results/metrics/mi_check.txt
"""

import json
import math
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
METRICS = ROOT / 'lab2/arnas/results/metrics'
TARGETS = ['friendsFeedQuery', 'FriendFeed.build']


def functions(path):
    for record in json.loads(Path(path).read_text())['records']:
        for name, fn in record['functions'].items():
            yield record['path'], name, {m['metricsId']: m['value'] for m in fn['metrics']}


def mi_formula(v, cc, sloc):
    raw = (171 - 5.2 * math.log(max(1, v)) - 0.23 * cc - 16.2 * math.log(max(1, sloc))) / 171 * 100
    return raw, math.ceil(min(100, max(0, raw)))


print('== 1. MI formulės patikrinimas (Dart Code Linter 4.4.2, commit d90e75a) ==')
print('MI = ceil(clamp((171 − 5,2·ln(V) − 0,23·CC − 16,2·ln(SLOC)) / 171 × 100, 0, 100))')
print()
for path, name, m in functions(METRICS / 'dcl.json'):
    if name not in TARGETS:
        continue
    v, cc, sloc = m['halstead-volume'], m['cyclomatic-complexity'], m['source-lines-of-code']
    raw, mi = mi_formula(v, cc, sloc)
    print(f'{name} ({path})')
    print(f'  V = {v:.2f}, CC = {cc}, SLOC = {sloc}')
    print(f'  5,2·ln(V) = {5.2 * math.log(v):.2f};  0,23·CC = {0.23 * cc:.2f};  16,2·ln(SLOC) = {16.2 * math.log(sloc):.2f}')
    print(f'  (171 − {5.2 * math.log(v):.2f} − {0.23 * cc:.2f} − {16.2 * math.log(sloc):.2f}) / 171 × 100 = {raw:.2f} → {mi}')
    print(f'  DCL pateikta reikšmė: {m["maintainability-index"]}  →  {"SUTAMPA" if mi == m["maintainability-index"] else "NESUTAMPA"}')
    print()

rows = [(m['maintainability-index'], name, path)
        for path, name, m in functions(METRICS / 'dcl_lib.json') if 'maintainability-index' in m]
values = [r[0] for r in rows]
below = [r for r in rows if r[0] < 50]
print('== 2. Viso lib/ kodo MI (visos funkcijos) ==')
print(f'Funkcijų: {len(values)}')
print(f'Vidurkis: {statistics.mean(values):.1f};  mediana: {statistics.median(values):g};  min: {min(values)};  max: {max(values)}')
print(f'Žemiau 50: {len(below)} ({100 * len(below) / len(values):.0f} %)')
print('Mažiausi indeksai:')
for mi, name, path in sorted(rows)[:6]:
    print(f'  {mi:3}  {name}  ({path})')
home = [r[0] for r in rows if r[2].endswith('home_widget.dart')]
print(f'home_widget.dart: {len(home)} funkcijų, MI vidurkis {statistics.mean(home):.1f}')
for name in TARGETS:
    mi = next(r[0] for r in rows if r[1] == name)
    print(f'{name}: MI {mi}; mažesnį MI turi {sum(1 for x in values if x < mi)} iš {len(values)} funkcijų')
