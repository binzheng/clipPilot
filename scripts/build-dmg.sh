#!/bin/bash

# ClipPilot DMG ビルドスクリプト
# このスクリプトは、ClipPilotをビルドして配布可能なDMGファイルを作成します。

set -e

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}ClipPilot DMG ビルドスクリプト${NC}"
echo "======================================"

# 変数設定
APP_NAME="ClipPilot"
VERSION=${1:-"1.0.0"}
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
TEMP_DMG_DIR="temp-dmg"

# クリーンアップ
echo -e "\n${YELLOW}クリーンアップ中...${NC}"
rm -rf "${APP_BUNDLE}"
rm -rf "${TEMP_DMG_DIR}"
rm -f "${DMG_NAME}"

# リリースビルド
echo -e "\n${YELLOW}リリースビルド中...${NC}"
cd ClipPilot
swift build -c release
cd ..

# .appバンドルの作成
echo -e "\n${YELLOW}.appバンドル作成中...${NC}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# バイナリをコピー
cp "ClipPilot/${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Info.plistをコピーして変数を置換
if [ -f "ClipPilot/Info.plist" ]; then
    # Info.plistの変数を実際の値に置換
    sed "s/\$(EXECUTABLE_NAME)/${APP_NAME}/g" "ClipPilot/Info.plist" > "${APP_BUNDLE}/Contents/Info.plist"
else
    # Info.plistが存在しない場合は作成
    cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.clippilot.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
EOF
fi

# リソースをコピー
if [ -d "ClipPilot/Sources/Resources" ]; then
    cp -r "ClipPilot/Sources/Resources/" "${APP_BUNDLE}/Contents/Resources/"
fi

# 実行権限を付与
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# コード署名（アドホック署名）
echo -e "\n${YELLOW}コード署名中...${NC}"
if [ -f "ClipPilot/entitlements.plist" ]; then
    codesign --force --deep --sign - --entitlements "ClipPilot/entitlements.plist" --options runtime "${APP_BUNDLE}"
else
    codesign --force --deep --sign - --options runtime "${APP_BUNDLE}"
fi

# 署名の検証
echo -e "${YELLOW}署名を検証中...${NC}"
codesign --verify --verbose "${APP_BUNDLE}" && echo -e "${GREEN}✓ 署名検証成功${NC}"

echo -e "${GREEN}✓ .appバンドル作成完了${NC}"

# DMG作成
echo -e "\n${YELLOW}DMG作成中...${NC}"

# 一時ディレクトリを作成
mkdir -p "${TEMP_DMG_DIR}"
cp -r "${APP_BUNDLE}" "${TEMP_DMG_DIR}/"

# Applicationsフォルダへのシンボリックリンクを作成
ln -s /Applications "${TEMP_DMG_DIR}/Applications"

# 読み書き可能なDMGを一時的に作成
TEMP_DMG="temp-${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${TEMP_DMG_DIR}" \
    -ov -format UDRW \
    "${TEMP_DMG}"

# DMGをマウント
echo -e "${YELLOW}DMGレイアウトを設定中...${NC}"
MOUNT_DIR="/Volumes/${APP_NAME}"
hdiutil attach "${TEMP_DMG}" -readwrite -noverify -noautoopen

# AppleScriptでウィンドウレイアウトを設定
sleep 2
osascript <<EOF
tell application "Finder"
    tell disk "${APP_NAME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 920, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "${APP_BUNDLE}" of container window to {140, 180}
        set position of item "Applications" of container window to {380, 180}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# DMGをデタッチ
sync
hdiutil detach "${MOUNT_DIR}"

# 圧縮されたDMGに変換
echo -e "${YELLOW}DMGを圧縮中...${NC}"
hdiutil convert "${TEMP_DMG}" -format UDZO -o "${DMG_NAME}"

# 一時ファイルをクリーンアップ
rm -rf "${TEMP_DMG_DIR}"
rm -f "${TEMP_DMG}"

echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}✓ ビルド完了！${NC}"
echo -e "${GREEN}DMGファイル: ${DMG_NAME}${NC}"
echo -e "${GREEN}=====================================${NC}"

# DMGサイズを表示
DMG_SIZE=$(du -h "${DMG_NAME}" | cut -f1)
echo -e "ファイルサイズ: ${DMG_SIZE}"
