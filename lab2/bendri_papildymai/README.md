# MusicReal LD2 bendri papildymai

Dokumentas sutvarkytas 2026-10-27. Papildomi matavimai ir statistikos testai atlikti 2026-10-26.
Kodo versija: `d90e75ae77d128f895771bfc709856d50ddaf8d6`.
Aplinka: Windows, Flutter 3.44.9, Dart 3.12.2.

## Kas pridėta

- Bendri fizinio kodo dydžio matavimai su cloc 2.10.
- Trūkstamas statistikos funkcijų sakinių ir sprendimų padengimas.
- Pakartotinai patikrintos statistikos sudėtingumo reikšmės ir ištaisyti jų paaiškinimai.
- Iš „Confluence“ į šį priedą perkeltos pilnos Arno užklausos.
- Manto ir Edo instrukcijų santraukos su tikra šio pokalbio kilme.
- Atnaujinti Manto ir Edo rezultatų archyvai pateikti kataloge `studentu_archyvai`.

Originalus Roko LD2 archyvas šiame kompiuteryje neprieinamas. Roko anksčiau pateikti rezultatai dokumente atskirti nuo papildomo trijų testų patikrinimo. Jie nepateikiami kaip naujai pakartoti.

## Kodo dydis

`cloc_by_file.json` – originali ataskaita pagal failus; `cloc_console.log` – originali įrankio išvestis; `size_summary.json` – iš jų sudaryta suvestinė.

| Grupė | LOC | CLOC | NCLOC | Tuščios |
|---|---:|---:|---:|---:|
| Programos šaltiniai | 10 685 | 399 | 9 309 | 977 |
| Esami testai, atskirai | 2 896 | 174 | 2 261 | 461 |

LOC čia apima visas fizines eilutes. CLOC yra cloc komentarų eilutės, NCLOC – netuščios kodo eilutės. Eilutė su kodu ir komentaru skaičiuojama kaip kodas.

Apimtis: Git versijos lib Dart failai ir firebase/functions JavaScript failai, be paslėptos konfigūracijos. Testai skaičiuojami atskirai. Assets, build, priklausomybės ir vėliau sukurti LD2 testai neįtraukiami. FlutterFlow pagalbiniai failai parodyti atskirai; kiti lib failai nevadinami vien rankomis rašytais.

Pakartojimas:

1. Iš [oficialaus cloc leidimo](https://github.com/AlDanial/cloc/releases/tag/v2.10) parsisiųsti cloc-2.10.exe į šio katalogo `tools`.
2. `measure_size.py` pradžioje prireikus pakeisti REPO kelią.
3. Paleisti `python -X utf8 measure_size.py`.

Skriptas skaito tik konkrečius Git objektus ir nepakeičia darbo medžio. Visi analizuoti failai bei jų SHA256 pateikti `source_manifest.json`. cloc paleistas su `--skip-uniqueness`, todėl vienodi sekami failai taip pat įskaičiuojami.
Naudoto oficialaus exe SHA256: `97786c4b5bb71d2be67e42061a2f5d03db73bbf88228f8710001d770e867bbef`.
Įrankio dokumentacija: https://github.com/AlDanial/cloc.

## Papildomas statistikos patikrinimas

Failai `papildomi_testai/` turi būti įrašyti į projekto `test/ld2_statistics_check/`.
Jie naudoja esamą `test/mantas/support` aplinką iš tos pačios Git versijos.

```powershell
flutter test --no-pub test/ld2_statistics_check/statements_check_test.dart --coverage --branch-coverage --coverage-path statistics_lcov.info -r expanded
flutter analyze --no-pub test/ld2_statistics_check
```

V01 – tuščias sąrašas; V02 – kartojamos dainos, kelios emocijos ir trūkstami laukai; V03 – daugiau nei 10 dainų ir tuščios emocijos.
Visi 3 PASS, analizė: No issues found. Tai nėra visas Roko originalus rinkinys ir šie testai netikrina lygybės rikiavimo defekto.

| Funkcija | Eilutės | VM šakų taškai | AST sakiniai | Sprendimų baigtys |
|---|---:|---:|---:|---:|
| _emotionTotals | 8/8 | 4/4 | 7/7 | 4/4 |
| _topSongs | 18/18 | 9/9 | 20/20 | 8/8 |

Sakiniai yra AST Statement mazgai be Block, įskaitant continue ir anoniminių funkcijų kūno sakinius. Išraiškos nelaikomos atskirais sakiniais vien dėl to, kad yra naujoje eilutėje.

Sprendimų apskaita šiame papildyme apima if bei for-in ciklus. _emotionTotals turi vieną if ir vieną for; _topSongs – tris if ir vieną for. Todėl vardikliai 4 ir 8 skiriasi nuo Roko anksčiau pateiktų 2 ir 6, kuriuose buvo skaičiuojami tik if.

`instrument_statistics.dart` skaitiklius įterpia pagal originalų AST. For-in šaltinis apgaubiamas generatoriumi, kuris registruoja tikras iteracijas ir normalų ciklo užbaigimą; elementai neišmetami ir nekeičiami. Vieno sakinio if kūnai apgaubiami bloku, kad būtų suskaičiuotas ir continue. Instrumentuotas rinkinys taip pat davė 3 PASS. Originalus statistikos failas atkurtas `finally` bloke ir palygintas su HEAD.

Tai ne visų kelių, visų išimčių ar MC/DC matavimas. Implicitinių ?? bei ?. baigtys atskirais AST sprendimais neskaičiuojamos. VM BRDA rodikliai pateikti atskirai.

Pakartoti instrumentuotą matavimą galima su `run_statistics_check.ps1`; prireikus nurodyti Repo, Flutter, Dart ir AnalyzerConfig parametrus. Analyzer naudojamas iš įdiegto Dart Code Linter 4.4.2 priklausomybių (`analyzer` 14.5.0).
`statistics_map.json` nurodo kiekvieno skaitiklio vietą, `statistics_probe.log` – tikrus skaitiklius, `statistics_summary.json` – automatiškai sudarytą rezultatą.

## Ištaisyti paaiškinimai

Originali DCL ataskaita patvirtina:
- _emotionTotals CC = 1 + for + if + ?? = 4;
- _topSongs CC = 1 + for + 3 if + 2 ?? + ?. = 8.

Anoniminės funkcijos ar pats rikiavimo palyginimas čia nėra papildomi ciklomatiniai taškai. `statistics_metrics.json` turi tikslias prieaugių vietas.
Pakartotinis cognitive_complexity 0.3.0 matavimas patvirtino kognityvines reikšmes 3 ir 8.

„Jira“ SCRUM-48 aiškiai reikalauja, kad vienodo dažnio dainos būtų rikiuojamos pagal paskutinio klausymosi datą. Išvada, kad ši taisyklė neapibrėžta, pataisyta. Defektas registruotas kaip SCRUM-169.

## Testų kilmė

Manto ir Edo testai parengti šiame Codex pokalbyje. Tikslus modelio identifikatorius neišsaugotas. Generuota tęstinėje sesijoje su kodo ir ankstesnių testų kontekstu; instrukcijų santrauka nėra pateikiama kaip pažodinis atskiros vienkartinės užklausos tekstas.

Arno pilnos užklausos išsaugotos `arnas_prompt_1.txt`–`arnas_prompt_3.txt` tiesiai iš redaktoriaus kopijavimo formato. Roko bendros užklausos instrukcijos paliktos jo „Confluence“ dalyje.
LD1 testų autorystė atskirai nepatvirtinta, todėl rinkinių palyginimas neįrodo žmogaus ir asistento autorystės poveikio.
