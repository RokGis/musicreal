import 'dart:convert';

class StatisticsProbe {
  static final Map<String, int> statements = {};
  static final Map<String, Map<String, int>> decisions = {};
  static void statement(String id) =>
      statements.update(id, (n) => n + 1, ifAbsent: () => 1);
  static bool condition(String id, bool value) {
    final counts = decisions.putIfAbsent(id, () => {'true': 0, 'false': 0});
    counts['$value'] = counts['$value']! + 1;
    return value;
  }

  static Iterable<T> iterations<T>(String id, Iterable<T> source) sync* {
    for (final value in source) {
      condition(id, true);
      yield value;
    }
    condition(id, false);
  }

  static void report() => print('STATISTICS_PROBE=${jsonEncode({
            'statements': statements,
            'decisions': decisions,
          })}');
}
