#!/usr/bin/env bash
# LD2, 5 ir 6.1 užduotys (Arnas): friendsFeedQuery() ir FriendFeed.build() metrikos.
#   ciklomatinis sudėtingumas, MI, Halstead V, SLOC – dart_code_linter 4.4.2
#   kognityvinis sudėtingumas                     – cognitive_complexity 0.3.0
# Naudojimas (iš repozitorijos šaknies): bash lab2/arnas/scripts/measure_complexity.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SRC=lib/pages/home/home_widget.dart
OUT=lab2/arnas/results/metrics
mkdir -p "$OUT"

echo "== Aplinka =="
date '+%Y-%m-%d %H:%M'
echo "šaka $(git rev-parse --abbrev-ref HEAD), commit $(git rev-parse --short HEAD)"
flutter --version 2>/dev/null | head -1
dart --version 2>&1
dart pub global list | grep -E '^(cognitive_complexity|dart_code_linter) '

echo
echo "== cognitive_complexity $SRC =="
dart pub global run cognitive_complexity "$SRC" 2>/dev/null \
  | grep -v -E '^(MSG|IO|FINE) *:' | tee "$OUT/cognitive.txt"
dart pub global run cognitive_complexity --format json "$SRC" 2>/dev/null \
  | grep -v -E '^(MSG|IO|FINE) *:' > "$OUT/cognitive.json"

echo
echo "== dart_code_linter:metrics analyze lib/pages/home =="
dart pub global run dart_code_linter:metrics analyze lib/pages/home \
    --reporter=console-verbose --no-congratulate 2>/dev/null \
  | sed 's/\x1b\[[0-9;]*[A-Za-z]//g' | grep -v -E 'Analyzing|Processing' \
  > "$OUT/dcl_console.txt" || true
# Tik dvi Arno funkcijos; visas failas – $OUT/dcl_console.txt.
awk '/^[A-Z]+ +(friendsFeedQuery|FriendFeed\.build)$/{p=1} p{print} p&&/^$/{p=0}' "$OUT/dcl_console.txt"

dart pub global run dart_code_linter:metrics analyze lib/pages/home \
    --reporter=json --json-path="$OUT/dcl.json" >/dev/null 2>&1 || true
dart pub global run dart_code_linter:metrics analyze lib/pages/home \
    --reporter=html --output-directory="$OUT/dcl_html" >/dev/null 2>&1 || true
# Viso lib/ MI pasiskirstymui (6.1): python3 lab2/arnas/scripts/mi_check.py
dart pub global run dart_code_linter:metrics analyze lib \
    --reporter=json --json-path="$OUT/dcl_lib.json" >/dev/null 2>&1 || true
echo "Originalios ataskaitos: $OUT/dcl.json, $OUT/dcl_lib.json, $OUT/dcl_html/lib/pages/home/home_widget.html"
