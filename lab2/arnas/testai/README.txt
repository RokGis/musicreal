Arno LD2 testai – viskas vienoje vietoje (kopijos iš test/ld2_arnas, test/tests, test/mantas/support
ir lab2/arnas/results; commit d90e75a)

1_LD2_testai                 galutiniai testai: Q01–Q09, F01–F07, I01
2_LD2_pirmas_variantas       asistento pirmas variantas ir jo paleidimas (15 PASS / 2 FAIL)
3_LD2_galutiniai_rezultatai  galutinis paleidimas (17/17 PASS), analizatorius, padengiamumas, matrica,
                             atsitiktinės tvarkos ir stabilumo paleidimai, fixes.diff (Q08 ir F06 pataisos)
4_LD1_testai                 LD1 srauto testai ir jų rezultatai (19 PASS / 3 FAIL)
5_pagalbiniai_failai         helpers.dart ir Manto Firestore pakaitalas, kuriuos naudoja testai (ne Arno kodas)
6_skriptai                   testų ir padengiamumo skriptai, AST sakinių ir sprendimų žemėlapis
7_ekrano_kopijos             testų, padengiamumo ir matricų ekrano kopijos (04–12)
env.txt                      aplinka: Flutter, Dart, OS

Čia tik kopijos: flutter test jų nevykdo, analizatorius netikrina. Paleidimas iš repozitorijos šaknies:
  flutter test test/ld2_arnas -r expanded
  bash lab2/arnas/scripts/run_tests_and_coverage.sh
