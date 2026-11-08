param(
 [string]$Repo = 'C:\Users\pedse\Downloads\musicreal',
 [string]$Flutter = 'C:\Users\pedse\sdk\flutter\bin\flutter.bat',
 [string]$Dart = 'C:\Users\pedse\sdk\flutter\bin\dart.bat',
 [string]$AnalyzerConfig = 'C:\Users\pedse\AppData\Local\Pub\Cache\global_packages\dart_code_linter\.dart_tool\package_config.json'
)
$ErrorActionPreference = 'Stop'
Push-Location $Repo
try {
 $revision = git rev-parse HEAD
 if ($revision -ne 'd90e75ae77d128f895771bfc709856d50ddaf8d6') { throw 'Reikia ataskaitoje nurodytos kodo versijos' }
 & $Flutter test --no-pub test/ld2_statistics_check/statements_check_test.dart --coverage --branch-coverage --coverage-path "$PSScriptRoot\statistics_lcov.info" -r expanded *> "$PSScriptRoot\statistics_tests.log"
 if ($LASTEXITCODE -ne 0) { throw 'Pagrindiniai statistikos patikrinimai nepraeina' }
 & $Flutter analyze --no-pub test/ld2_statistics_check *> "$PSScriptRoot\statistics_analysis.log"
 if ($LASTEXITCODE -ne 0) { throw 'Statinės analizės pastabos' }
 & $Dart "--packages=$AnalyzerConfig" "$PSScriptRoot\instrument_statistics.dart" lib/statistics/statistics_widget.dart "$PSScriptRoot\statistics_widget.instrumented.dart" "$PSScriptRoot\statistics_map.json" "$Repo\test\ld2_statistics_check\coverage_probe.dart"
 if ($LASTEXITCODE -ne 0) { throw 'Instrumentavimas nepavyko' }
 Copy-Item -LiteralPath 'lib\statistics\statistics_widget.dart' -Destination "$PSScriptRoot\statistics_widget.original.dart" -Force
 try {
  Copy-Item -LiteralPath "$PSScriptRoot\statistics_widget.instrumented.dart" -Destination 'lib\statistics\statistics_widget.dart' -Force
  & $Flutter test --no-pub test/ld2_statistics_check/statements_check_test.dart -r expanded *> "$PSScriptRoot\statistics_probe.log"
  $probeExitCode = $LASTEXITCODE
 } finally {
  Copy-Item -LiteralPath "$PSScriptRoot\statistics_widget.original.dart" -Destination 'lib\statistics\statistics_widget.dart' -Force
 }
 if ($probeExitCode -ne 0) { throw 'Instrumentuotas patikrinimas nepraeina' }
 if ((git hash-object lib/statistics/statistics_widget.dart) -ne (git rev-parse HEAD:lib/statistics/statistics_widget.dart)) { throw 'Programos failas skiriasi nuo HEAD' }
 python -X utf8 "$PSScriptRoot\summarize_statistics.py"
} finally { Pop-Location }
