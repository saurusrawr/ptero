#!/bin/bash
set -e

WEB="$1"
NAME="$2"
ICON="$3"

WORKDIR="/root/web2apk"
TEMPLATE="$WORKDIR/template"
OUT="$WORKDIR/build/$NAME"
FINAL="$WORKDIR/output/$NAME.apk"

mkdir -p "$WORKDIR/build" "$WORKDIR/output"
rm -rf "$OUT"
cp -r "$TEMPLATE" "$OUT"

# ganti web url
sed -i "s|{{WEB_URL}}|$WEB|g" \
"$OUT/app/src/main/java"/*/*/MainActivity.java

# ganti nama apk
sed -i "s|app_name_placeholder|$NAME|g" \
"$OUT/app/src/main/res/values/strings.xml"

# icon handling
if [ "$ICON" = "no" ]; then
  echo "[INFO] Mengambil favicon website..."
  DOMAIN=$(echo "$WEB" | awk -F/ '{print $3}')
  wget -q "https://www.google.com/s2/favicons?domain=$DOMAIN&sz=256" -O /tmp/icon.png
else
  echo "[INFO] Download icon custom..."
  wget -q "$ICON" -O /tmp/icon.png
fi

# replace icon
for d in mipmap-hdpi mipmap-mdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
  cp /tmp/icon.png "$OUT/app/src/main/res/$d/ic_launcher.png"
done

# build
cd "$OUT"
chmod +x gradlew
./gradlew assembleRelease

APK="$OUT/app/build/outputs/apk/release/app-release.apk"

if [ ! -f "$APK" ]; then
  echo "BUILD_FAILED"
  exit 1
fi

cp "$APK" "$FINAL"
echo "BUILD_SUCCESS"
