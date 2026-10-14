#!/bin/bash
# Build Halo.app (không cần Xcode, chỉ Command Line Tools). Chạy: ./build.sh && open Halo.app
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release
.build/release/Halo --selftest
APP=Halo.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Halo "$APP/Contents/MacOS/Halo"
# Icon: app tự vẽ PNG 1024px -> iconset đủ cỡ -> .icns
TMP=$(mktemp -d); .build/release/Halo --icon "$TMP/icon.png"
mkdir "$TMP/Halo.iconset"
for s in 16 32 128 256 512; do
  sips -z $s $s "$TMP/icon.png" --out "$TMP/Halo.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$TMP/icon.png" --out "$TMP/Halo.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$TMP/Halo.iconset" -o "$APP/Contents/Resources/Halo.icns"
rm -rf "$TMP"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>local.halo.ring</string>
  <key>CFBundleName</key><string>Halo</string>
  <key>CFBundleExecutable</key><string>Halo</string>
  <key>CFBundleIconFile</key><string>Halo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.2.0</string>
  <key>CFBundleVersion</key><string>2</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
# Ký bằng chứng chỉ tự ký CỐ ĐỊNH trong login keychain: chữ ký giữ nguyên qua các lần build
# -> macOS nhớ quyền Accessibility, không phải bật lại. Lần đầu tự tạo chứng chỉ (chỉ dùng trên máy này).
# Gỡ: Keychain Access -> xoá "Halo Local Signing".
IDENTITY="Halo Local Signing"
if ! security find-certificate -c "$IDENTITY" >/dev/null 2>&1; then
  T=$(mktemp -d)
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=$IDENTITY" \
    -addext "keyUsage=critical,digitalSignature" -addext "extendedKeyUsage=critical,codeSigning" \
    -keyout "$T/key.pem" -out "$T/cert.pem" 2>/dev/null
  openssl pkcs12 -export -inkey "$T/key.pem" -in "$T/cert.pem" -out "$T/id.p12" -passout pass:halo -name "$IDENTITY" 2>/dev/null \
    || openssl pkcs12 -export -legacy -inkey "$T/key.pem" -in "$T/cert.pem" -out "$T/id.p12" -passout pass:halo -name "$IDENTITY"
  security import "$T/id.p12" -k ~/Library/Keychains/login.keychain-db -P halo -T /usr/bin/codesign >/dev/null
  rm -rf "$T"
  echo "Đã tạo chứng chỉ ký: $IDENTITY"
fi
codesign --force --sign "$IDENTITY" "$APP"
echo "OK: $(pwd)/$APP"
