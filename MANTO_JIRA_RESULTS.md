# Manto Jira TC rezultatai — kopijavimui į Jira

Šaltinis: `flutter test test/mantas/ -r expanded` (Flutter 3.44.9), commit `36f620a`, du identiški paleidimai.
Iš viso 22 TC: **18 PASS, 4 FAIL**.

| Jira TC | Reikalavimas | Rezultatas | Trumpas rezultatas | Komentaras reikalingas |
|---|---|---|---|---|
| TC-FEAT62-01 | SCRUM-62 | PASS | Be jaustuko įkėlimas blokuojamas, įrašas nesukuriamas | Ne |
| TC-FEAT62-02 | SCRUM-62 | PASS | Su 1 jaustuku įkėlimas užbaigiamas, sukuriamas 1 įrašas | Ne |
| TC-FEAT62-03 | SCRUM-62 | **FAIL** | Tikėtasi 5 jaustukų, rodomi 3 | **Taip** |
| TC-FEAT62-04 | SCRUM-62 | PASS | Pasirinkus B, A atžymimas; lieka tik B | Ne |
| TC-FEAT62-05 | SCRUM-62 | PASS | Jaustukas išsaugotas su daina ir rodomas Statistikos suvestinėje | Ne |
| TC-US65-01 | SCRUM-65 | **FAIL** | Po dainos pasirinkimo pateikiami 3 jaustukai vietoje 5 | **Taip** |
| TC-US65-02 | SCRUM-65 | PASS | Vienu metu pasirinktas tik vienas jaustukas | Ne |
| TC-US65-03 | SCRUM-65 | PASS | Be jaustuko įkėlimo užbaigti negalima | Ne |
| TC-US65-04 | SCRUM-65 | PASS | Jaustukas išsaugotas tame pačiame įraše su daina | Ne |
| TC-US65-05 | SCRUM-65 | PASS | Draugo sraute prie dainos rodomas jaustukas | Ne |
| TC-FEAT30-01 | SCRUM-30 | PASS | Atmetus Google kredencialą naudotojas neprijungiamas, rodomas klaidos pranešimas | Ne |
| TC-FEAT30-02 | SCRUM-30 | **FAIL** | Atšaukus Facebook prisijungimą — null klaida, pranešimas nerodomas | **Taip** |
| TC-FEAT30-03 | SCRUM-30 | PASS | Pirmą kartą prisijungus sukuriamas 1 profilis su uid, el. paštu, vardu | Ne |
| TC-FEAT30-04 | SCRUM-30 | PASS | Pakartotinai prisijungus naudojamas esamas profilis, naujas nesukuriamas | Ne |
| TC-FEAT30-05 | SCRUM-30 | PASS | Be vardo sukuriamas profilis su uid ir el. paštu, klaidos nėra | Ne |
| TC-FEAT30-06 | SCRUM-30 | PASS | Matomi savo vardas ir el. paštas; uid saugomas profilio įraše | Neprivalomas (galima paminėti: matomas uid AC nereikalaujamas) |
| TC-US33-01 | SCRUM-33 | PASS | Registracija per Google sukuria paskyrą ir prijungia | Ne |
| TC-US33-02 | SCRUM-33 | PASS | Registracija per Facebook sukuria paskyrą ir prijungia (testuota su SDK test double) | Ne |
| TC-US33-03 | SCRUM-33 | PASS | Nepavykus Google autentifikacijai rodomas pranešimas, paskyra nesukuriama | Ne |
| TC-US33-04 | SCRUM-33 | **FAIL** | Atšaukus Facebook registraciją — null klaida, pranešimas nerodomas | **Taip** |
| TC-US33-05 | SCRUM-33 | PASS | Po registracijos naudotojas prijungiamas automatiškai | Ne |
| TC-US33-06 | SCRUM-33 | PASS | Vardas ir el. paštas užpildomi iš Google, papildomos formos nėra | Ne |

## FAIL komentarai kopijavimui į Jira

### TC-FEAT62-03

Testo rezultatas: FAIL

Tikėtasi:
Pasirinkus dainą rodomas lygiai 5 jaustukų sąrašas.

Gauta:
Rodomi 3 jaustukai. Automatinis testas „TC-FEAT62-03 (BVA: 5)“: Expected: <5>, Actual: <3>.

Susijęs reikalavimas / AC:
SCRUM-62 AC2 — „Jaustuko pasirinkimo metu naudotojui yra rodomas sąrašas iš 5 galimų pasirinkti jaustukų“.

Defektas:
D1 — lib/pages/post/post_widget.dart:18-23 sąraše kEmotions apibrėžti tik 3 jaustukai.

### TC-US65-01

Testo rezultatas: FAIL

Tikėtasi:
Pasirinkus dainą naudotojui pateikiami 5 galimi jaustukai.

Gauta:
Pateikiami 3 jaustukai. Automatinis testas „TC-US65-01 (AC65-1)“: Expected: <5>, Actual: <3>.

Susijęs reikalavimas / AC:
SCRUM-65 AC65-1.

Defektas:
D1 — ta pati priežastis kaip TC-FEAT62-03 (kEmotions turi 3 elementus).

### TC-FEAT30-02

Testo rezultatas: FAIL

Tikėtasi:
Atšaukus Meta/Facebook prisijungimą naudotojas neprijungiamas, lieka prisijungimo ekrane ir mato klaidos pranešimą.

Gauta:
Naudotojas neprijungiamas, bet pranešimas nerodomas: programa meta „Null check operator used on a null value“ (facebook_auth.dart:61), nes atšaukus Facebook SDK grąžina accessToken = null.

Susijęs reikalavimas / AC:
SCRUM-30 AC6 — „nepavykus arba atšaukus autentifikaciją naudotojas neprijungiamas ir pateikiamas klaidos pranešimas“.

Defektas:
D2 — Android/iOS kelias; testuota su Facebook SDK test double, web demo neatkuriama.

### TC-US33-04

Testo rezultatas: FAIL

Tikėtasi:
Atšaukus registraciją per Facebook grįžtama į registracijos ekraną, rodomas klaidos / informacinis pranešimas, paskyra nesukuriama.

Gauta:
Paskyra nesukuriama, bet pranešimas nerodomas: ta pati null klaida facebook_auth.dart:61.

Susijęs reikalavimas / AC:
SCRUM-33 AC6 — „Jei autentifikacija nepavyksta arba naudotojas atšaukia veiksmą, pateikiamas klaidos pranešimas“.

Defektas:
D2 — Android/iOS kelias; testuota su Facebook SDK test double, web demo neatkuriama.
