# Manto rasti defektai ir spragos (SCRUM-62, 65, 30, 33)

**4 defektų grupės, kurias patvirtina 8 krentantys reikalavimų / AC testai**, ir 1 reikalavimo spraga, kurią rodo 9-as krentantis testas.
Iš viso 38 automatiniai testai: 29 PASS, 9 FAIL. Defektai sąmoningai **netaisyti**.

## D1 — 3 jaustukai vietoje privalomų 5

- **Reikalavimai:** SCRUM-62, SCRUM-65
- **AC:** SCRUM-62 AC2, SCRUM-65 AC65-1
- **Jira TC / testai:** TC-FEAT62-03 (`TC-FEAT62-03 (BVA: 5)` ir pagalbinis unit testas), TC-US65-01 — FAIL
- **Tikėtasi:** pasirinkus dainą rodomi 5 jaustukai
- **Faktiškai:** rodomi 3 (`Expected: <5> Actual: <3>`)
- **Šaltinis:** `lib/pages/post/post_widget.dart:18-23` (`kEmotions`); demo kopija `lib/demo/demo_data.dart:11-15`
- **Svarba:** Major (Jira prioritetas High)
- **Kaip rasta:** BVA (riba 5) widget ir unit testai
- **Demo:** **taip**, atkuriama web demo („New post“ → pasirinkti dainą → 3 jaustukai)

## D2 — Facebook atšaukimas / nesėkmė (Android/iOS): null klaida, nėra privalomo pranešimo

- **Reikalavimai:** SCRUM-30, SCRUM-33
- **AC:** SCRUM-30 AC6, SCRUM-33 AC6
- **Jira TC / testai:** TC-FEAT30-02, TC-US33-04, `EBT-AUTH-03` — FAIL
- **Tikėtasi:** naudotojas neprijungiamas, lieka prisijungimo ekrane, rodomas klaidos pranešimas
- **Faktiškai:** naudotojas neprijungiamas, bet programa meta `Null check operator used on a null value` ir pranešimo nėra
- **Šaltinis:** `lib/auth/firebase_auth/facebook_auth.dart:57/61` (`result!`); `firebase_auth_manager.dart:340` gaudo tik `FirebaseAuthException`
- **Svarba:** Major
- **Kaip rasta:** DT (atšaukimo šaka) + klaidomis grįstas testas; patikrinta, kad tikras `flutter_facebook_auth` SDK atšaukus grąžina `accessToken = null` (ne test double artefaktas)
- **Demo:** **ne** — web naudoja kitą kodo šaką (`signInWithPopup`), Facebook programėlė nesukurta (SCRUM-69)

## D3 — Google atšaukimas (Android/iOS): nėra privalomo pranešimo

- **Reikalavimai:** SCRUM-30, SCRUM-33
- **AC:** SCRUM-30 AC6, SCRUM-33 AC6 (abu aiškiai reikalauja pranešimo atšaukus)
- **Jira TC / testai:** Jira TC nėra (TC rinkinyje atšaukimas tik per Facebook); testas `AC6-GOOGLE-CANCEL` — FAIL
- **Tikėtasi:** neprijungiamas + rodomas pranešimas
- **Faktiškai:** neprijungiamas, bet programa tyliai grįžta, pranešimo nėra
- **Šaltinis:** `lib/auth/firebase_auth/google_auth.dart:14-16`, `firebase_auth_manager.dart:337`, `log_in_page_widget.dart:292`
- **Svarba:** Minor
- **Kaip rasta:** AC6 testas (Google variantas), atšaukimas imituotas tikru SDK kodu `sign_in_canceled`
- **Demo:** **ne** — demo build'e Google mygtukas apeina autentifikaciją; web šaka pagal kodą pranešimą rodytų

## D4 — Google SDK `PlatformException` neapdorojama

- **Reikalavimas:** SCRUM-30
- **AC:** SCRUM-30 AC6 („nepavykus … autentifikacijai … pateikiamas klaidos pranešimas“)
- **Jira TC / testai:** Jira TC nėra; testas `EBT-AUTH-02` — FAIL
- **Tikėtasi:** tinklo / SDK klaidos atveju neprijungiamas ir rodomas pranešimas
- **Faktiškai:** `PlatformException(network_error, …)` neapdorota, pranešimo nėra
- **Šaltinis:** `lib/auth/firebase_auth/google_auth.dart:14`; `firebase_auth_manager.dart:340` gaudo tik `FirebaseAuthException`
- **Svarba:** Medium
- **Kaip rasta:** klaidomis grįstas testas; klaidos kodai `network_error` / `sign_in_failed` patikrinti tikruose Android/iOS plugin'uose
- **Demo:** **ne** — reikėtų mobiliojo įrenginio ir dirbtinės tinklo klaidos

## Requirement / testability gaps

Tai **ne** programos klaidos — Jira elgesio neapibrėžia arba apibrėžia nevienareikšmiškai.

- **G1 — nepavykusio įkėlimo elgesys neapibrėžtas.** `EBT-POST-07` FAIL: nepavykus įrašyti į DB (`post_widget.dart:113`) išimtis neapdorojama, naudotojas nieko nemato; įrašas neišsaugomas. **Tai NĖRA tiesioginis AC pažeidimas** — joks AC nenusako, kas turi įvykti; SCRUM-62 komentare pažymėta, kad klaidų pranešimai neapibrėžti. Rasta klaidomis grįstu testavimu.
- **G2 — TC-FEAT30-06 reikalauja daugiau nei AC.** TC nurodo „rodoma uid“, bet AC5 reikalauja tik pasiekti profilio informaciją, AC3 — uid išsaugoti. **Matomo uid trūkumas NĖRA produkto defektas** — tai TC ir AC atsekamumo neatitikimas. Testas tikrina AC: vardas ir el. paštas matomi, uid yra profilio įraše (PASS).
- **G3 — „suvestinė“ (SCRUM-62 AC3) neapibrėžta.** Interpretuota kaip Statistikos ekranas.
- **G4 — Jira TC rinkinys nepilnas.** Nėra TC Google atšaukimui (AC6) ir SCRUM-30 AC1; pridėti automatiniai testai.
- **G5 — pranešimų tekstai neapibrėžti; TC-FEAT62-01 leidžia „blokuojamas / mygtukas neaktyvus“.** Testai pranešimų formuluočių netikrina.
- **G6 — SCRUM-62 DoD mini „sėkmės pranešimą“**, bet tai ne AC; ne demo režime jo nėra. Netestuota kaip defektas.

## Trumpas paaiškinimas gynimui

> Mano dalis — keturi reikalavimai: SCRUM-62 ir SCRUM-65 apie jaustuko pasirinkimą įkeliant dainą, ir SCRUM-30 bei SCRUM-33 apie registraciją per Google ir Facebook.
>
> Testavau automatiškai su Flutter — dažniausiai widget testais, kurie paleidžia tikrus programos ekranus. Firebase, Google ir Facebook pakeičiau test doubles, nes tikro OAuth automatiniame teste paleisti negalima ir rezultatai turi būti pakartojami.
>
> Įvykdžiau visus 22 Jira test case'us ir padengiau visus 21 acceptance criteria — tai 100 %. Iš viso 38 automatiniai testai: 29 praėjo, 9 krito.
>
> Krentančių testų netaisiau, nes užduotis — patikrinti, ar programa atitinka reikalavimus, o ne priderinti testus prie kodo. Jei Jira sako viena, o kodas daro kita, testas turi kristi.
>
> Ryškiausias pavyzdys: Jira reikalauja 5 jaustukų, o kode yra tik 3 — tai matosi ir teste, ir demo versijoje.
>
> Klaidomis grįstas testavimas rado ir patikimumo problemų: pavyzdžiui, atšaukus Facebook prisijungimą programa meta null klaidą ir nerodo pranešimo, nors AC6 jį reikalauja.
>
> Galiausiai atskyriau tikrus defektus nuo reikalavimų spragų: pavyzdžiui, kai nepavyksta išsaugoti įrašo, Jira neapibrėžia, kas turi įvykti, todėl tai ne programos klaida, o reikalavimo trūkumas. Taip pat vieno test case'o reikalavimą rodyti uid laikau test case'o neatitikimu acceptance kriterijui, ne defektu.
