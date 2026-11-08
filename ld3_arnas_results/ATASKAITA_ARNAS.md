# LD3 – Arno dalis: laiko elgsena ir mastelio kaita (draugų srautas)

> Paruošta 2026-11-08. **Confluence puslapis „3 laboratorinis“ nekeistas** – žemiau esantį tekstą reikia įkelti ranka.
>
> Kodas ir įrodymai: šaka [`arnas-3lb`](https://github.com/ArnasIc3/musicreal/tree/arnas-3lb) (`ArnasIc3/musicreal`, matuota versija `d90e75a`), katalogai `test/ld3_arnas/` ir `ld3_arnas_results/`.
>
> Šio failo kopija: `ld3_arnas_results/ATASKAITA_ARNAS.md`.

---

## ⚠️ KO TRŪKSTA – BŪTINA SUTVARKYTI

### A. Mano daliai, prieš įkeliant į Confluence

1. **Ekrano vaizdai dar neįkelti į Confluence.** Užduotis reikalauja matavimus įrodyti ekrano vaizdais. Paruošti 8 PNG `ld3_arnas_results/screenshots/`. Į 5 skyrių įkelti bent **T2, S2, S4** (sąrašas – 5 skyriaus tekste).
2. ~~Kodas ne GitHub'e.~~ **Sutvarkyta:** nupushinta į šaką [`arnas-3lb`](https://github.com/ArnasIc3/musicreal/tree/arnas-3lb). Jei komanda nori, kad kodas būtų pagrindiniame `RokGis/musicreal`, reikia atidaryti PR.
3. **Flutter versija skiriasi nuo komandos:** aš – 3.44.9, Rokas ir Edas – 3.44.0. Projekto versija ta pati (`d90e75a`). Tai įrašyta 2 skyriaus tekste. Jei komandai svarbu vienodumas, matavimus galima perleisti su 3.44.0.
4. **Matavimai – flutter_test (debug, JIT), ne telefone, tinklas modeliuotas.** Tai aiškiai parašyta tekste, bet gynime tai bus pirmas klausimas – žr. „Pasiruošimas gynimui“.

### B. Visam Confluence puslapiui (palyginta su užduoties .docx, 2026-11-08 turiniu)

| # | Trūkumas | Kieno | Užduoties reikalavimas | Ką daryti |
|---|---|---|---|---|
| 1 | **Nėra nė vieno ekrano vaizdo** (Rokas turi 1) | **Mantas, Edas** | „PS produkto kokybės matavimus/testavimus įrodyti ekrano vaizdais“ | Įkelti testų išvesties ar suvestinės ekrano vaizdus į 5 skyrių |
| 2 | **6 skyrius „Bendros išvados“ tuščias** | visi | „Pateikti išvadas ir rekomendacijas“ | Juodraštis – šio failo pabaigoje |
| 3 | **LD3 testų kodo nėra GitHub'e**: `RokGis/musicreal` main = `d90e75a`, `ArnasIc3/musicreal` turi tik LD1/LD2 šakas | Mantas (`ld3/`), Rokas (`test/ld3_rokas`, `ld3_rokas_results`), Edas (`test/ld3_edas`, `ld3_edas_results`). Mano – šakoje `arnas-3lb` | „Turėti prieigą prie taikytų įrankių, matavimo galimybei pakartoti“ | Nupushinti. Gal yra asmeniniuose fork'uose – patikrinti |
| 4 | **Nėra pastraipos „Vertinimas naudojimui ir palaikymui“ ir palyginimo su SLA** | **Mantas** | „Įvertinti įtaką naudojimo/palaikymo metu; atitikimą SLA ar rekomendacijoms“ | Parašyti pastraipą kaip Roko ir Edo |
| 5 | **Nė viena rekomendacija nepagrįsta literatūra** (yra tik nuoroda į Firebase dokumentaciją) | **Mantas** | „Bent viena rekomendacija grindžiama literatūros šaltiniais“ | Pvz., [OWASP Top 10 – A01 Broken Access Control](https://owasp.org/Top10/) (yra kurso šaltinių sąraše) |
| 6 | Matuota kita versija (`69237bc`), kiti – `d90e75a` | Mantas | sistemiškumas | Patikrinau: `git diff 69237bc d90e75a -- firebase/firestore.rules` tuščias, taisyklės tos pačios, rezultatai palyginami. Užtenka vieno sakinio |
| 7 | 5 skyriuje neįvardyti testų ir žurnalų failai | Mantas | pakartojamumas | Įrašyti kaip Roko ir Edo |
| 8 | Įrankiai pateikti nuoroda, bet be trumpo aprašymo | visi (smulkmena) | „Pateikti trumpą informaciją apie įrankį ir jo URL“ | Po vieną sakinį, ką įrankis daro |
| 9 | Niekur nepagrįsta, kodėl subcharakteristikos aktualios produktui | visi (smulkmena) | „Pasirinktos sub-charakteristikos turi būti aktualios tiriamam PS produktui“ | Po vieną sakinį (mano tekste yra) |

---

## Tekstas Confluence puslapiui (kopijuoti į „Arnas –“ vietas)

### 1. Pasirinktos subcharakteristikos

Arnas – laiko elgsena (veikimo efektyvumas) ir mastelio kaita (lankstumas) pagal [ISO/IEC 25010:2023](https://www.iso.org/standard/78176.html).

### 2. Įrankiai ir matavimo būdas

**Arnas**

2026-11-08 matavau draugų srautą (SCRUM-49) – `FriendFeed` ir `friendsFeedQuery()` faile `lib/pages/home/home_widget.dart` – iš projekto versijos d90e75a. Srautas yra pirmas ekranas po prisijungimo, o jo apimtis auga su draugų ir jų įrašų skaičiumi. Todėl jam aktualiausia, kaip greitai jis parodomas ir kaip elgiasi didėjant apkrovai.

Įrankiai:
- [Flutter 3.44.9 flutter_test valdiklių testai](https://docs.flutter.dev/cookbook/testing/widget/introduction) – paleidžia tikrus ekrano valdiklius be įrenginio. Kadrų trukmę matavau `Stopwatch`, tinklo vėlinimą modeliavau virtualiu testų laikrodžiu.
- [fake_cloud_firestore 3.0.2](https://pub.dev/packages/fake_cloud_firestore) – Firestore duomenų bazė atmintyje.
- Manto platformos lygio Firestore pakaitalas – po juo veikia tikras [cloud_firestore 5.6.9](https://pub.dev/packages/cloud_firestore) kodas, todėl M1 tikrinau su nepakeistu produkciniu `FeedSource`.
- `assets_audio_player` kanalo pakaitalas – skaičiuoja garso grotuvų atidarymus ir atsako kaip įrenginys.

Produkcinio kodo nekeičiau (`git diff -- lib android ios web firebase` tuščias), duomenys sintetiniai, produkcinės aplinkos nematavau.

Laiko elgsenai matavau du dalykus:
- **L1** – srauto įkėlimo laiką: nuo srauto atsiradimo ekrane iki kadro, kuriame visos kortelės turi autorių, dainą ir paruoštą grotuvą.
- **L2** – naujo draugo įrašo pasirodymo laiką: nuo atnaujinto užklausos rezultato iki kadro, kuriame nauja kortelė pilnai parodyta ir visų kortelių autoriai atitinka dainas.

L1 ir L2 matavau kliento pusėje su atmintyje paruoštais duomenimis. Priežastis: fake_cloud_firestore kiekvienai užklausai perrenka visą kolekciją ir pats užtrunka ilgiau nei ekranas (kontrolinis matavimas su juo: 30 įrašų – 489,6 ms vietoj 249,0 ms). Tinklo dalį vertinau atskirai (L1-M): kiekvienos Firestore užklausos pirmam atsakymui pridėjau 100 ms ir 300 ms vėlinimą ir virtualiu laikrodžiu matavau, kada srautas pilnas. Kiekvieną scenarijų paleidau 7 kartus po 2 apšilimo paleidimų ir skelbiu medianą su ribomis. Ekranas – telefono dydžio (412 × 915).

Mastelio kaitai matavau:
- **M1** – kokią dalį draugų šios dienos įrašų srautas parodo, kai draugų skaičius auga (30 ir 31, papildomai 100).
- **M2** – kiek išteklių (Firestore prenumeratų, garso grotuvų, kortelių) sunaudojama atidarant srautą ir atėjus vienam naujam įrašui, kai įrašų yra 10 ir 30 (papildomai 1 ir 100).

Debug režimu per didelę užklausą sustabdo cloud_firestore `assert`. Todėl release elgseną, kai užklausą atmeta platforma, modeliavau atskirai (M1-R).

Slenksčiai (tyrimo, ne SLA):
- pilnas srautas – greičiau nei per 1 s (Nielseno 1 s riba);
- kadras – iki 16 ms (60 kadrų/s);
- srautas veikia su bet kuriuo draugų skaičiumi, kurį programa leidžia pridėti (100 %);
- naujas įrašas – ne daugiau kaip 2 naujos prenumeratos ir 1 grotuvas (tiek reikia vienai kortelei).

SCRUM-49 skaitinių reikalavimų neturi.

### 3. Matavimų rezultatai

**Arnas**

| Metrika | 1 scenarijus | 2 scenarijus |
|---|---|---|
| L1. Srauto įkėlimo laikas (kliente) | 10 įrašų: 131,3 ms (115,8–150,6), ilgiausias kadras 59,5 ms | 30 įrašų: 249,0 ms (203,1–336,8), ilgiausias kadras 118,3 ms |
| L2. Naujo draugo įrašo pasirodymo laikas | Sraute 10 įrašų: 75,2 ms (68,0–129,8), ilgiausias kadras 29,1 ms | Sraute 30 įrašų: 157,4 ms (135,6–237,0), ilgiausias kadras 62,4 ms |
| M1. Parodytų draugų įrašų dalis | 30 draugų: 30/30 (100 %) | 31 draugas: 0/31 (0 %), `AssertionError`; release modelis – begalinis įkėlimo indikatorius |
| M2. Ištekliai: prenumeratos / grotuvai | 10 įrašų: atidarant 21 / 10 (ekrane 5 kortelės); naujas įrašas – 32 / 11 | 30 įrašų: atidarant 61 / 30 (ekrane 5 kortelės); naujas įrašas – 92 / 31 |

Papildomi atvejai:
- **Bazinis** (1 įrašas): L1 – 44,4 ms, L2 – 22,9 ms.
- **Apkrovos** (30 draugų, 100 įrašų – programa leidžia skelbti kelis kartus per dieną): L1 – 733,8 ms (ilgiausias kadras 344,2 ms), L2 – 457,1 ms, atidarant 201 prenumerata ir 100 grotuvų.
- **Tinklo modelis L1-M:** su 100 ms vėlinimu srautas pilnas po 305 ms, su 300 ms – po 905 ms. Tiek pat ir su 10, ir su 30 įrašų: 3 nuoseklūs etapai (įrašų sąrašas → autorius → daina).
- **Kontrolinis L1-DB** su fake_cloud_firestore: 10 įrašų – 149,0 ms, 30 – 489,6 ms.
- Pakartotinis viso rinkinio paleidimas medianas pakeitė ne daugiau kaip 13 %.

**Laiko elgsena.** Kliento laikas auga tiesiškai su įrašų skaičiumi – apie 6–7 ms vienam įrašui (131 → 249 → 734 ms prie 10, 30 ir 100 įrašų), nors ekrane telpa tik 5 kortelės. Priežastis: srautas yra `ListView.builder` su `shrinkWrap: true` ir `NeverScrollableScrollPhysics` viduje `SingleChildScrollView`. Taip iš karto sukuriamos ir išdėstomos visos kortelės kartu su grotuvais. Ilgiausias kadras – tas, kuriame sukuriamos kortelės su grotuvais. Jis viršija 16 ms jau prie 10 įrašų (59,5 ms), o prie 30 įrašų siekia 118,3 ms.

Tinklo dalis už kliento kainą didesnė. Kortelė pilna tik po trijų nuoseklių užklausų (įrašų sąrašas → autoriaus dokumentas → dainos užklausa), nes autoriaus ir dainos srautai sukuriami tik gavus ankstesnio etapo duomenis. Todėl apytiksliai:
- su 100 ms vėlinimu 30 įrašų srautas pilnas po ~0,55 s (305 + 249 ms);
- su 300 ms – po ~1,15 s (905 + 249 ms), t. y. 1 s slenkstis viršijamas.

Naujas įrašas parodomas per 4 kadrus, bet pirmajame kadre po atnaujinimo **visų kortelių autoriai neteisingi**. Kortelės pririštos prie indekso, todėl naujas įrašas viršuje paslenka sąrašą, o `StreamBuilder` dar rodo seną autorių su nauja daina (S2 ekrano vaizdas: „Friend 009“ prie „Song 000-900“, nors daina priklauso „Friend 000“).

**Mastelio kaita.** Srautas turi kietą 30 draugų ribą. `friendsFeedQuery()` visus draugus deda į vieną `whereIn` filtrą, o Firestore `in` filtras leidžia ne daugiau kaip 30 reikšmių. Draugų pridėjimas jokios ribos neturi, SCRUM-49 jos nemini.

Su 31 draugu parodoma 0 % įrašų:
- debug režimu `FriendFeed.build()` meta `AssertionError` ir vietoj srauto rodomas klaidos ekranas;
- release režimu assert'ai pašalinami, užklausą atmeta platforma, o `queryCollection()` klaidą nuryja (`handleError(print)`). Srautas lieka įkėlimo būsenoje neribotai – po 10 s vis dar indikatorius, be pranešimo ir be pakartojimo mygtuko (M1-R, S4).

Tai konkretus jau užregistruoto defekto SCRUM-167 atvejis ir SCRUM-49 AC7 pažeidimas. LD2 teste Q09 riba rasta užklausos lygiu, dabar patvirtinta ir naudotojo ekrane su produkciniu `FeedSource`.

Ištekliai auga su visais dienos įrašais, o ne su matomomis kortelėmis:
- **Atidarant** sukuriama 1 + 2N prenumeratų ir N grotuvų (30 įrašų – 61 ir 30, nors matomos 5 kortelės).
- **Kiekvienas naujas įrašas** sukuria 3N + 2 naujų prenumeratų, nutraukia 3N ir iš naujo atidaro N + 1 grotuvą (30 įrašų – 92, 90 ir 31; ideali reikšmė – 2 ir 1). Priežastis: `FeedSource` kiekviename `build()` grąžina naują srautą, o paslinktos kortelės gauna kitą dainą, todėl grotuvas ją atidaro iš naujo.
- **Pasikeitus naudotojo dokumentui** (pvz., `streak_count`) `AuthUserStreamWidget` perkuria `FriendFeed`, ir 31 kortelės sraute sukuriama 156 naujos prenumeratos.

**Vertinimas naudojimui ir palaikymui.** Tipiniam naudotojui (iki 10 draugų, po įrašą per dieną) su geru ryšiu srautas parodomas per ~0,4 s, todėl 1 s slenkstis išlaikomas. Tačiau atidarant praleidžiami kadrai (ilgiausias kadras 59,5 ms > 16 ms). Su lėtu mobiliuoju ryšiu (300 ms) srautas pilnas tik po ~1,0–1,2 s. Slenkstis viršijamas dėl trijų nuoseklių užklausų, ne dėl duomenų kiekio.

Mastelio kaitos slenksčiai neišlaikyti. 31-asis draugas srautą sugadina visiškai ir be jokio pranešimo, o socialinėje programėlėje tai realus scenarijus, nes draugų skaičius neribojamas.

Palaikymui tai reiškia:
- klaidos nepasiekia nei naudotojo, nei stebėsenos (tik `print` į įrenginio žurnalą), todėl skundai atrodys kaip „srautas kraunasi amžinai“;
- tinklo ir baterijos sąnaudos auga su visais dienos įrašais: kiekvienas naujas įrašas iš naujo atidaro visus grotuvus ir perprenumeruoja visus dokumentus, o kiekvienas naujas Firestore klausytojas, jei dokumento nėra talpykloje, yra apmokestinamas skaitymas.

Laikai išmatuoti debug (JIT) režimu, todėl absoliučios reikšmės didesnės nei release versijos telefone. Išvadas grindžiu augimo pobūdžiu (tiesiškai su visais įrašais) ir etapų bei prenumeratų skaičiumi, kurie nuo režimo nepriklauso. SLA projekte nesutarta, todėl lyginta su išvardytais tyrimo slenksčiais.

### 4. Rekomendacijos

**Arnas**

1. **Panaikinti 30 draugų ribą.** `friendsFeedQuery()` naudoja vieną `whereIn('post_user', friends)`, o [Firestore `in` filtras](https://firebase.google.com/docs/firestore/query-data/queries) leidžia ne daugiau kaip 30 reikšmių. Galimi sprendimai:
   - draugų sąrašą skaidyti po 30 ir sujungti kelių užklausų rezultatus, rikiuojant pagal `created_at`;
   - įrašus rašant išskleisti į kiekvieno draugo srauto kolekciją (fan-out).

   SCRUM-49 papildyti draugų skaičiaus riba ir pridėti testą su 31 ir 100 draugų (M1).
2. **Rodyti klaidą ir leisti pakartoti.** `FriendFeed` tikrina tik `snapshot.hasData`, o `queryCollection()` klaidą nuryja, todėl bet kokia užklausos klaida (31 draugas, ryšys, teisės) baigiasi begaliniu indikatoriumi (M1-R). Reikia klaidos būsenos su „Bandyti dar kartą“, kaip reikalauja SCRUM-49 AC7 (defektas SCRUM-167).
3. **Kurti tik matomas korteles.** `SingleChildScrollView` + `ListView.builder(shrinkWrap: true, physics: NeverScrollableScrollPhysics())` pakeisti slenkamu `ListView.builder` arba `CustomScrollView` su `SliverList`, kad būtų kuriamos tik matomos (~5) ir artimiausios kortelės. Flutter dokumentacija tai pagrindžia:
   - [`ScrollView.shrinkWrap`](https://api.flutter.dev/flutter/widgets/ScrollView/shrinkWrap.html) nurodo, kad shrink-wrap gerokai brangesnis;
   - [Performance best practices](https://docs.flutter.dev/perf/best-practices) rekomenduoja ilgus sąrašus kurti tingiai ir kadrą išlaikyti per 16 ms.

   Dabar L1 ir M2 auga su visais įrašais. Garso grotuvą kurti tik paspaudus „Groti“, ne kortelės `initState`.
4. **Pašalinti trijų etapų užklausų grandinę.** Autoriaus vardą, nuotrauką ir dainos URL įrašyti į įrašo dokumentą jo kūrimo metu (denormalizacija), arba bent paleisti autoriaus ir dainos užklausas lygiagrečiai. Su denormalizacija pilnam srautui reikia 1 tinklo etapo vietoj 3: su 300 ms vėlinimu ~0,3 s vietoj ~0,9 s. Tada išlaikoma 1 s riba, kurią [J. Nielsenas](https://www.nngroup.com/articles/response-times-3-important-limits/) nurodo kaip ribą, iki kurios nenutrūksta naudotojo minties srautas. Prenumeratų sumažėtų nuo 1 + 2N iki 1.
5. **Stabilus kortelių tapatumas ir srautai.** Kortelėms suteikti `ValueKey(post.reference.path)`, o autoriaus ir dainos srautus kurti vieną kartą (kortelės `State` arba talpykloje pagal dokumento kelią), ne kiekviename `build()`. Dabar:
   - vienas naujas įrašas sukuria 3N + 2 prenumeratų ir N + 1 grotuvų atidarymų (30 įrašų – 92 ir 31 vietoj 2 ir 1);
   - pirmame kadre visos kortelės rodo ne to autoriaus vardą (L2, S2);
   - kiekvienas naudotojo dokumento pasikeitimas perprenumeruoja visą srautą (156 prenumeratos).
6. **Įtraukti matavimus į automatinį paleidimą su slenksčiais**, kad regresija būtų pastebėta iš karto:
   - srautas su 31 draugu rodo visus įrašus;
   - naujas įrašas – ne daugiau kaip 2 naujos prenumeratos;
   - L1 su 30 įrašų testuose – iki 300 ms.

### 5. Matavimų įrodymai

**Arnas**

Pakartojimas: projekto šaknyje paleisti `bash ld3_arnas_results/tools/irodymai.sh`. Skriptas:
- užfiksuoja aplinką ir kodo versiją;
- paleidžia `flutter analyze` ir tris testų rinkinius vienas po kito;
- surenka suvestinę ir padaro ekrano vaizdus.

Testai: `test/ld3_arnas/time_behaviour_test.dart`, `test/ld3_arnas/scalability_test.dart`, `test/ld3_arnas/screens_test.dart`. Pagalbiniai failai: `test/ld3_arnas/support/feed_bench.dart`, `test/ld3_arnas/support/rejecting_firestore.dart`.

Žurnalai ir suvestinė: `ld3_arnas_results/time_behaviour_run.log`, `scalability_run.log`, `screens_run.log`, `analyze.log`, `env.txt`, `SUVESTINE.txt`, `stabilumo_patikra.txt`, `raw/*.json` (kiekvieno paleidimo kadrų laikai).

Aplinka: Flutter 3.44.9, Dart 3.12.2, projekto versija d90e75a, `git diff -- lib android ios web firebase pubspec.yaml pubspec.lock` tuščias.

Ekrano vaizdai (`ld3_arnas_results/screenshots/`) – **įkelti bent T2, S2 ir S4**:

| Failas | Kas parodyta |
|---|---|
| `T1_aplinka_ir_versija.png` | Aplinka, kodo versija, tuščias `git diff` |
| `T2_suvestine.png` | Visų matavimų suvestinė ir „All tests passed“ |
| `T3_laiko_elgsena_paleidimas.png` | Laiko elgsenos testų paleidimas (14/14) |
| `T4_mastelio_kaita_paleidimas.png` | Mastelio kaitos testų paleidimas (8/8) |
| `S1_srautas_10_irasu.png` | Srautas su 10 įrašų (5 kortelės ekrane) |
| `S2_naujas_irasas_pirmas_kadras_neatitinka_autoriai.png` | Pirmas kadras po naujo įrašo – autoriai neatitinka dainų |
| `S3_naujas_irasas_po_3_kadru.png` | Ta pati būsena po 3 kadrų – teisingi autoriai |
| `S4_release_modelis_po_10s_begalinis_indikatorius.png` | Užklausą atmetus – po 10 s tik indikatorius |

---

## Pasiūlymas 6 skyriui „Bendros išvados“ (komandos juodraštis)

> Tik pasiūlymas – suderinti su Mantu, Roku ir Edu.

- **Stipriausios vietos:**
  - autentiškumas – 100 % teisingų tapatybės sprendimų (Edas);
  - vientisumas – svetimų įrašų keitimas ir trynimas blokuojami 100 % (Mantas);
  - talpa tipinei apkrovai – statistikos ekranas apie 15–19 ms (Rokas);
  - srauto laikas tipiniam naudotojui su geru ryšiu – apie 0,4 s (Arnas).
- **Silpniausios vietos:**
  - konfidencialumas – prisijungęs pašalinis skaito svetimą el. paštą ir įrašus;
  - apsauga nuo naudotojo klaidų – 0/4 pranešimų;
  - atkuriamumas – 1 iš 2 trūkių;
  - mastelio kaita – srautas neveikia nuo 31 draugo.
- **Bendra priežastis keliose vietose – klaidos nuryjamos be pranešimo ir pakartojimo:** statistika (R1), prisijungimas (U1), srautas (M1-R). Vienas bendras klaidos būsenos komponentas su „Bandyti dar kartą“ pagerintų tris subcharakteristikas iš karto.
- **Antra bendra priežastis – klientas skaito daugiau duomenų nei rodo:** statistika perskaito visus 30 dienų dokumentus (P3), srautas – visus dienos įrašus ir po dvi papildomas prenumeratas kiekvienam (M2). Sprendimai: agregacija serveryje, denormalizacija, tingūs sąrašai.
- **SLA nesutarta**, todėl visi lygino su tyrimo slenksčiais. Rekomenduojama į reikalavimus (SCRUM) įrašyti skaitines ribas: atsako laiką, draugų skaičių, duomenų apimtį.

---

## Pasiruošimas gynimui

### Apribojimai (pasakyti patiems, kol nepaklausė)

- **Debug (JIT), ne release telefone.** Absoliutūs laikai yra viršutinis įvertis. Išvados remiasi tuo, kas nuo režimo nepriklauso: tiesiniu augimu su N, 3 tinklo etapais, prenumeratų ir grotuvų skaičiais.
- **Tinklas modeliuotas.** Fiksuotas vėlinimas kiekvienos užklausos pirmam atsakymui, be pralaidumo ir svyravimų. Garso failo paruošimo laikas nemodeliuotas (grotuvo pakaitalas atsako iš karto), todėl realus laikas tik ilgesnis.
- **Release elgsena su 31 draugu modeliuota.** Debug režimu `assert` sustoja anksčiau. Modeliavau, kad platforma atmeta užklausą, ir patikrinau, ką tada rodo nepakeistas produkcinis kodas.
- **fake_cloud_firestore nepraneša `collectionGroup` klausytojams** apie įrašus subkolekcijose. M2 teste tas pats įvykis paskelbiamas `collectionGroup` keliu (`QuerySnapshotStreamManager.fireSnapshotUpdate`) – taip, kaip praneštų serveris. Komentaras yra kode (`feed_bench.dart`).
- **Firestore apmokestinimo nematavau.** Skaičiuoju prenumeratas, ne apmokestintus skaitymus (tai priklauso nuo SDK talpyklos).
- **Netikrinta:** kas nutinka grojančiam grotuvui, kai naujas įrašas paslenka sąrašą. `didUpdateWidget` grojančio grotuvo neatidaro iš naujo, todėl tikėtina, kad grojanti daina lieka po kitos kortelės. Tai hipotezė, ne matavimas.

### Tikėtini Komandos B klausimai

- **Kuo skiriasi tavo mastelio kaita nuo Roko talpos?**
  - Talpa – kiek ekranas gali apdoroti neviršydamas slenksčio (Rokas: statistika iki ~33 000 įrašų).
  - Mastelio kaita (ISO/IEC 25010:2023 nauja lankstumo subcharakteristika) – kaip elgsena ir išteklių naudojimas keičiasi augant apkrovai ir ar sistema prisitaiko. Pas mane: kieta riba ties 31 draugu (M1) ir augimo koeficientas – 2 prenumeratos ir 1 grotuvas vienam įrašui atidarant, 3 prenumeratos vienam įrašui per kiekvieną atnaujinimą (M2).
  - Matuojami skirtingi ekranai.
- **Kodėl L1/L2 be duomenų bazės?** Kontrolinis L1-DB parodė, kad fake_cloud_firestore pats sunaudoja daugiau laiko nei ekranas (490 ms vs 249 ms prie 30 įrašų). Jis kiekvienai užklausai perrenka ir kopijuoja visą kolekciją, o Firestore naudoja indeksus. Tokie laikai matuotų pakaitalą, ne MusicReal. Produkcinis užklausų kelias tikrinamas M1 ir M2.
- **Ar 30 riba tikra produkcijoje?** Taip. Ją nurodo Firestore dokumentacija, `cloud_firestore` 5.6.9 ją tikrina `query.dart` assert'e (matosi M1 klaidoje), o platformos SDK tikrina užklausą prieš siunčiant.
- **Kodėl naujas įrašas sukuria 3N + 2 prenumeratų?**
  - `ListView` perkuria visas korteles, `FeedSource.author()` grąžina naują srautą, todėl `StreamBuilder` atsisako seno ir prenumeruoja naują: N + 1 autorių.
  - Dainos srautas perkuriamas du kartus – kai pasikeičia sąrašas ir kai ateina autorius: N + (N + 1).
  - Iš viso: N + 1 + N + N + 1 = 3N + 2. Tai sutampa su išmatuotu 32 / 92 / 302.
- **Kaip modeliavai tinklą?** Kiekvieno srauto prenumerata prijungiama prie duomenų tik po RTT laikmačio virtualiame testų laikrodyje, laikas skaičiuojamas 5 ms žingsniais. Rezultatas lygiai 3 × RTT nepriklausomai nuo N: užklausos viename etape lygiagrečios, bet etapai nuoseklūs.
- **Kodėl 16 ms ir 1 s?**
  - 16 ms – vienas kadras prie 60 Hz ([Flutter UI performance](https://docs.flutter.dev/perf/ui-performance)).
  - 1 s – Nielseno riba, iki kurios naudotojas nepraranda minties srauto.
  - SLA ir SCRUM-49 skaitinių ribų neturi.
- **Kaip tai susiję su ISO/IEC 25023?**
  - L1 atitinka apdorojimo trukmę (*turnaround time*): nuo užklausos iki pilno rezultato.
  - L2 – atsako laiką (*response time*).
  - Adekvatumas – santykis su slenksčiu, pvz., ilgiausias kadras 118,3 / 16 ≈ 7,4 prie 30 įrašų.

---

## Šaltiniai

- ISO/IEC 25010:2023 – https://www.iso.org/standard/78176.html
- Firestore užklausos ir `in` riba – https://firebase.google.com/docs/firestore/query-data/queries
- J. Nielsen, „Response Times: The 3 Important Limits“ – https://www.nngroup.com/articles/response-times-3-important-limits/
- Flutter Performance best practices – https://docs.flutter.dev/perf/best-practices
- Flutter `ScrollView.shrinkWrap` – https://api.flutter.dev/flutter/widgets/ScrollView/shrinkWrap.html
- Flutter UI performance (16 ms kadras) – https://docs.flutter.dev/perf/ui-performance
- flutter_test – https://docs.flutter.dev/cookbook/testing/widget/introduction
- fake_cloud_firestore – https://pub.dev/packages/fake_cloud_firestore
- cloud_firestore – https://pub.dev/packages/cloud_firestore
- Jira: SCRUM-49 (srauto reikalavimas, AC7), SCRUM-167 (srautas nerodo klaidos)
