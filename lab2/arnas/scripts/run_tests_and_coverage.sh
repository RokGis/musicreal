#!/usr/bin/env bash
# LD2 (Arnas): LD1 srauto testų pradinis paleidimas, LD2 testai, analizatorius ir
# friendsFeedQuery() / FriendFeed.build() padengimas.
# Naudojimas (iš repozitorijos šaknies):
#   bash lab2/arnas/scripts/run_tests_and_coverage.sh            # be matricų
#   MATRIX=1 bash lab2/arnas/scripts/run_tests_and_coverage.sh   # + kiekvieno testo matrica (~5 min.)
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

R=lab2/arnas/results
COV="python3 lab2/arnas/scripts/function_coverage.py"
mkdir -p "$R/baseline_ld1" "$R/final"

echo "== Sakinių ir sprendimų žemėlapis (Dart AST) =="
dart run lab2/arnas/tools/coverage_map/bin/coverage_map.dart \
    lib/pages/home/home_widget.dart friendsFeedQuery FriendFeed.build > "$R/coverage_map.json"

echo "== LD1 srauto testai =="
flutter test --no-pub --branch-coverage --coverage-path "$R/baseline_ld1/lcov.info" -r expanded \
    test/tests/feed_query_test.dart test/tests/feed_widget_test.dart > "$R/baseline_ld1/test_run.txt" 2>&1
grep -E 'All tests passed|Some tests failed' "$R/baseline_ld1/test_run.txt" | tail -1
$COV summary "$R/baseline_ld1/lcov.info" > "$R/baseline_ld1/coverage.txt"

echo "== LD2 testai =="
dart analyze test/ld2_arnas > "$R/final/analyze.txt" 2>&1; tail -1 "$R/final/analyze.txt"
flutter test --no-pub --branch-coverage --coverage-path "$R/final/lcov.info" -r expanded \
    test/ld2_arnas > "$R/final/test_run.txt" 2>&1
grep -E 'All tests passed|Some tests failed' "$R/final/test_run.txt" | tail -1
flutter test --no-pub --branch-coverage --coverage-path "$R/final/lcov_unit_widget.info" \
    test/ld2_arnas/friends_feed_query_test.dart test/ld2_arnas/friend_feed_build_test.dart \
    > "$R/final/test_run_unit_widget.txt" 2>&1
flutter test --no-pub test/ld2_arnas/feed_integration_test.dart -r expanded > "$R/final/integration_run.txt" 2>&1
$COV summary "$R/final/lcov.info" > "$R/final/coverage_all.txt"
$COV summary "$R/final/lcov_unit_widget.info" > "$R/final/coverage_unit_widget.txt"
grep -E '^==|^Eilutės|^VM|^Sakiniai|^Sprendimų' "$R/final/coverage_all.txt"

if [ "${MATRIX:-0}" = 1 ]; then
  $COV matrix "$R/baseline_ld1/matrix.md" test/tests/feed_query_test.dart test/tests/feed_widget_test.dart > /dev/null
  $COV matrix "$R/final/matrix.md" test/ld2_arnas/friends_feed_query_test.dart \
      test/ld2_arnas/friend_feed_build_test.dart test/ld2_arnas/feed_integration_test.dart > /dev/null
  echo "Matricos: $R/baseline_ld1/matrix.md, $R/final/matrix.md"
fi

if command -v genhtml >/dev/null; then
  genhtml "$R/final/lcov.info" --branch-coverage -q -o "$R/final/html" 2>/dev/null \
    || genhtml "$R/final/lcov.info" -q -o "$R/final/html"
fi
