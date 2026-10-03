# Manto ekrano kopijos — ką nufotografuoti

Visos komandos vykdomos **Git Bash** repozitorijos šakniniame aplanke (kur yra `pubspec.yaml`).
Flutter 3.44.9 turi būti `PATH`. Manto kompiuteryje SDK įdiegtas `C:\Users\pedse\sdk\flutter`, todėl kiekvienam naujam terminalui:

```bash
export PATH="/c/Users/pedse/sdk/flutter/bin:$PATH"
```

Kitame kompiuteryje šį kelią pakeiskite savo Flutter SDK `bin` aplanku.

Ekrano kopijoje visada turi matytis ir pati komanda, ir rezultatas.

## A. Aplinka

```bash
flutter --version
```

Turi matytis: `Flutter 3.44.9` ir `Dart 3.12.2`.

## B. Visas Manto rinkinys

```bash
flutter test test/mantas/ -r expanded
```

Turi matytis paskutinė eilutė: `+29 -9: Some tests failed.`
(38 testai: 29 PASS, 9 FAIL, 0 BLOCKED.) Jei netelpa, nufotografuokite pabaigą su „Failing tests:“ sąrašu.

## C. Atskiri FAIL

### TC-FEAT62-03 (D1)
```bash
flutter test test/mantas/post_emotion_test.dart --plain-name "TC-FEAT62-03 (BVA: 5)"
```
Laukiamas įrodymas: `Expected: <5>` ir `Actual: <3>`.
Klasifikacija: patvirtintas reikalavimo defektas.

### TC-US65-01 (D1)
```bash
flutter test test/mantas/post_emotion_test.dart --plain-name "TC-US65-01"
```
Laukiamas įrodymas: `Expected: <5>` ir `Actual: <3>`.
Klasifikacija: patvirtintas reikalavimo defektas.

### TC-FEAT30-02 (D2)
```bash
flutter test test/mantas/authentication_test.dart --plain-name "TC-FEAT30-02"
```
Laukiamas įrodymas: `Null check operator used on a null value`, eilutė `facebook_auth.dart:61:26` ir `Found 0 widgets with type "SnackBar"`.
Klasifikacija: patvirtintas reikalavimo defektas.

### TC-US33-04 (D2)
```bash
flutter test test/mantas/authentication_test.dart --plain-name "TC-US33-04 (DT: cancel branch)"
```
Laukiamas įrodymas: `Null check operator used on a null value`, `facebook_auth.dart:61:26`, `Found 0 widgets with type "SnackBar"`.
Klasifikacija: patvirtintas reikalavimo defektas.

### AC6-GOOGLE-CANCEL (D3)
```bash
flutter test test/mantas/authentication_test.dart --plain-name "AC6-GOOGLE-CANCEL"
```
Laukiamas įrodymas: `Found 0 widgets with type "SnackBar"` (atšaukus Google pranešimas nerodomas).
Klasifikacija: patvirtintas reikalavimo defektas (SCRUM-30 AC6 / SCRUM-33 AC6; Jira TC šiam atvejui nėra).

### EBT-AUTH-02 (D4)
```bash
flutter test test/mantas/authentication_test.dart --plain-name "EBT-AUTH-02"
```
Laukiamas įrodymas: `PlatformException(network_error, A network error occurred., null, null)` ir `Found 0 widgets with type "SnackBar"`.
Klasifikacija: patvirtintas reikalavimo defektas (SCRUM-30 AC6), rastas klaidomis grįstu testu.

### EBT-POST-07 (G1)
```bash
flutter test test/mantas/post_emotion_test.dart --plain-name "EBT-POST-07"
```
Laukiamas įrodymas: testo pavadinime matosi `REQUIREMENT GAP`, `Exception: permission-denied`, `post_widget.dart:113:5`.
Klasifikacija: reikalavimo / testuojamumo spraga (**ne** AC defektas).

## D. Demo — D1 (3 jaustukai)

URL: https://rokgis.github.io/musicreal/

1. Atidaryti demo ir palaukti, kol pasirodys „Sign In“.
2. Paspausti „Continue with Google“ (demo build'e paskyros nereikia — iš karto atidaromas srautas).
3. Paspausti „+ Post“ (apačioje dešinėje).
4. Skiltyje „1. Choose a song“ pasirinkti „Morning Light“.
5. Nufotografuoti visą skiltį „2. How do you feel?“ (geriausia visą „New post“ ekraną su pasirinkta daina).

Tikėtasi pagal Jira: 5 jaustukai.
Faktiškai: 3 jaustukai.
Ekrano kopijoje turi aiškiai matytis visi 3 pasirinkimai.

**Nespauskite „Continue with Facebook“** — demo jis neapeina autentifikacijos ir paleidžia tikrą Facebook prisijungimą; įrodymams jo nereikia.
