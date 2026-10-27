# LD2 – Arno dalis: draugų srautas

MusicReal 2 laboratorinio darbo Arno dalies (5, 6.1–6.3, 8.1, 8.2.a) matavimai, testai ir
įrodymai. Archyvas atkartoja repozitorijos kelius, todėl jį reikia išskleisti
repozitorijos šaknyje.

## Kodo versija ir aplinka

| | |
|---|---|
| Repozitorija | https://github.com/RokGis/musicreal |
| Šaka ir commit | `arnas-2lb`, `d90e75ae77d128f895771bfc709856d50ddaf8d6` (tas pats kaip Manto matavimuose; `upstream/main` nuo jo nepasikeitęs) |
| Programos kodas | nekeistas (`git diff` tuščias) |
| Flutter / Dart | 3.44.9 / 3.12.2 |
| OS | Linux Mint 22.3 |
| Python | 3.12.3 (pagalbiniams skriptams) |
| Metrikų įrankiai | dart_code_linter 4.4.2, cognitive_complexity 0.3.0 |
| Data | 2026-10-25 |

Tikslios versijos ir laikas – `results/env.txt`.

## Analizuojamos funkcijos

| Funkcija | Vieta | Paskirtis |
|---|---|---|
| `friendsFeedQuery()` | `lib/pages/home/home_widget.dart:182–192` | Firestore užklausa: draugų šiandienos įrašai, nuo naujausio |
| `FriendFeed.build()` | `lib/pages/home/home_widget.dart:345–393` | Srauto būsenos: nėra draugų, kraunama, nėra įrašų, įrašų sąrašas |

## Svarbiausi rezultatai

| Rodiklis | friendsFeedQuery() | FriendFeed.build() | Šaltinis |
|---|---|---|---|
| Ciklomatinis sudėtingumas | 1 | 4 | dart_code_linter |
| Kognityvinis sudėtingumas | 0 | 5 | cognitive_complexity |
| Prižiūrimumo indeksas | 74 | 44 | dart_code_linter |
| Halstead V / SLOC | 33,2 / 5 | 846,0 / 44 | dart_code_linter |

| Testų rinkinys | Testai | PASS | FAIL |
|---|---|---|---|
| LD1 srauto testai (`test/tests/feed_*`) | 22 | 19 | 3 (žinomi defektai SCRUM-167, SCRUM-168) |
| LD2, pirmasis variantas | 17 | 15 | 2 (testų klaidos) |
| LD2, galutinis variantas | 17 | 17 | 0 |

| Padengimas | friendsFeedQuery() LD1 | LD2 | FriendFeed.build() LD1 | LD2 |
|---|---|---|---|---|
| Eilutės (LCOV DA) | 4/4 | 4/4 | 21/23 | 23/23 |
| VM šakų taškai (LCOV BRDA) | 1/1 | 1/1 | 6/7 | 7/7 |
| Sakiniai (AST + DA) | 1/1 | 1/1 | 11/12 | 12/12 |
| Sprendimų baigtys (if true/false) | netaikoma | netaikoma | 6/6 | 6/6 |

LD2 reikšmės vienodos ir be integracinio testo I01 (`final/coverage_unit_widget.txt`).

## Struktūra

```
lab2/arnas/
  README.md
  scripts/measure_complexity.sh        sudėtingumas, MI (5, 6.1)
  scripts/run_tests_and_coverage.sh    LD1 ir LD2 testai, analizatorius, padengimas
  scripts/function_coverage.py         funkcijų padengimas iš LCOV + AST žemėlapio, matricos
  scripts/screenshot.py                ekrano kopijos iš žurnalų ir HTML ataskaitų
  scripts/mi_check.py                  MI formulės patikrinimas ir viso lib/ MI pasiskirstymas (6.1)
  tools/coverage_map/                  Dart AST įrankis: sakiniai ir sprendimai
  results/env.txt                      aplinka
  results/metrics/                     cognitive.txt/json, dcl_console.txt, dcl.json, dcl_html/,
                                       dcl_lib.json (visas lib/), mi_check.txt
  results/coverage_map.json            AST sakinių ir sprendimų sąrašas
  results/baseline_ld1/                LD1 testų žurnalas, lcov.info, padengimas, matrica
  results/first_version/               pirmasis LD2 testų variantas (prieš paleidimą), SHA256SUMS,
                                       pirmojo paleidimo ir analizatoriaus žurnalai
  results/final/                       galutiniai žurnalai, lcov failai, padengimas, matrica,
                                       fixes.diff, pakartotiniai ir atsitiktinės tvarkos paleidimai
  results/screenshots/                 01–12 ekrano kopijos
test/ld2_arnas/
  friends_feed_query_test.dart         Q01–Q09 (friendsFeedQuery)
  friend_feed_build_test.dart          F01–F07 (FriendFeed.build)
  feed_integration_test.dart           I01 (6.3)
```

## Atkūrimas

```bash
git switch arnas-2lb                                  # commit d90e75a
flutter pub get
dart pub global activate cognitive_complexity 0.3.0
dart pub global activate dart_code_linter 4.4.2
(cd lab2/arnas/tools/coverage_map && dart pub get)

bash lab2/arnas/scripts/measure_complexity.sh                  # 5, 6.1
MATRIX=1 bash lab2/arnas/scripts/run_tests_and_coverage.sh     # 5.5, 6.3, 8.1, 8.2.a
```

Atskiros komandos:

```bash
dart analyze test/ld2_arnas
flutter test --no-pub --branch-coverage --coverage-path lab2/arnas/results/final/lcov.info -r expanded test/ld2_arnas
flutter test --no-pub test/ld2_arnas/feed_integration_test.dart -r expanded
python3 lab2/arnas/scripts/function_coverage.py summary lab2/arnas/results/final/lcov.info
```

`MATRIX=1` kiekvieną testą paleidžia atskirai (`--plain-name`) ir užtrunka apie 5 min.

## Padengimo metodika

- Eilutės ir VM šakų taškai imami tiesiai iš `flutter test --branch-coverage` LCOV
  failo (DA ir BRDA įrašai). DA skaitiklio dydis nevertinamas – tik 0 arba > 0.
- Dart VM BRDA įrašai žymi blokų įėjimus (funkcija, uždarinys, then/else blokas). Kai
  `if` neturi `else`, false baigties įrašo nėra, todėl BRDA nelaikomi sprendimų
  padengimu.
- Sakinius ir sprendimus išvardija `tools/coverage_map` pagal Dart AST
  (`analyzer` 14.5.0): sakinys – Statement mazgas, išskyrus Block, ir `=>` kūnas
  (vienas sakinys). Sakinys laikomas įvykdytu, jei įvykdyta pirma DA eilutė jo ribose.
- `if` true baigtį liudija pirmas then šakos sakinys. False baigtį liudija kitas sakinys
  po `if`; tai galioja tik todėl, kad visi trys `build()` then blokai baigiasi `return`
  (įrankis tai patikrina).
- `build()` sąlygos neturi `&&` ir `||`, todėl išsišakojimų ir sprendimų padengimas
  sutampa. Tai nėra MC/DC ar visų kelių padengimas.
- Programos kodas neinstrumentuojamas ir nekeičiamas.

## Ekrano kopijos

`results/screenshots/` failai sukurti `scripts/screenshot.py`: išsaugotas žurnalas
atvaizduojamas HTML puslapyje ir nufotografuojamas antraštiniu Firefox. 02 ir 03 –
apkirpta dart_code_linter HTML ataskaita. Tekstas rodomas toks, kokį įrašė įrankiai.

| Failas | Turinys |
|---|---|
| 01 | Aplinka, cognitive_complexity lentelė, DCL metrikos |
| 02, 03 | DCL HTML ataskaita: friendsFeedQuery() be prieaugių, build() `+1 cyclo` 349, 368, 375 eil. |
| 04, 05 | LD1 testų paleidimas ir padengimas |
| 06 | LD2 pirmasis paleidimas (2 FAIL) |
| 07, 08 | LD2 galutinis paleidimas ir padengimas |
| 09, 10 | LD2 ir LD1 padengimo matricos |
| 11 | Integracinis testas I01 |
| 12 | Pirmojo ir galutinio varianto skirtumai |
| 13 | MI formulės patikrinimas ir viso lib/ MI pasiskirstymas |

## Apribojimai

- Testai vykdomi Dart VM su `fake_cloud_firestore` ir Manto platformos pakaitalu
  (`test/mantas/support`). Tikras Firebase serveris, indeksai, saugumo taisyklės ir
  tinklas netikrinami.
- I01 naudoja tikrą laikrodį. Paleidimas per vidurnaktį gali būti nestabilus.
- HTML padengimo ataskaitos (genhtml) nėra – `lcov` paketas neįdiegtas.
