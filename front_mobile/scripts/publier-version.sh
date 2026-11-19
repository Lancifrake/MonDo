#!/bin/bash
# Publie une nouvelle version Android : l'application installée la propose à l'ouverture (« Nouvelle version »).
# Usage : ./scripts/publier-version.sh 1.0.1 "Ce qui change, en une ou deux phrases"
#   - le numéro de build (après le +) augmente de 1 à chaque publication ;
#   - l'APK est attaché à une release GitHub « mobile-v<version>+<build> » du dépôt public Lancifrake/MonDo.
set -e
cd "$(dirname "$0")/.."
VERSION="$1"; NOTES="$2"
[ -n "$VERSION" ] && [ -n "$NOTES" ] || { echo 'Usage : ./scripts/publier-version.sh 1.0.1 "Ce qui change"'; exit 1; }
BUILD=$(( $(sed -n 's/^version: .*+\([0-9]*\)$/\1/p' pubspec.yaml) + 1 ))
sed -i '' "s/^version: .*/version: $VERSION+$BUILD/" pubspec.yaml
TAG="mobile-v$VERSION+$BUILD"
echo "Construction de $TAG…"
# Avec Shorebird configuré : la version doit être une « release » Shorebird pour recevoir ensuite les correctifs.
if command -v shorebird >/dev/null && [ -f shorebird.yaml ]; then
  shorebird release android --artifact apk -- --dart-define=API_URL=https://mon-do-console.vercel.app/api --dart-define=DEMO_COMPTES=true
else
  flutter build apk --release --dart-define=API_URL=https://mon-do-console.vercel.app/api --dart-define=DEMO_COMPTES=true
fi
cp build/app/outputs/flutter-apk/app-release.apk "build/MonDo-$VERSION.apk"
gh release create "$TAG" "build/MonDo-$VERSION.apk" --repo Lancifrake/MonDo --title "MonDo $VERSION (Android)" --notes "$NOTES"
echo "Publié : $TAG. Pense à commiter pubspec.yaml (version $VERSION+$BUILD)."
