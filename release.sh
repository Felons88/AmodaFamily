#!/usr/bin/env bash
# Kinplora release — bumps version, builds signed APK, publishes GitHub
# release + update manifest. Usage: ./release.sh 0.2.0
set -euo pipefail
cd "$(dirname "$0")"

VER="${1:?usage: ./release.sh X.Y.Z}"
OLD_BUILD=$(grep '^version:' pubspec.yaml | grep -oE '[0-9]+$')
BUILD=$((OLD_BUILD + 1))
TAG="v$VER"

echo "==> Releasing $VER (build $BUILD)"
sed -i "s/^version: .*/version: $VER+$BUILD/" pubspec.yaml

flutter build apk --release \
  --dart-define=SUPABASE_URL=https://sjxctvcneibdsqhwszeq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable__gQzSrc7lJ7ic3y1Pk7u_Q_qCgmYh5x \
  --dart-define=UPDATE_MANIFEST_URL=https://raw.githubusercontent.com/Felons88/AmodaFamily/main/deploy/version.json

python - "$VER" "$BUILD" <<'PY'
import json, sys
v, b = sys.argv[1], int(sys.argv[2])
json.dump({"version": v, "build": b,
  "apkUrl": "https://github.com/Felons88/AmodaFamily/releases/latest/download/app-release.apk",
  "notes": f"Kinplora {v}", "mandatory": False},
  open('deploy/version.json', 'w'), indent=2)
PY

git add -A
git commit -m "release $VER (build $BUILD)" || true
git push origin master
git push origin master:refs/heads/main
git tag -a "$TAG" -m "$TAG" || true
git push origin "$TAG"

TOKEN=$(printf "protocol=https\nhost=github.com\n\n" | git credential fill | grep '^password=' | cut -d= -f2)
REL=$(curl -s -X POST "https://api.github.com/repos/Felons88/AmodaFamily/releases" \
  -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" \
  -d "{\"tag_name\":\"$TAG\",\"name\":\"Kinplora $VER\",\"body\":\"Kinplora $VER (build $BUILD)\"}")
RID=$(echo "$REL" | python -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
if [ -z "$RID" ]; then echo "Release create failed: $REL"; exit 1; fi

curl -s -X POST "https://uploads.github.com/repos/Felons88/AmodaFamily/releases/$RID/assets?name=app-release.apk" \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/vnd.android.package-archive" \
  --data-binary "@build/app/outputs/flutter-apk/app-release.apk" | python -c "import json,sys; d=json.load(sys.stdin); print('asset:', d.get('browser_download_url','FAILED'))"

echo "==> $VER released. Installed apps will prompt on next launch."
