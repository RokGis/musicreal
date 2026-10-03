# MANTO_4_UZDUOTIS_FINAL — automatizuotas reikalavimais grįstas testavimas

Autorius: Mantas · Apimtis: SCRUM-62, SCRUM-65, SCRUM-30, SCRUM-33
Šaltinis: Jira eksportas `Jira (1).csv` (2026-10-03, naujausias). Jira nekeista.
Kodas: `RokGis/musicreal`, `main` @ `5c4a5d8`. Produkcinis kodas (`lib/`) nekeistas.
Aplinka: Flutter 3.44.9 (stable), Dart 3.12.2, Windows 11.

## 1. Testavimo būdas

- **Automatizuotas Flutter testavimas** (`flutter_test`): 37 widget testai (`testWidgets`) ir 1 unit testas (`test`).
- Widget testai paleidžia **tikrus** programos ekranus (`PostWidget`, `HomeWidget`, `StatisticsWidget`, `LogInPageWidget`, `ProfileWidget`) ir tikrą autentifikacijos logiką (`FirebaseAuthManager`, `google_auth.dart`, `facebook_auth.dart`, `maybeCreateUser`).
- **Išorinės priklausomybės pakeistos test doubles** platformos sąsajos lygyje (`test/mantas/support/`):
  - Cloud Firestore → atminties „fake“ (`fake_firestore.dart`);
  - Firebase Auth, Google Sign-In, Facebook Login → „fake“ platformos (`fake_auth.dart`).
  Programos kodas kviečia `FirebaseFirestore.instance` / `FirebaseAuth.instance` tiesiogiai, todėl pakeistas tik žemiausias (platformos) sluoksnis — visa `cloud_firestore`, `firebase_auth`, `google_sign_in`, `flutter_facebook_auth` Dart logika vykdoma tikra.
- **Kodėl ne tikras OAuth:** automatiniai testai turi būti deterministiniai ir nepriklausyti nuo tinklo, Google/Facebook paskyrų, CAPTCHA, 2FA ir slaptažodžių; tikras OAuth negali būti paleistas `flutter test` aplinkoje (nėra naršyklės/įrenginio). Klaidų ir atšaukimo scenarijai (pvz. tinklo klaida) tikru OAuth apskritai nėra patikimai atkuriami.
- Fake atsakymai atitinka **tikrų SDK** elgesį (patikrinta paketų šaltiniuose):
  - Facebook atšaukimas: Android `FacebookLoginResultDelegate.java:37` → `CANCELLED`; Dart `FacebookAuthPlatformImplementation.login()` grąžina `LoginResult(status: cancelled, accessToken: null)` — tą patį grąžina fake.
  - Google: `GoogleSignInPlugin.java:126-129` / `FLTGoogleSignInPlugin.m:27-30` skelbia `sign_in_canceled`, `network_error`, `sign_in_failed` — fake meta tuos pačius kodus.
- Testavimo technikos (pagal Jira TC): EP, BVA (riba 5), sprendimų lentelės (DT R1–R3), funkcinis; papildomai — klaidomis grįstas testavimas (EBT, 4c).

## 2. Apimtis

| Reikalavimas | Tipas | Tema |
|---|---|---|
| SCRUM-62 | Feature | Emocijos (jaustuko) pasirinkimas įkeliant dainą |
| SCRUM-65 | Story | Emocijos pridėjimas prie dainos jaustukais |
| SCRUM-30 | Feature | Registracija / prisijungimas / profilis tik per išorines platformas |
| SCRUM-33 | Story | Registracija per Google / Meta / Facebook |

## 3. Vykdymo suvestinė (tik Mantas)

| | Viso | PASS | FAIL | BLOCKED |
|---|---|---|---|---|
| Automatiniai testai `test/mantas/` | **38** | **29** | **9** | 0 |
| Jira TC (TC-FEAT62/US65/FEAT30/US33) | **22** | **18** | **4** | 0 |
| Acceptance Criteria | **21** | **17** | **4** | 0 |

Rezultatas identiškas dviejuose paleidimuose (tas pats 9 krentančių testų rinkinys).
Senas `test/widget_test.dart` į šiuos skaičius **neįtrauktas** (žr. 8 sk.).

Jira TC FAIL: TC-FEAT62-03, TC-US65-01, TC-FEAT30-02, TC-US33-04.
AC FAIL: SCRUM-62 AC2, SCRUM-65 AC65-1, SCRUM-30 AC6, SCRUM-33 AC6.

9 FAIL pagal kategoriją:
- kategorija 1 (patvirtinti reikalavimų defektai): **4 defektų grupės, kurias patvirtina 8 krentantys reikalavimų / AC testai** — D1 (3 testai), D2 (3), D3 (1), D4 (1);
- kategorija 2 (EBT defektai be AC): 0;
- kategorija 3 (reikalavimo spraga): 1 testas — G1;
- kategorija 4 (infrastruktūra): 0 Manto testų (tik senas `widget_test.dart`, neįskaičiuotas).

## 4. AC padengimas (100 %)

| Reik. | AC | Jira TC | Automatinis testas | Tipas | Rezultatas | Klasifikacija |
|---|---|---|---|---|---|---|
| SCRUM-62 | AC1 be jaustuko įkelti negalima | TC-FEAT62-01 | `TC-FEAT62-01 (EP: 0 emojis)` | widget | PASS | requirement test |
| SCRUM-62 | AC1 (teigiama klasė) | TC-FEAT62-02 | `TC-FEAT62-02 (EP: 1 emoji)` | widget | PASS | requirement test |
| SCRUM-62 | AC2 sąrašas iš 5 jaustukų | TC-FEAT62-03 | `TC-FEAT62-03 (BVA: 5)` | widget | **FAIL** | requirement test |
| SCRUM-62 | AC2 | TC-FEAT62-03 | `TC-FEAT62-03 (supporting unit test, BVA: 5)` | unit | **FAIL** | requirement test |
| SCRUM-62 | AC4 tik vienas jaustukas | TC-FEAT62-04 | `TC-FEAT62-04` | widget | PASS | requirement test |
| SCRUM-62 | AC3 išsaugomas ir rodomas suvestinėje | TC-FEAT62-05 | `TC-FEAT62-05` | widget | PASS | requirement test (+ G3) |
| SCRUM-65 | AC65-1 5 jaustukai | TC-US65-01 | `TC-US65-01 (AC65-1)` | widget | **FAIL** | requirement test |
| SCRUM-65 | AC65-2 tik vienas | TC-US65-02 | `TC-US65-02 (AC65-2)` | widget | PASS | requirement test |
| SCRUM-65 | AC65-3 be jaustuko negalima | TC-US65-03 | `TC-US65-03 (AC65-3)` | widget | PASS | requirement test |
| SCRUM-65 | AC65-4 išsaugomas su daina | TC-US65-04 | `TC-US65-04 (AC65-4)` | widget | PASS | requirement test |
| SCRUM-65 | AC65-5 rodomas sraute | TC-US65-05 | `TC-US65-05 (AC65-5)` | widget | PASS | requirement test |
| SCRUM-30 | AC1 pateikiamos platformos | — (Jira TC nėra) | `SCRUM-33 AC1 / SCRUM-30 AC1` | widget | PASS | requirement test |
| SCRUM-30 | AC2 vienas profilis | TC-FEAT30-03 | `TC-FEAT30-03 (DT R2)` | widget | PASS | requirement test |
| SCRUM-30 | AC3 uid, el. paštas, vardas | TC-FEAT30-03, TC-FEAT30-05 | `TC-FEAT30-03`, `TC-FEAT30-05 (EP: no name)` | widget | PASS | requirement test |
| SCRUM-30 | AC4 pakartotinai — naujo nėra | TC-FEAT30-04 | `TC-FEAT30-04 (DT R3)` | widget | PASS | requirement test |
| SCRUM-30 | AC5 pasiekia profilio info | TC-FEAT30-06 | `TC-FEAT30-06` | widget | PASS | requirement test (+ G2) |
| SCRUM-30 | AC6 nepavykus — neprijungtas + klaidos pranešimas | TC-FEAT30-01 | `TC-FEAT30-01 (DT R1)` | widget | PASS | requirement test |
| SCRUM-30 | AC6 atšaukus (Facebook) | TC-FEAT30-02 | `TC-FEAT30-02 (DT R1)` | widget | **FAIL** | requirement test |
| SCRUM-30 / 33 | AC6 atšaukus (Google) | — (Jira TC nėra, G4) | `AC6-GOOGLE-CANCEL` | widget | **FAIL** | requirement test |
| SCRUM-33 | AC1 Google ir Meta/Facebook | TC-US33-01/02 1 žingsnis | `SCRUM-33 AC1 / SCRUM-30 AC1` | widget | PASS | requirement test |
| SCRUM-33 | AC2 sukuriama paskyra | TC-US33-01, TC-US33-02 | `TC-US33-01 (EP: Google)`, `TC-US33-02 (EP: Facebook)` | widget | PASS | requirement test |
| SCRUM-33 | AC3 profilis iš teikėjo duomenų | TC-US33-06 | `TC-US33-06` | widget | PASS | requirement test |
| SCRUM-33 | AC4 automatiškai prijungiamas | TC-US33-05 | `TC-US33-05` | widget | PASS | requirement test |
| SCRUM-33 | AC5 be papildomos formos | TC-US33-06 | `TC-US33-06` | widget | PASS | requirement test |
| SCRUM-33 | AC6 nepavykus — pranešimas | TC-US33-03 | `TC-US33-03 (DT: error branch)` | widget | PASS | requirement test |
| SCRUM-33 | AC6 atšaukus (Facebook) | TC-US33-04 | `TC-US33-04 (DT: cancel branch)` | widget | **FAIL** | requirement test |

Klaidomis grįsti testai (EBT) — 6 sk. Visi 21 AC turi bent vieną automatinį testą; visi 22 Jira TC vykdyti.

## 5. Patvirtinti reikalavimų įgyvendinimo defektai (kategorija 1)

4 defektų grupės, kurias patvirtina 8 krentantys reikalavimų / AC testai. Tai nėra 8 skirtingi defektai: keli testai tikrina tą pačią šakninę priežastį.

**D1 — Rodomi 3 jaustukai vietoje 5**
- Reikalavimas / AC: SCRUM-62 AC2 („sąrašas iš 5 galimų pasirinkti jaustukų“), SCRUM-65 AC65-1.
- Jira TC: TC-FEAT62-03, TC-US65-01. Testai: `TC-FEAT62-03 (BVA: 5)`, `TC-FEAT62-03 (supporting unit test)`, `TC-US65-01` — FAIL (`Expected: <5> Actual: <3>`).
- Tikėtasi 5, faktiškai 3.
- Šaltinis: `lib/pages/post/post_widget.dart:18-23` (`kEmotions`, komentaras „The three emotions a post can carry.“); demo duomenys dubliuoja sąrašą `lib/demo/demo_data.dart:11-15`.
- Patvirtinta: automatiniu testu ✔; kodu ✔; diegtame demo `main.dart.js` yra lygiai 3 jaustukų URL ✔; web demo ekrane 3 jaustukus 2026-10-03 pastebėjo Claude naršyklėje (stebėjimas, ne Manto įrodymas). **Manto asmeninė demo ekrano kopija dar nepadaryta** — žr. paskutinį skyrių.
- Svarba: Major (Jira prioritetas High).

**D2 — Facebook atšaukimas / nesėkmė: null dereferencija, pranešimo nėra**
- Reikalavimas / AC: SCRUM-30 AC6, SCRUM-33 AC6.
- Jira TC: TC-FEAT30-02, TC-US33-04; papildomai `EBT-AUTH-03` (FAILED būsena). Visi FAIL.
- Tikėtasi: naudotojas neprijungtas, lieka prisijungimo ekrane, rodomas klaidos pranešimas.
- Faktiškai: `Null check operator used on a null value` ties `lib/auth/firebase_auth/facebook_auth.dart:61` (iOS/kitos šaka; Android šakoje ta pati klaida `:57`). `FirebaseAuthManager._signInOrCreateAccount` gaudo tik `FirebaseAuthException` (`firebase_auth_manager.dart:340`), todėl išimtis neapdorojama; pranešimas nerodomas. Naudotojas neprijungiamas (ta AC dalis tenkinama).
- Ar tai fake artefaktas? **Ne.** Tikras `flutter_facebook_auth` 7.1.2 atšaukus grąžina `LoginResult(status: cancelled, accessToken: null)` (Android `CANCELLED`/`FAILED` → `getResultFromException`). Kodas tikrina ne `status`, o daro `result!`.
- Platforma: **Android/iOS** (ne web). Web šaka (`kIsWeb` → `signInWithPopup`) yra kitokia ir šios klaidos neturi.
- Patvirtinta: kodu ✔, SDK šaltiniu ✔, automatiniu testu ✔; rankiniu būdu **nepatikrinta** (demo — web; Facebook programėlė nesukurta, SCRUM-69).
- Svarba: Major.

**D3 — Uždarius Google paskyros pasirinkimą, pranešimas nerodomas**
- Reikalavimas / AC: SCRUM-30 AC6, SCRUM-33 AC6 (abu aiškiai: „atšaukus … pateikiamas klaidos pranešimas“). Jira TC šiam Google atvejui **nėra** (žr. G4).
- Testas: `AC6-GOOGLE-CANCEL` — FAIL (`Found 0 widgets with type "SnackBar"`).
- Faktiškai: `google_auth.dart:14-16` grąžina `null`, `firebase_auth_manager.dart:337` grąžina `null`, `log_in_page_widget.dart:292` tyliai `return`. Naudotojas neprijungtas (OK), bet pranešimo nėra.
- Platforma: **Android/iOS**. Web'e uždarius popup `signInWithPopup` meta `FirebaseAuthException` (`popup-closed-by-user`) → pagal kodą pranešimas būtų rodomas (nepatikrinta).
- Patvirtinta: kodu ✔, automatiniu testu ✔; rankiniu būdu **nepatikrinta** (demo Google mygtukas apeina autentifikaciją).
- Svarba: Minor.

**D4 — Google SDK klaida (`network_error` / `sign_in_failed`) neapdorojama**
- Reikalavimas / AC: SCRUM-30 AC6 („nepavykus … autentifikacijai … pateikiamas klaidos pranešimas“). Rasta klaidomis grįstu testu.
- Testas: `EBT-AUTH-02` — FAIL (`PlatformException(network_error, …)` neapdorota, pranešimo nėra).
- Faktiškai: `GoogleSignIn.signIn()` (`google_auth.dart:14`) meta `PlatformException`, kurios `firebase_auth_manager.dart:340` negaudo.
- Kodai `network_error`, `sign_in_failed` yra tikrame plugin'e (`GoogleSignInPlugin.java:128-129`, `FLTGoogleSignInPlugin.m:29-30`).
- Platforma: Android/iOS. Patvirtinta: kodu ✔, testu ✔; rankiniu būdu **nepatikrinta**.
- Svarba: Medium.

## 6. Klaidomis grįsto testavimo radiniai (atskirai nuo AC)

| EBT | Kodėl naudingas | Susietas su AC | Rezultatas | Jei FAIL |
|---|---|---|---|---|
| EBT-POST-01 jaustukas be dainos | privalomas laukas „daina“ tuščias | SCRUM-61/62 prielaida | PASS | — |
| EBT-POST-02 tuščia forma | abu privalomi laukai tušti | SCRUM-62 AC1 | PASS | — |
| EBT-POST-03 tas pats jaustukas 2 kartus | perjungimo (toggle) klaida → 0 arba 2 pasirinkti | SCRUM-62 AC4 | PASS | — |
| EBT-POST-04 pataisymas po blokavimo | būsena po klaidos neužstringa | SCRUM-62 AC1+AC3 | PASS | — |
| EBT-POST-05 dvigubas „Post“ | dublikato įrašai | SCRUM-62 AC3 | PASS | — |
| EBT-POST-06 dainos ir jaustuko keitimas | išsaugoma paskutinė, ne pirmoji reikšmė | SCRUM-62 AC3+AC4 | PASS | — |
| EBT-POST-07 DB rašymo klaida | tinklo/teisių klaida įkeliant | **nėra AC** | FAIL | G1 (reikalavimo spraga) |
| EBT-AUTH-02 Google `network_error` | SDK išimtis | SCRUM-30 AC6 | FAIL | D4 |
| EBT-AUTH-03 Facebook `FAILED` | teikėjo nesėkmė | SCRUM-30 AC6 | FAIL | D2 (ta pati priežastis) |
| EBT-AUTH-04 `account-exists-with-different-credential` | tas pats el. paštas per kitą teikėją | SCRUM-30 AC6 | PASS | — |
| EBT-AUTH-05 auth manager grąžina `null` | neprijungimas atšaukus / atmetus | SCRUM-30 AC6 | PASS | — |
| EBT-AUTH-06 dvigubas Google paspaudimas | dvigubas profilis / 2 dialogai | SCRUM-30 AC2 | PASS | — |
| EBT-AUTH-07 teikėjas nepateikia el. pašto | trūkstami neprivalomi duomenys | SCRUM-30 AC3 „jei pateikia“ | PASS | — |

Papildomai klaidų atvejus padengia Jira TC: atmestas/pasibaigęs kredencialas (TC-FEAT30-01, TC-US33-03), trūkstamas vardas (TC-FEAT30-05), pakartotinis prisijungimas (TC-FEAT30-04).
**Kategorija 2 (EBT defektai be AC): nėra** — visi EBT FAIL atvejai arba pažeidžia AC6 (D2, D4), arba yra neapibrėžtas elgesys (G1).

## 7. Reikalavimų / testuojamumo spragos (kategorija 3 — ne programos klaidos)

- **G1 — Nepavykusio įkėlimo elgesys neapibrėžtas.** SCRUM-62 komentare (2026-04-15) pažymėta, kad trūksta klaidų pranešimų nesėkmingo įkėlimo atvejais. `EBT-POST-07` FAIL: `_submit` (`post_widget.dart:113`) neturi `try/catch`, išimtis neapdorojama, naudotojas nieko nemato; įrašas neišsaugomas ir sėkmė neimituojama. Kadangi AC to nereikalauja — tai spraga, ne defektas.
- **G2 — TC-FEAT30-06 reikalauja daugiau nei AC.** TC laukiamas rezultatas „rodoma … (uid, el. paštas, vardas)“, o AC5 — tik „gali pasiekti savo profilio informaciją“, AC3 — uid **išsaugomas**. Pirmesnėje ataskaitoje buvęs „D5 — uid nerodomas“ buvo **testo klaida (per griežtas testas)** ir atšauktas. Dabar testas tikrina: matomi vardas ir el. paštas, rodomas būtent savo (ne kito) profilis, profilio įraše yra uid. Rekomenduojama komandai suderinti TC formuluotę su AC (Jira nekeičiau).
- **G3 — „Suvestinė“ (SCRUM-62 AC3) neapibrėžta.** Interpretuota kaip Statistikos ekranas (vienintelis po įkėlimo rodantis savo dainas su jaustuku); srautas tikrinamas atskirai (AC65-5).
- **G4 — Jira TC rinkinys nepilnas.** AC6 apima abu teikėjus, bet atšaukimo TC yra tik Facebook; SCRUM-30 AC1 neturi TC. Pridėti testai `AC6-GOOGLE-CANCEL` ir `SCRUM-33 AC1 / SCRUM-30 AC1`.
- **G5 — Pranešimų tekstai neapibrėžti; TC-FEAT62-01 leidžia „blokuojamas / mygtukas neaktyvus“.** Testai netikrina pranešimų formuluočių; AC6 „klaidos pranešimas“ tikrinamas kaip bet koks SnackBar.
- **G6 — SCRUM-62 DoD mini „sėkmės pranešimą“**, bet tai ne AC; ne demo režime po įkėlimo sėkmės pranešimo nėra. Netestuota kaip defektas.

## 8. Infrastruktūros / platformos apribojimai (kategorija 4)

- **Fake OAuth:** Google/Facebook dialogai netikri; tikri OAuth konfigūracijos klausimai (client ID, Facebook programėlė — SCRUM-69 „not qualified“) netikrinami. TC-US33-02 PASS įrodo tik kodo kelią, ne veikiantį Facebook prisijungimą.
- **Fake Firestore:** saugumo taisyklės (`firebase/firestore.rules`), indeksai, realus vėlinimas netikrinami.
- **Platforma:** testai vykdomi Dart VM (`kIsWeb == false`) Windows'e → tikrinamos mobiliosios šakos. Web šaka (`signInWithPopup`, kuri veikia demo) nepadengta; Facebook Android šaka (`Platform.isAndroid`, `:57`) nevykdyta, bet turi tą pačią `result!` klaidą.
- **Demo apribojimas:** `rokgis.github.io/musicreal` yra DEMO build (`--dart-define=DEMO=true`): Google mygtukas apeina autentifikaciją, duomenys atmintyje. Todėl D2–D4 ir G1 demo neatkuriami. Facebook mygtukas demo **neapeina** autentifikacijos ir paleistų tikrą Facebook popup — rankiniam tikrinimui netinka.
- **Testų technika:** `google_auth.dart` turi modulio lygio `GoogleSignIn` singletoną, kurio future'ai išlieka tarp testų; todėl teikėjo srautas vykdomas per `tester.runAsync` (kitaip po pirmo testo užstrigtų). Google Fonts testuose pakeisti repozitorijos šriftu (be tinklo).
- **Senas `test/widget_test.dart`:** sugeneruotas šabloninis „Counter increments smoke test“ be jokių tikrinimų; krenta, nes neinicializuotas Firebase (`FirebaseException: No Firebase App`). Tai ne MusicReal reikalavimo defektas ir ne Manto apimtis — **paliktas nepakeistas** (variantas A), į Manto rezultatus neįtrauktas. Pilnas `flutter test`: 39 testai, 29 PASS, 10 FAIL (9 Manto + 1 senas).

## 9. Įrodymų (screenshot) sąrašas

Bendri:
1. `flutter --version` (Flutter 3.44.9).
2. `flutter test test/mantas/ -r expanded` — visas sąrašas ir paskutinė eilutė `+29 -9: Some tests failed`. Antras paleidimas — tas pats rezultatas (determinizmas).

Kiekvienam FAIL — atskiras paleidimas (`--plain-name`) ir ekrano kopija su klaidos tekstu:

| FAIL testas | Komanda (`--plain-name`) | Kas turi matytis | Demo kopija |
|---|---|---|---|
| TC-FEAT62-03 (widget) | `"TC-FEAT62-03 (BVA: 5)"` | `Expected: <5> Actual: <3>` | **Taip** (D1 žingsniai žemiau) |
| TC-FEAT62-03 (unit) | `"supporting unit test"` | `has length of <3>` | — |
| TC-US65-01 | `"TC-US65-01"` | `Expected: <5> Actual: <3>` | ta pati D1 kopija |
| TC-FEAT30-02 | `"TC-FEAT30-02"` | `Null check operator… facebook_auth.dart:61:26` | Ne (C/D) |
| TC-US33-04 | `"TC-US33-04 (DT: cancel branch)"` | ta pati klaida + `0 widgets with type "SnackBar"` | Ne (C/D) |
| AC6-GOOGLE-CANCEL | `"AC6-GOOGLE-CANCEL"` | `Found 0 widgets with type "SnackBar"` | Ne (C) |
| EBT-AUTH-02 | `"EBT-AUTH-02"` | `PlatformException(network_error…)` | Ne (C) |
| EBT-AUTH-03 | `"EBT-AUTH-03"` | `Null check operator… facebook_auth.dart:61:26` | Ne (C/D) |
| EBT-POST-07 | `"EBT-POST-07"` | `Exception: permission-denied … post_widget.dart:113` | Ne (C) |

Rankinis patikrinimas: A — tik automatinis, B — papildomai demo, C — demo neatkuriama saugiai, D — blokuoja teikėjo/Firebase konfigūracija.
D1 → **B**; D2 → **C + D**; D3 → **C**; D4 → **C**; G1 → **C**.

**D1 rankiniai žingsniai (https://rokgis.github.io/musicreal/):**
1. Atidaryti puslapį, palaukti, kol pasirodys „Sign In“.
2. Paspausti „Continue with Google“ (demo režime paskyros nereikia — atidaromas srautas).
3. Paspausti „+ Post“ (apačioje dešinėje) → atsidaro „New post“.
4. Sąraše „1. Choose a song“ pasirinkti „Morning Light“ (pažymima varnele, apačioje rodoma „Morning Light“).
5. Suskaičiuoti jaustukus skiltyje „2. How do you feel?“.
Tikėtasi: 5. Faktiškai (pastebėta 2026-10-03): 3.
Ekrano kopija: visas „New post“ ekranas, kad matytųsi pasirinkta daina ir visa „2. How do you feel?“ eilutė.
Nespauskite „Continue with Facebook“ — demo jis neapeina autentifikacijos.

Papildomai naudinga: VS Code ekrano kopijos `post_widget.dart:18-23` ir `facebook_auth.dart:53-61`.

## 10. Naudotos komandos (Git Bash, repozitorijos šakniniame aplanke)

```bash
export PATH="/c/Users/pedse/sdk/flutter/bin:$PATH"
flutter --version
flutter pub get
flutter analyze test/mantas
flutter test test/mantas/ -r expanded
flutter test test/mantas/ -r expanded
flutter test test/mantas/post_emotion_test.dart --plain-name "TC-FEAT62-03 (BVA: 5)"
flutter test test/mantas/post_emotion_test.dart --plain-name "supporting unit test"
flutter test test/mantas/post_emotion_test.dart --plain-name "TC-US65-01"
flutter test test/mantas/post_emotion_test.dart --plain-name "EBT-POST-07"
flutter test test/mantas/authentication_test.dart --plain-name "TC-FEAT30-02"
flutter test test/mantas/authentication_test.dart --plain-name "TC-US33-04 (DT: cancel branch)"
flutter test test/mantas/authentication_test.dart --plain-name "AC6-GOOGLE-CANCEL"
flutter test test/mantas/authentication_test.dart --plain-name "EBT-AUTH-02"
flutter test test/mantas/authentication_test.dart --plain-name "EBT-AUTH-03"
flutter test
```

`export PATH=…` nurodo Flutter SDK vietą Manto kompiuteryje (`C:\Users\pedse\sdk\flutter`); kitame kompiuteryje naudokite savo SDK kelią. PowerShell: vietoje `flutter` naudoti `<SDK>\bin\flutter.bat`.

## 11. Audito pataisymai (lyginant su ankstesne versija: 38 / 28 / 10)

| Pakeitimas | Priežastis |
|---|---|
| Pašalintas `TC-FEAT30-06 (uid)` UI testas; TC-FEAT30-06 perrašytas (vardas + el. paštas matomi, savas profilis, uid profilio įraše) | Per griežtas: AC nereikalauja matomo uid (G2). Ankstesnis D5 atšauktas |
| Google atšaukimo testas perkeltas iš EBT į reikalavimų testus (`AC6-GOOGLE-CANCEL`) | AC6 aiškiai reikalauja pranešimo atšaukus |
| Pašalinti pranešimų teksto tikrinimai (TC-FEAT62-01, TC-US65-03, EBT-POST-01/02); „Error“ teksto tikrinimas pakeistas „rodomas pranešimas“ | Jira tekstų neapibrėžia (G5) |
| Pašalintas nonce tikrinimas (TC-US33-02) | Ne Jira reikalavimas |
| TC-FEAT30-04: pašalinti „dokumentas nepakitęs“ ir „vienas `set`“ tikrinimai; tikrinama, kad tai tas pats profilis su išlikusiais duomenimis | Per griežta, AC4 reikalauja tik „naujas nesukuriamas“ |
| TC-US65-04: pašalintas tikslus dokumento formos palyginimas | Per griežta, AC65-4 reikalauja tik jaustuko kartu su daina |
| EBT-POST-06 papildytas jaustuko keitimu | Užduoties EBT reikalavimas „changing song/emotion“ |
| EBT-POST-07 perklasifikuotas į reikalavimo spragą | Nėra AC |
| Pridėtas EBT-AUTH-07 (nėra el. pašto) | Trūkstami neprivalomi teikėjo duomenys |

## 12. Jira rezultatai, kuriuos Mantas įveda rankiniu būdu

Jira nekeista. Žemiau — galutiniai rezultatai kopijavimui į TC subtask'us (šaltinis: `flutter test test/mantas/ -r expanded`, 2 paleidimai, identiški).

| Jira TC | Rezultatas | Trumpas rezultatas |
|---|---|---|
| TC-FEAT62-01 | PASS | Be jaustuko įkėlimas blokuojamas, įrašas nesukuriamas, naudotojas lieka „New post“ lange |
| TC-FEAT62-02 | PASS | Su 1 jaustuku įkėlimas užbaigiamas, sukuriamas 1 įrašas |
| TC-FEAT62-03 | **FAIL** | Tikėtasi 5 jaustukų, rodomi 3 |
| TC-FEAT62-04 | PASS | Pasirinkus B, A atžymimas; lieka pasirinktas tik B |
| TC-FEAT62-05 | PASS | Jaustukas išsaugotas su daina ir rodomas prie dainos Statistikos suvestinėje |
| TC-US65-01 | **FAIL** | Po dainos pasirinkimo pateikiami 3 jaustukai vietoje 5 |
| TC-US65-02 | PASS | Vienu metu pasirinktas tik vienas jaustukas |
| TC-US65-03 | PASS | Be jaustuko įkėlimo užbaigti negalima |
| TC-US65-04 | PASS | Jaustukas išsaugotas tame pačiame įraše kartu su daina |
| TC-US65-05 | PASS | Draugo sraute prie dainos rodomas jaustukas |
| TC-FEAT30-01 | PASS | Firebase atmetus Google kredencialą naudotojas neprijungiamas, rodomas klaidos pranešimas |
| TC-FEAT30-02 | **FAIL** | Atšaukus Facebook prisijungimą programa meta null klaidą, pranešimas nerodomas |
| TC-FEAT30-03 | PASS | Pirmą kartą prisijungus sukuriamas 1 profilis su uid, el. paštu ir vardu |
| TC-FEAT30-04 | PASS | Pakartotinai prisijungus naujas profilis nesukuriamas, naudojamas esamas |
| TC-FEAT30-05 | PASS | Be vardo sukuriamas profilis su uid ir el. paštu, vardas tuščias, klaidos nėra |
| TC-FEAT30-06 | PASS | Prisijungęs naudotojas mato savo vardą ir el. paštą; uid saugomas profilio įraše (matomas uid AC nereikalaujamas — žr. G2) |
| TC-US33-01 | PASS | Registracija per Google sukuria paskyrą ir prijungia naudotoją |
| TC-US33-02 | PASS | Registracija per Facebook sukuria paskyrą ir prijungia naudotoją (testuota su fake SDK) |
| TC-US33-03 | PASS | Nepavykus Google autentifikacijai rodomas klaidos pranešimas, paskyra nesukuriama |
| TC-US33-04 | **FAIL** | Atšaukus Facebook registraciją programa meta null klaidą, pranešimas nerodomas |
| TC-US33-05 | PASS | Po registracijos naudotojas prijungiamas automatiškai, be atskiro login žingsnio |
| TC-US33-06 | PASS | Vardas ir el. paštas užpildomi iš Google, papildomos formos nėra |

Iš viso: 22 TC — 18 PASS, 4 FAIL.

Komentarai FAIL subtask'ams (kopijuoti tiesiai):

- **TC-FEAT62-03** — FAIL. Automatinis testas `TC-FEAT62-03 (BVA: 5)`: tikėtasi 5 jaustukų, rodomi 3 (`Expected: <5> Actual: <3>`). Priežastis: `lib/pages/post/post_widget.dart:18-23` sąraše `kEmotions` yra tik 3 elementai; pažeidžiamas SCRUM-62 AC2.
- **TC-US65-01** — FAIL. Pasirinkus dainą pateikiami 3 jaustukai vietoje 5 (`Expected: <5> Actual: <3>`). Ta pati priežastis kaip TC-FEAT62-03 (`kEmotions` 3 elementai); pažeidžiamas AC65-1.
- **TC-FEAT30-02** — FAIL. Atšaukus Meta/Facebook prisijungimą `facebook_auth.dart:61` meta „Null check operator used on a null value“, nes atšaukus SDK grąžina `accessToken = null`; klaidos pranešimas nerodomas (naudotojas neprijungiamas). Pažeidžiamas SCRUM-30 AC6; liečia Android/iOS kelią, testuota su SDK test double, web demo neatkuriama.
- **TC-US33-04** — FAIL. Atšaukus registraciją per Facebook ta pati null klaida (`facebook_auth.dart:61`), pranešimas nerodomas; paskyra nesukuriama. Pažeidžiamas SCRUM-33 AC6; Android/iOS kelias, testuota su SDK test double.

## 13. Kas dar nepadaryta?

MANTO DALIS:
- [x] Task 4 testavimo metodas pasirinktas (automatizuotas widget/unit + EBT)
- [x] Kiekvienas Jira TC įvykdytas (22/22)
- [x] PASS/FAIL užfiksuota (šiame dokumente, 3 ir 12 sk.)
- [x] AC padengimas = 100 % (21/21)
- [x] Klaidomis grįstas testavimas atliktas (12 EBT + Jira TC klaidų atvejai)
- [x] Defektai aprašyti (4 defektų grupės D1–D4; spragos G1–G6)
- [ ] Ekrano kopijos surinktos — žr. 14 sk.
- [ ] Manto asmeninė D1 demo ekrano kopija — žr. 14 sk.
- [ ] PASS/FAIL įrašyti Jira TC subtask'uose — 12 sk. lentelė (Jira automatiškai nekeista)

D2–D4 ir G1 demo neatkuriami (kategorijos C/D, 9 sk.) — tai dokumentuota ir papildomo rankinio patikrinimo nereikalauja.

## 14. Įrodymai, kuriuos Mantas turi surinkti

Nė viena žemiau nurodyta ekrano kopija dar nėra padaryta. Komandos vykdomos Git Bash repozitorijos šakniniame aplanke, kai Flutter 3.44.9 yra `PATH` (Manto kompiuteryje: `export PATH="/c/Users/pedse/sdk/flutter/bin:$PATH"`). Atskiras gidas: `MANTO_SCREENSHOTS.md` repozitorijos šaknyje.

- [ ] Screenshot — `flutter --version` (Flutter 3.44.9, Dart 3.12.2)
- [ ] Screenshot — `flutter test test/mantas/ -r expanded`, paskutinė eilutė `+29 -9: Some tests failed` (38 testai: 29 PASS, 9 FAIL)
- [ ] Screenshot — D1: `flutter test test/mantas/post_emotion_test.dart --plain-name "TC-FEAT62-03 (BVA: 5)"` → `Expected: <5>` / `Actual: <3>`
- [ ] Screenshot — D1: `flutter test test/mantas/post_emotion_test.dart --plain-name "TC-US65-01"` → `Expected: <5>` / `Actual: <3>`
- [ ] Screenshot — D2 (vienas reprezentatyvus Facebook atšaukimas): `flutter test test/mantas/authentication_test.dart --plain-name "TC-FEAT30-02"` → `Null check operator used on a null value` … `facebook_auth.dart:61:26` ir `Found 0 widgets with type "SnackBar"`
- [ ] Screenshot — D3: `flutter test test/mantas/authentication_test.dart --plain-name "AC6-GOOGLE-CANCEL"` → `Found 0 widgets with type "SnackBar"`
- [ ] Screenshot — D4: `flutter test test/mantas/authentication_test.dart --plain-name "EBT-AUTH-02"` → `PlatformException(network_error, …)` ir `Found 0 widgets with type "SnackBar"`
- [ ] Screenshot — G1: `flutter test test/mantas/post_emotion_test.dart --plain-name "EBT-POST-07"` → `Exception: permission-denied` … `post_widget.dart:113`; ekrane turi matytis testo pavadinimas su „REQUIREMENT GAP“ (ataskaitoje žymėti kaip reikalavimo spragą, ne AC defektą)
- [ ] Screenshot — MusicReal demo „New post“ ekranas su tik 3 jaustukais

Demo ekrano kopijos žingsniai:
1. Atidaryti https://rokgis.github.io/musicreal/ ir palaukti, kol pasirodys „Sign In“.
2. Įeiti į programą įprastu demo būdu — paspausti „Continue with Google“ (demo build'e paskyros nereikia, atidaromas srautas). Nespausti „Continue with Facebook“.
3. Paspausti „+ Post“ (apačioje dešinėje) — atsidaro „New post“.
4. Skiltyje „1. Choose a song“ pasirinkti dainą, pvz. „Morning Light“.
5. Užfiksuoti visą jaustukų pasirinkimo sritį „2. How do you feel?“ (geriausia visą „New post“ ekraną su pasirinkta daina).
6. Ekrano kopijoje turi aiškiai matytis 3 jaustukų pasirinkimai.

Tikėtasi pagal Jira (SCRUM-62 AC2, SCRUM-65 AC65-1): 5. Faktiškai: 3.
