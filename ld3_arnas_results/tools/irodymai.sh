#!/usr/bin/env bash
# LD3 – Arnas: draugų srauto laiko elgsenos ir mastelio kaitos matavimų
# pakartojimas. Paleisti iš repozitorijos šaknies:
#   bash ld3_arnas_results/tools/irodymai.sh
# Skriptas užfiksuoja aplinką ir kodo versiją, paleidžia matavimų testus vienas po
# kito (ne lygiagrečiai, kad laikai nesiveiktų), surenka suvestinę ir padaro
# ekrano vaizdus.
set -uo pipefail
cd "$(git rev-parse --show-toplevel)"

OUT=ld3_arnas_results
BASE=d90e75a
mkdir -p "$OUT/screenshots"
rm -rf "$OUT/raw"

lockver() { awk -v p="  $1:" '$0==p{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock; }

{
  echo "Data: $(date '+%Y-%m-%d %H:%M %Z')"
  echo "Repozitorija: $(git remote get-url upstream 2>/dev/null || git remote get-url origin)"
  echo "Šaka: $(git rev-parse --abbrev-ref HEAD), HEAD: $(git rev-parse --short HEAD)"
  echo "Matuojamas kodas: $BASE ($(git log -1 --format=%s $BASE))"
  echo "git diff --stat $BASE -- lib android ios web firebase pubspec.yaml pubspec.lock:"
  d=$(git diff --stat $BASE -- lib android ios web firebase pubspec.yaml pubspec.lock)
  echo "  ${d:-(tuščia – produkcinis kodas ir priklausomybės nepakeisti)}"
  echo "Nesekami/pakeisti failai už test/ld3_arnas ir $OUT ribų:"
  s=$(git status --porcelain | grep -v -E " (test/ld3_arnas|$OUT)/" || true)
  echo "  ${s:-(nėra)}"
  echo "OS: $(. /etc/os-release; echo "$PRETTY_NAME"), branduolys $(uname -r)"
  echo "CPU: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs), loginių branduolių: $(nproc)"
  flutter --version 2>/dev/null | grep -E '^(Flutter|Tools)'
  echo "fake_cloud_firestore $(lockver fake_cloud_firestore), cloud_firestore $(lockver cloud_firestore), assets_audio_player (git 243f953)"
} > "$OUT/env.txt"
cat "$OUT/env.txt"

echo; echo "== flutter analyze test/ld3_arnas"
flutter analyze test/ld3_arnas > "$OUT/analyze.log" 2>&1; tail -n 1 "$OUT/analyze.log"

status=0
for suite in time_behaviour scalability screens; do
  echo "== flutter test test/ld3_arnas/${suite}_test.dart"
  flutter test "test/ld3_arnas/${suite}_test.dart" -r expanded > "$OUT/${suite}_run.log" 2>&1 || status=1
  tail -n 1 "$OUT/${suite}_run.log"
done

{
  echo "LD3 – Arnas: draugų srautas (FriendFeed), laiko elgsena ir mastelio kaita"
  echo "Kodas: $BASE; $(grep -E '^Flutter' "$OUT/env.txt" | awk '{print $1, $2}'), $(grep fake_cloud "$OUT/env.txt")"
  echo "Laikai – mediana (min–max) iš 7 paleidimų po 2 apšilimo, flutter_test debug (JIT)."
  echo
  for id in L1 L1-M L2 L1-DB M1 M1-R M2; do
    grep -h "^RESULT | $id |" "$OUT"/time_behaviour_run.log "$OUT"/scalability_run.log \
      | sed -E 's/^RESULT \| //'
  done
  echo
  for suite in time_behaviour scalability screens; do
    echo "$suite: $(tail -n 1 "$OUT/${suite}_run.log")"
  done
} > "$OUT/SUVESTINE.txt"

echo; cat "$OUT/SUVESTINE.txt"

# Terminalo išvesties ekrano vaizdai (LD2 įrankis, antraštinis Firefox).
shot() { python3 lab2/arnas/scripts/screenshot.py log "$@" || echo "ekrano vaizdas nepavyko: $1"; }
shot "$OUT/screenshots/T1_aplinka_ir_versija.png" "LD3 Arnas – aplinka ir kodo versija" "$OUT/env.txt"
shot "$OUT/screenshots/T2_suvestine.png" "LD3 Arnas – matavimų suvestinė" "$OUT/SUVESTINE.txt"
shot "$OUT/screenshots/T3_laiko_elgsena_paleidimas.png" "LD3 Arnas – laiko elgsenos testų paleidimas" "$OUT/time_behaviour_run.log"
shot "$OUT/screenshots/T4_mastelio_kaita_paleidimas.png" "LD3 Arnas – mastelio kaitos testų paleidimas" "$OUT/scalability_run.log"

exit $status
