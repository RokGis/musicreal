# 1 LD: Reikalavimų kokybė ir reikalavimais grįstas testavimas

Dokumentas paruoštas pagal užduoties `1ld_kokybeVU-2026_1.docx` struktūrą.
Projektas: **SCRUM „Projektų valdymas“** (mif-projektu-valdymas.atlassian.net).

| Studentas | Funkcionalumas | Reikalavimai (vartotojo / sistemos / nefunkcinis) |
| --- | --- | --- |
| | Prisijungimas ir paskyros ištrynimas | SCRUM-47 / SCRUM-30 / SCRUM-42 |
| | Dainos ir emocijos įkėlimas | SCRUM-65 / SCRUM-61 / SCRUM-63 |
| | Draugų ratas ir srautas | SCRUM-51 / SCRUM-49 / SCRUM-50 |
| | Statistika ir „streak“ | SCRUM-39 / SCRUM-48 / SCRUM-44 |

> Vardus įrašykite patys. Į Jira nieko nekeičiu — žemiau esantys tekstai skirti
> nusikopijuoti į Jira aprašymus ir komentarus.

---

## 1. Reikalavimų kokybės kriterijai

Keturi bendrieji kriterijai ir du dalykinės srities kriterijai. Pagrindimas
reikalingas gynimui.

| Nr. | Kriterijus | Ką tikrina | Kodėl pasirinktas šiai PS |
| --- | --- | --- | --- |
| K1 | Vienareikšmiškumas | Formuluotė turi tik vieną interpretaciją; nėra „patogiai“, „greitai“, „tinkamai“ | Komandos backlog'e daug vertinamųjų žodžių, todėl skirtingi nariai reikalavimą suprastų skirtingai |
| K2 | Patikrinamumas | Galima sugalvoti testą, kuris duotų „taip / ne“; skaičiai turi matavimo būdą | Nefunkciniuose reikalavimuose yra „2 sekundės“, „97-98 %“ be matavimo sąlygų |
| K3 | Išbaigtumas | Yra priėmimo kriterijai, pradiniai duomenys, klaidų atvejai | Dauguma backlog įrašų neturi aprašymo — testuoti nėra pagal ką |
| K4 | Atsekamumas | Susietas su epic'u, turi unikalų ID, matoma realizacija | Reikia parodyti padengiamumą nuo epic'o iki testinio atvejo |
| D1 | Atitiktis BDAR (dalykinė sritis) | Asmens duomenų prieiga, saugojimas ir visiškas pašalinimas | Sistema saugo emocijas — jautrius duomenis; SCRUM-32, SCRUM-44 |
| D2 | Atitiktis verslo tikslui (dalykinė sritis) | Reikalavimas prisideda prie kasdienio įsitraukimo (OKR/KPI iš SCRUM-7) | Produkto vertė — kasdienis grįžimas („streak“), todėl reikalavimai turi jį palaikyti |

## 2. Patikrinimo sąrašas (CheckList)

Naudojamas inspektuojant kiekvieną iš 3 reikalavimų. Atsakymas „Ne“ = radinys,
kurį reikia užrašyti Jira komentare.

| Nr. | Klausimas | Kriterijus |
| --- | --- | --- |
| C1 | Ar reikalavime nėra vertinamųjų žodžių („greitai“, „patogu“, „tinkamai“)? | K1 |
| C2 | Ar aiškus veikėjas ir jo veiksmas (kas ir ką daro)? | K1 |
| C3 | Ar galima parašyti testą, kuris duotų vienareikšmį rezultatą? | K2 |
| C4 | Ar skaitiniai dydžiai turi matavimo būdą ir sąlygas (tinklas, įrenginys, duomenų kiekis)? | K2 |
| C5 | Ar yra priėmimo kriterijai? | K3 |
| C6 | Ar aprašytas bent vienas klaidos / neigiamas atvejis? | K3 |
| C7 | Ar nurodyti pradiniai duomenys ir būsena? | K3 |
| C8 | Ar reikalavimas susietas su epic'u ir turi ID? | K4 |
| C9 | Ar matomas ryšys su realizacija (komponentas, ekranas)? | K4 |
| C10 | Ar aprašyta, kieno duomenys prieinami ir kam jie nepasiekiami? | D1 |
| C11 | Ar numatyta, kas nutinka duomenims ištrynus paskyrą? | D1 |
| C12 | Ar matomas ryšys su verslo rodikliu (OKR/KPI iš SCRUM-7)? | D2 |

### Inspektavimo radiniai (bendri visam backlog'ui)

Radiniai, kuriuos galima demonstruoti gynime:

- **C5 „Ne“ daugumai įrašų.** Iš 97 Jira įrašų didžioji dalis neturi aprašymo ir
  priėmimo kriterijų (pvz., SCRUM-44, SCRUM-48, SCRUM-51, SCRUM-54).
- **C4 „Ne“ (SCRUM-55, SCRUM-50).** „Ne ilgiau kaip 2 sekundės“ nenurodo, kur
  matuojama (klientas ar serveris), su kokiu tinklu ir kiek duomenų.
- **C4 „Ne“ (SCRUM-57, SCRUM-54).** „97-98 %“ ir „99 %“ neturi matavimo lango ir
  skaitiklio — tokio reikalavimo neįmanoma patikrinti per gynimą.
- **C6 „Ne“ beveik visiems.** Neaprašytas nė vienas klaidos atvejis (pvz., ką
  daryti, kai įkėlimas nepavyksta).
- **C1 „Ne“ (SCRUM-65).** „Kad būtų patogu išreikšti emociją“ — „patogu“
  nepamatuojama.

---

## 3. Reikalavimai, priėmimo kriterijai ir testiniai atvejai

Kiekvienam studentui: 3 reikalavimai, iš kurių 2 detalizuoti iki DoR ir padengti
testiniais atvejais 100 %.

Taikytos TA sudarymo technikos (reikės pagrįsti gynime):
**EK** — ekvivalenčių klasių skaidymas, **RR** — ribinių reikšmių analizė,
**BP** — būsenų perėjimų testavimas, **SL** — sprendimų lentelė,
**KS** — klaidų spėjimas (error guessing).

---

### Studentas 1 — Prisijungimas ir paskyros ištrynimas

**Vartotojo reikalavimas (DoR): SCRUM-47** — Kaip naudotojas, noriu ištrinti savo
profilį taip, kad visi mano duomenys būtų pašalinti iš sistemos.

Priėmimo kriterijai:
- PK1.1 Profilio lange yra „Remove Account“ veiksmas.
- PK1.2 Ištrynus pašalinamas `users/{uid}` įrašas ir jo `userPost` subkolekcija.
- PK1.3 Pašalinamos visos `friend_requests`, kuriose naudotojas yra siuntėjas arba gavėjas.
- PK1.4 Naudotojas pašalinamas iš kitų naudotojų `friends` masyvų.
- PK1.5 Jei nuo paskutinio prisijungimo praėjo per daug laiko, ištrynimas neįvyksta ir rodomas pranešimas.
- PK1.6 Po ištrynimo sesija nutraukiama ir grąžinama į prisijungimo langą.

**Sistemos reikalavimas (DoR): SCRUM-30** — Registracija ir prisijungimas tik per
išorines platformas.

Priėmimo kriterijai:
- PK1.7 Prisijungimo lange nėra el. pašto / slaptažodžio laukų.
- PK1.8 Pirmo prisijungimo metu automatiškai sukuriamas `users` įrašas su `email`, `display_name`, `uid`, `created_time`.
- PK1.9 Antras prisijungimas ta pačia paskyra naujo įrašo nesukuria.

**Nefunkcinis reikalavimas: SCRUM-42** — OAuth 2.0 ir BDAR atitiktis.
*Inspektavimo radinys:* neturi priėmimo kriterijų (C5 „Ne“) ir nepatikrinamas
esama formuluote (C3 „Ne“) — rekomenduojama perrašyti į „naudojami tik tiekėjo
OAuth 2.0 srautai; programėlė nesaugo slaptažodžių“.

| TA ID | Padengia | Technika | Pradinė būsena | Veiksmai | Laukiamas rezultatas |
| --- | --- | --- | --- | --- | --- |
| TA1.1 | PK1.7, PK1.8 | EK | Neprisijungta, nauja Google paskyra | Atidaryti programėlę → „Continue with Google“ → pasirinkti paskyrą | Patenkama į Home; Firestore atsiranda `users/{uid}` su 4 laukais |
| TA1.2 | PK1.9 | EK | Paskyra jau egzistuoja | Atsijungti → prisijungti ta pačia paskyra | Įrašų skaičius `users` nepakito; rodomas tas pats profilis |
| TA1.3 | PK1.7 | KS | Prisijungimo langas | Peržiūrėti visus laukus ir mygtukus | Yra tik Google ir Facebook; el. pašto lauko nėra |
| TA1.4 | PK1.5 | RR | Prisijungta seniai (>5 min. nuo autentifikacijos) | Profilis → „Remove Account“ | Pranešimas „Too long since most recent sign in…“; paskyra **neištrinta**; likti profilyje |
| TA1.5 | PK1.1–PK1.4, PK1.6 | SL | Ką tik prisijungta; naudotojas turi 1 draugą, 1 įrašą, 1 užklausą | Profilis → „Remove Account“ | Grįžtama į prisijungimo langą; Firestore dingsta naudotojo įrašas, `userPost`, `friend_requests`; draugo `friends` masyve jo nebėra |
| TA1.6 | PK1.2 | KS | Paskyra ištrinta | Prisijungti ta pačia Google paskyra | Sukuriamas naujas tuščias profilis, `streak_count` = 0 |

---

### Studentas 2 — Dainos ir emocijos įkėlimas

**Vartotojo reikalavimas (DoR): SCRUM-65** — Kaip naudotojas, noriu prie dainos
pridėti emociją jaustuku.

Priėmimo kriterijai:
- PK2.1 Įkėlimo lange emociją galima pasirinkti mygtuku arba įvesti ranka.
- PK2.2 Pasirinkta emocija išsaugoma įrašo lauke `emoji`.
- PK2.3 Emocija matoma įraše sraute.

**Sistemos reikalavimas (DoR): SCRUM-61** — Sistema leidžia pasirinkti dainą iš
katalogo ir įkelti ją į dienos srautą.

Priėmimo kriterijai:
- PK2.4 Paieška pagal pavadinimo dalį grąžina tik atitinkančius kūrinius.
- PK2.5 Be pasirinktos dainos įrašas nesukuriamas.
- PK2.6 Sukurtame įraše saugomi `song_name`, `emoji`, `post_user`, `created_at`.
- PK2.7 Naudotojas negali rašyti į svetimą įrašų kolekciją.

**Nefunkcinis reikalavimas: SCRUM-63** — Įkelta daina užregistruojama ne ilgiau
nei per 5 sekundes.
*Inspektavimo radinys:* nenurodyta matavimo pradžia ir pabaiga (C4 „Ne“).
Siūloma: „nuo „Post“ paspaudimo iki įrašo atsiradimo Firestore, 4G ryšiu“.

| TA ID | Padengia | Technika | Pradinė būsena | Veiksmai | Laukiamas rezultatas |
| --- | --- | --- | --- | --- | --- |
| TA2.1 | PK2.4 | EK | Kataloge ≥3 dainos | Paieškoje įvesti egzistuojančio pavadinimo dalį | Rodomi tik atitinkantys kūriniai |
| TA2.2 | PK2.4 | KS | Tas pats | Įvesti neegzistuojantį pavadinimą | Tuščias sąrašas, programėlė nelūžta |
| TA2.3 | PK2.1–PK2.3, PK2.6 | EK | Prisijungta | Pasirinkti dainą → pasirinkti jaustuką → „Post“ | Grįžtama į Home; Firestore įraše yra visi 4 laukai; emocija matoma sraute |
| TA2.4 | PK2.5 | RR | Daina nepasirinkta | Spausti „Post“ | Pranešimas „Pick a song before posting.“; įrašas nesukuriamas |
| TA2.5 | PK2.1 | RR | Daina pasirinkta | Nepasirinkti emocijos → „Post“ | Pranešimas „Pick an emotion before posting.“; įrašas nesukuriamas |
| TA2.6 | PK2.7 | KS | Rules playground | Bandyti rašyti į `users/{kitas_uid}/userPost` | Rašymas draudžiamas |
| TA2.7 | SCRUM-63 | RR | Prisijungta | Matuoti laiką nuo „Post“ iki įrašo Firestore | ≤ 5 s (užfiksuoti tikslų laiką) |

---

### Studentas 3 — Draugų ratas ir srautas

**Vartotojo reikalavimas (DoR): SCRUM-51 / SCRUM-52** — Pridėti ir pašalinti
draugą.

Priėmimo kriterijai:
- PK3.1 Paieškoje randamas kitas naudotojas pagal vardą.
- PK3.2 „Add Friend“ sukuria užklausą su `status: pending`.
- PK3.3 Gavėjas mato užklausą su siuntėjo vardu.
- PK3.4 „Accept“ įrašo abu naudotojus į vienas kito `friends` masyvus.
- PK3.5 „Decline“ užklausą ištrina, draugystė nesukuriama.
- PK3.6 Pašalinus draugą, jis dingsta iš abiejų `friends` masyvų.

**Sistemos reikalavimas (DoR): SCRUM-49** — Srauto turinys pateikiamas pagal
draugų sąrašą.

Priėmimo kriterijai:
- PK3.7 Sraute rodomi tik draugų įrašai, naujausi viršuje.
- PK3.8 Naudotojas be draugų mato tuščią srautą be klaidos.
- PK3.9 Pašalinus draugą, jo įrašai dingsta iš srauto.
- PK3.10 Svetimų užklausų peržiūra ir keitimas draudžiami.

**Nefunkcinis reikalavimas: SCRUM-50** — Srauto ir draugų sąrašo užkrovimas ne
ilgiau kaip 2 sekundės.
*Inspektavimo radinys:* nenurodytas draugų ir įrašų kiekis, prie kurio matuojama
(C4 „Ne“). Siūloma: „su 30 draugų ir 100 įrašų“.

| TA ID | Padengia | Technika | Pradinė būsena | Veiksmai | Laukiamas rezultatas |
| --- | --- | --- | --- | --- | --- |
| TA3.1 | PK3.1, PK3.2 | EK | Paskyros A ir B | A ieško B → „Add Friend“ | Pranešimas „Friend Request Sent“; `friend_requests` įrašas `pending` |
| TA3.2 | PK3.3, PK3.4 | BP | Užklausa `pending` | B atidaro draugų langą → „Accept“ | `status` = `accepted`; abiejų `friends` masyvuose yra vienas kitas |
| TA3.3 | PK3.5 | BP | Užklausa `pending` | B spaudžia „Decline“ | Užklausa ištrinta; `friends` masyvai nepakito |
| TA3.4 | PK3.7 | EK | A ir B — draugai | A įkelia įrašą | B sraute matomas A įrašas, naujausias viršuje |
| TA3.5 | PK3.6, PK3.9 | BP | A ir B — draugai | B pašalina A | Abiejų `friends` tušti; A įrašai dingo iš B srauto |
| TA3.6 | PK3.8 | RR | Nauja paskyra, 0 draugų | Atidaryti Home | Tuščias srautas, programėlė nelūžta |
| TA3.7 | PK3.10 | KS | Rules playground, naudotojas C | Skaityti A→B užklausą; keisti jos `status` | Abu veiksmai draudžiami |
| TA3.8 | PK3.10 | KS | Rules playground, naudotojas C | Įrašyti svetimą naudotoją į A `friends` | Draudžiama (leidžiama tik save) |
| TA3.9 | PK3.7 | RR | Naudotojas su 31 draugu | Atidaryti Home | **Rizika:** Firestore `whereIn` riba — 30; srautas neveikia |

---

### Studentas 4 — Statistika ir „streak“

**Vartotojo reikalavimas (DoR): SCRUM-39 / SCRUM-40** — Mėnesio dainų ir emocijų
statistika bei kasdienio aktyvumo „streak“.

Priėmimo kriterijai:
- PK4.1 Profilyje matomas „streak“ skaičius.
- PK4.2 Pirmas įrašas nustato „streak“ = 1.
- PK4.3 Įrašas kitą dieną padidina „streak“ vienetu.
- PK4.4 Antras įrašas tą pačią dieną „streak“ nekeičia.
- PK4.5 Praleidus dieną „streak“ atstatomas į 0.

**Sistemos reikalavimas (DoR): SCRUM-48** — Statistikoje pateikiama paskutinių
30 dienų klausomiausių kūrinių ir jaustukų suvestinė.

Priėmimo kriterijai:
- PK4.6 Rodomas įrašų skaičius per 30 dienų.
- PK4.7 Rodomos dažniausios dainos (iki 5) su skaičiais.
- PK4.8 Rodomos dažniausios emocijos (iki 5) su skaičiais.
- PK4.9 Senesni nei 30 dienų įrašai neįtraukiami.
- PK4.10 Naudotojas be įrašų mato paaiškinimą, ne klaidą.

**Nefunkcinis reikalavimas: SCRUM-44** — BDAR: prieiga prie asmeninės statistikos
tik paskyros savininkui.

Priėmimo kriterijai:
- PK4.11 Statistikoje rodomi tik paties naudotojo įrašai, net jei jis turi draugų.
- PK4.12 Neprisijungus duomenys nerodomi.

| TA ID | Padengia | Technika | Pradinė būsena | Veiksmai | Laukiamas rezultatas |
| --- | --- | --- | --- | --- | --- |
| TA4.1 | PK4.1, PK4.2 | BP | Nauja paskyra, 0 įrašų | Įkelti pirmą įrašą → atidaryti profilį | „streak“ = 1; `last_post_date` — šiandien |
| TA4.2 | PK4.3 | BP | `last_post_date` = vakar (nustatyti konsolėje) | Įkelti įrašą | „streak“ padidėja vienetu |
| TA4.3 | PK4.4 | BP | Šiandien jau įkelta | Įkelti antrą įrašą | „streak“ nepakito |
| TA4.4 | PK4.5 | RR | `last_post_date` = prieš 3 dienas | Atidaryti Home | „streak“ = 0 |
| TA4.5 | PK4.5 | RR | `last_post_date` = užvakar (riba) | Atidaryti Home | „streak“ = 0 (riba: vakar — išlieka, užvakar — nutrūksta) |
| TA4.6 | PK4.6–PK4.8 | EK | 3 įrašai su ta pačia daina, skirtingos emocijos | Atidaryti statistiką | Daina rodoma su skaičiumi 3; emocijos pagal dažnumą |
| TA4.7 | PK4.9 | RR | Įrašas su `created_at` prieš 40 dienų | Atidaryti statistiką | Įrašas neįtrauktas |
| TA4.8 | PK4.9 | RR | Įrašas su `created_at` prieš 29 ir 31 dieną | Atidaryti statistiką | 29 d. — įtrauktas, 31 d. — ne |
| TA4.9 | PK4.10 | RR | Paskyra be įrašų | Atidaryti statistiką | „No posts in the last 30 days.“, be klaidų |
| TA4.10 | PK4.11 | KS | A ir B — draugai, B turi įrašų | A atidaro statistiką | B dainų ir emocijų nėra |
| TA4.11 | PK4.12 | KS | Atsijungta | Atidaryti `/statistics` | Duomenų nerodoma |

---

## 4. Error-based testavimas

Atvejai, sudaryti spėjant tipines klaidas (KS technika), ne iš reikalavimų.

| Nr. | Atvejis | Laukiama | Rizika, jei nepavyksta |
| --- | --- | --- | --- |
| E1 | Įkelti įrašą be interneto ryšio | Aiškus pranešimas | Naudotojas nežino, ar įrašas išsaugotas |
| E2 | Du kartus greitai spausti „Post“ | Sukuriamas vienas įrašas | Dubliuoti įrašai iškraipo statistiką |
| E3 | Siųsti draugystės užklausą tam pačiam naudotojui du kartus | Pranešimas „Friend request already sent.“; antra užklausa nesukuriama | Sąrašas užsipildytų dublikatais |
| E4 | Siųsti draugystės užklausą sau | Pranešimas „You cannot add yourself.“ | Naudotojas taptų savo paties draugu |
| E5 | Emocijos lauke įrašyti tekstą, kuris nėra paveikslėlio nuoroda | Pranešimas „Pick one of the emotions shown above.“ | Sraute vietoj emocijos būtų rodoma klaida |
| E6 | Pakeisti įrenginio laiko juostą ir įkelti įrašą | „streak“ skaičiuojamas nuosekliai | Laiko juostos keitimas leidžia dirbtinai didinti „streak“ |
| E7 | Ištrinti paskyrą, kol draugas žiūri srautą | Įrašai dingsta be klaidos | Srautas rodo neegzistuojančius duomenis |

## 5. Rizikų matrica

Tikimybė ir poveikis: Ž — žema, V — vidutinė, A — aukšta.

| ID | Rizika (kyla iš reikalavimo) | Tikimybė | Poveikis | Lygis | Siūlomas sprendimas |
| --- | --- | --- | --- | --- | --- |
| R1 | Reikalavimai be priėmimo kriterijų — negalima įrodyti, kad realizuota | A | A | **Aukštas** | Prieš sprintą reikalauti DoR: kriterijai + klaidų atvejai |
| R2 | „2 s“, „97-98 %“, „99 %“ nepamatuojami | A | V | **Aukštas** | Nurodyti matavimo tašką, apkrovą ir langą |
| R3 | Srautas veikia tik iki 30 draugų (`whereIn` riba) | V | A | **Aukštas** | Skaidyti užklausą arba saugoti srautą atskirai |
| R4 | Bet kuris prisijungęs naudotojas gali skaityti bet kieno įrašus | V | A | **Aukštas** | Perprojektuoti srauto užklausą į draugų apribojimą |
| R5 | „streak“ skaičiuojamas pagal įrenginio laiką | V | V | **Vidutinis** | Skaičiuoti serveryje (`updateStreak` funkcija) |
| R6 | Dublikatų kontrolė draugystės užklausoms — **įgyvendinta** (tikrinamos abi kryptys ir esama draugystė) | Ž | Ž | **Žemas** | Patikrinti TA E3, E4 |
| R7 | „Post“ be dainos nerodo pranešimo — **įgyvendinta** | Ž | Ž | **Žemas** | Patikrinti TA2.4 |
| R8 | Emocija neprivaloma — **įgyvendinta**: privaloma ir turi būti paveikslėlio nuoroda | Ž | V | **Žemas** | Įrašyti taisyklę į SCRUM-65 aprašymą |
| R9 | Paskyros ištrynimas priklauso nuo Cloud Function | Ž | A | **Vidutinis** | Testuoti po kiekvieno diegimo; stebėti funkcijos logus |

## 6. Testavimo vykdymas

**Rekomenduojamas įrankis:** Qase (rankinis testavimas) — TA importuojami iš šios
lentelės, kiekvienas vykdymas fiksuojamas su ekrano kopija. Selenium / Cypress
šiam projektui netinka: programėlė veikia per Firebase autentifikaciją su Google
langu, kurio automatizuoti negalima be atskirų testinių paskyrų.

**Būtina prieš vykdymą** (be šio žingsnio 3 srauto TA nepraeis):

`npx firebase-tools deploy --only firestore:rules,firestore:indexes,functions -P project-for-management-sugxvo`

**Pasiruošimas:** dvi Google paskyros (A ir B), du naršyklės profiliai, atvira
Firebase konsolė, kataloge ≥3 dainos.

**Fiksavimas:** kiekvienam TA — rezultatas (teisinga / klaidinga), ekrano kopija,
o radus klaidą — jos aprašymas (žingsniai, laukta, gauta, sunkumas).

## 7. Išvados ir rekomendacijos

1. **Specifikavimo klaidos.** Pagrindinė backlog'o problema — reikalavimai be
   priėmimo kriterijų ir be klaidų atvejų. Iš 97 įrašų aprašymą turi tik keli,
   todėl testinius atvejus teko kurti iš realizacijos, o ne iš reikalavimo. Tai
   klasikinė reikalavimų inžinerijos klaida: testas tikrina, kas padaryta, o ne
   kas buvo norėta.
2. **Nefunkciniai reikalavimai nepatikrinami.** SCRUM-50, SCRUM-55, SCRUM-57 ir
   SCRUM-54 turi skaičius be matavimo konteksto.
3. **Dalykinės srities spraga.** Sistema saugo emocijas, bet tik SCRUM-44 mini
   prieigos ribojimą; srauto reikalavimai prieigos neaptaria.
4. **Rekomendacija procesui.** Įvesti DoR kontrolinį sąrašą (2 skyrius) kaip
   privalomą sprintų planavimo žingsnį ir reikalauti bent vieno neigiamo atvejo
   kiekvienam reikalavimui.

## 8. Žinomi apribojimai (verta paminėti gynime)

- Srautas veikia tik iki 30 draugų (Firestore `whereIn` apribojimas).
- Bet kuris prisijungęs naudotojas gali skaityti bet kurio naudotojo įrašus —
  apribojimas iki draugų reikalautų kitokios srauto užklausos.
- „streak“ skaičiuojamas pagal įrenginio laiką, todėl pakeitus laiko juostą jį
  galima paveikti.
- Dublikatų tikrinimas veikia `pending` būsenos užklausoms: atmetus užklausą,
  naują išsiųsti galima (toks ir buvo sumanymas).
- Projektas nesikompiliavo su Flutter 3.44, kol nebuvo atnaujinti
  `font_awesome_flutter` ir `page_transition` paketai — tai laikytina
  konfigūracijos rizika, jei komanda iš naujo eksportuos projektą iš FlutterFlow.
