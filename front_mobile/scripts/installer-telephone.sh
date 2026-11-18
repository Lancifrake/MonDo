#!/bin/bash
# Compile l'app et l'installe sur le téléphone Android branché en USB (débogage USB activé).
# Usage : ./scripts/installer-telephone.sh            (serveur hébergé, via le relais Vercel)
#         ./scripts/installer-telephone.sh local      (serveur local sur le Mac, port 3100)
#         ./scripts/installer-telephone.sh --release  (APK à diffuser : sans l'import de comptes de démo)
set -e
cd "$(dirname "$0")/.."
API="https://mon-do-console.vercel.app/api"
DEMO="--dart-define=DEMO_COMPTES=true"
for a in "$@"; do
  case "$a" in
    local) API="http://$(ipconfig getifaddr en0):3100" ;;
    --release) DEMO="" ;;
  esac
done
APPAREIL=$(flutter devices --machine 2>/dev/null | python3 -c "import sys,json; print(next((d['id'] for d in json.load(sys.stdin) if d.get('targetPlatform','').startswith('android')), ''))")
[ -n "$APPAREIL" ] || { echo "Aucun téléphone Android détecté : branche-le et accepte le débogage USB."; exit 1; }
echo "Serveur : $API  |  téléphone : $APPAREIL"
flutter build apk --release --target-platform android-arm64 --dart-define=API_URL="$API" $DEMO
flutter install -d "$APPAREIL" --use-application-binary build/app/outputs/flutter-apk/app-release.apk
echo "Installé. Ouvre MonDo sur le téléphone."
