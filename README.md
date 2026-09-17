# MusicReal (ProjectForManagement)

A Flutter + Firebase app for sharing a daily song with an emotion: friends see
each other's posts in a feed, keep a posting streak, and view their own
30-day statistics.

Tracked in Jira project **SCRUM**. Test documentation for the course lab:
[`LD1_TESTAVIMAS.md`](LD1_TESTAVIMAS.md).

## Requirements

- **Flutter 3.44** (stable). Older or newer versions may fail to build —
  check with `flutter --version`.
- A browser, Android emulator or iOS simulator.

## Run it

```bash
git clone <this repository>
cd project_for_management
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

Then open **http://localhost:8080** (the first load takes about a minute).

> Use `localhost`, not `127.0.0.1` — Firebase only allows Google sign-in from
> `localhost` by default.

Other targets:

```bash
flutter emulators --launch Pixel_10 && flutter run   # Android
open -a Simulator && flutter run                     # iOS
```

## Signing in

Use **Continue with Google** with any Google account. Everyone shares the same
Firebase project, so classmates can find and add each other as friends.

## Firebase

The app talks to the Firebase project `project-for-management-sugxvo`.
Security rules live in [`firebase/firestore.rules`](firebase/firestore.rules)
and Cloud Functions in [`firebase/functions`](firebase/functions) and
[`firebase/custom_cloud_functions`](firebase/custom_cloud_functions).

Only project owners can deploy them:

```bash
cd firebase
npx firebase-tools login
npx firebase-tools deploy --only firestore:rules,functions -P project-for-management-sugxvo
```

## Project layout

| Path | What's there |
| --- | --- |
| `lib/pages/` | Screens: home feed, post, friends, profile, login |
| `lib/statistics/` | 30-day statistics screen |
| `lib/ui/app_ui.dart` | Shared design system (cards, avatars, buttons) |
| `lib/backend/` | Firestore records and queries |
| `firebase/` | Security rules and Cloud Functions |

## Music credits

The songs bundled in `assets/` are royalty-free tracks by the artists below.

Kevin MacLeod's music is licensed under
[Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/),
which requires this attribution:

- "Back on Track - Latinesque" by Kevin MacLeod (incompetech.com)
- "Bushwick Tarentella Loop" by Kevin MacLeod (incompetech.com)
- "Gnarled Situation" by Kevin MacLeod (incompetech.com)

Licensed under Creative Commons: By Attribution 4.0 License.

| Track | Artist | File |
| --- | --- | --- |
| Back on Track - Latinesque | Kevin MacLeod | `assets/videos/Back_on_Track_-_Latinesque_-_Kevin_MacLeod.mp3` |
| Bushwick Tarentella Loop | Kevin MacLeod | `assets/videos/Bushwick_Tarentella_Loop_-_Kevin_MacLeod.mp3` |
| Gnarled Situation | Kevin MacLeod | `assets/videos/Gnarled_Situation_-_Kevin_MacLeod.mp3` |
| Precipice | Twin Musicom | `assets/videos/Precipice_-_Twin_Musicom.mp3` |
| Race Car | Rondo Brothers | `assets/videos/Race_Car_-_Rondo_Brothers.mp3` |
| This Or That | TrackTribe | `assets/videos/This_Or_That_-_TrackTribe.mp3` |
| Ten | Anno Domini Beats | `assets/audios/Ten_-_Anno_Domini_Beats.mp3` |

The tracks by Twin Musicom, Rondo Brothers, TrackTribe and Anno Domini Beats
come from the YouTube Audio Library. Their files carry no license text, so check
each one's terms in the library before reusing them outside this project.

## Note on FlutterFlow

The project was first generated with FlutterFlow and then edited by hand.
Re-exporting from FlutterFlow will overwrite those edits.
