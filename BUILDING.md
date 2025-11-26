# ClipPilotのビルド

このガイドでは、ClipPilotをソースからビルドする詳細な手順を説明します。

## クイックスタート

```bash
cd ClipPilot
swift build
swift run
```

## Xcodeでのビルド

1. Xcodeで`Package.swift`を開く
2. 「ClipPilot」スキームを選択
3. デスティネーションで「My Mac」を選択
4. ⌘R でビルドして実行

## コマンドラインビルド

### デバッグビルド

```bash
swift build
```

バイナリは `.build/debug/ClipPilot` に生成されます

### リリースビルド

```bash
swift build -c release
```

バイナリは `.build/release/ClipPilot` に生成されます

### 実行

```bash
# デバッグ
swift run

# リリース
swift run -c release
```

## テスト

### 全テストの実行

```bash
swift test
```

### 特定のテストの実行

```bash
swift test --filter ClipPilotTests.testAddTextItem
```

### Xcodeでテストを実行

⌘U で全てのテストを実行します。

## よくある問題

### コード署名エラー

コード署名エラーが発生した場合：

1. Xcodeでプロジェクトを開く
2. ターゲットを選択
3. 「Signing & Capabilities」に移動
4. 開発チームを選択
5. 「Automatically manage signing」を有効化

### アクセシビリティ権限

アプリが正しく機能するにはアクセシビリティ権限が必要です。初回起動時：

1. 権限ダイアログで「設定を開く」をクリック
2. システム環境設定 → セキュリティとプライバシー → プライバシー → アクセシビリティ に移動
3. リストにClipPilotを追加して有効化

### 依存関係の不足

Swift Package Managerが依存関係の不足を報告する場合：

```bash
swift package resolve
swift package update
```

## 配布用ビルド

### アイコンの生成

配布用のアプリアイコンとDMG背景画像を生成：

```bash
./scripts/create-icons.sh
```

このスクリプトは以下を生成します：
- `ClipPilot/Resources/AppIcon.icns` - アプリケーションアイコン（全サイズ）
- `dmg-resources/background.png` - DMG背景画像
- `dmg-resources/background@2x.png` - Retina DMG背景画像

#### 必要な依存関係

```bash
pip3 install Pillow
```

### 自動DMGビルド（推奨）

配布用DMGファイルを自動的に作成：

```bash
./scripts/build-dmg.sh
```

このスクリプトは以下を実行します：
1. リリースビルドの作成（最適化済み）
2. .appバンドルの構築
   - バイナリ、リソース、Info.plistのコピー
   - CFBundleExecutable変数の解決
   - アプリアイコンの統合
3. コード署名（Hardened Runtime有効）
4. DMGイメージの作成
   - カスタム背景画像
   - インストール用矢印とレイアウト
   - Applicationsフォルダへのシンボリックリンク

生成されるDMG：`ClipPilot-{version}.dmg`

### 手動ビルドプロセス

#### 1. リリースビルドの作成

```bash
swift build -c release --arch arm64 --arch x86_64
```

#### 2. .appバンドルの構築

```bash
APP_NAME="ClipPilot"
APP_BUNDLE="${APP_NAME}.app"

mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# バイナリをコピー
cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Info.plistをコピーして変数を置換
sed "s/\$(EXECUTABLE_NAME)/${APP_NAME}/g" \
  "ClipPilot/Info.plist" > "${APP_BUNDLE}/Contents/Info.plist"

# アイコンをコピー
cp "ClipPilot/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
```

#### 3. コード署名（Hardened Runtime）

エンタイトルメント付きで署名：

```bash
codesign --force --deep --sign - \
  --entitlements "ClipPilot/entitlements.plist" \
  --options runtime \
  "${APP_BUNDLE}"
```

アドホック署名（開発用）：

```bash
codesign --force --deep --sign - --options runtime "${APP_BUNDLE}"
```

プロダクション署名（Developer ID）：

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --entitlements "ClipPilot/entitlements.plist" \
  --options runtime \
  "${APP_BUNDLE}"
```

#### 4. 署名の検証

```bash
codesign --verify --verbose "${APP_BUNDLE}"
codesign --display --verbose=4 "${APP_BUNDLE}"
spctl --assess --verbose "${APP_BUNDLE}"
```

#### 5. DMGの作成

```bash
# 作業用DMGを作成
hdiutil create -size 100m -fs HFS+ -volname "ClipPilot" \
  -format UDRW temp.dmg

# マウント
hdiutil attach temp.dmg

# ファイルをコピー
cp -R "${APP_BUNDLE}" "/Volumes/ClipPilot/"
ln -s /Applications "/Volumes/ClipPilot/Applications"

# 背景画像を設定（オプション）
mkdir "/Volumes/ClipPilot/.background"
cp "dmg-resources/background.png" "/Volumes/ClipPilot/.background/"

# アンマウント
hdiutil detach "/Volumes/ClipPilot"

# 圧縮して最終DMGを作成
hdiutil convert temp.dmg -format UDZO -o "ClipPilot-1.0.3.dmg"
rm temp.dmg
```

### Xcodeでアーカイブ

1. Product → Archive
2. アーカイブが完了するまで待機
3. Window → Organizer
4. アーカイブを選択
5. 「Distribute App」をクリック
6. 配布方法を選択

## 環境要件

- macOS 13.0以降
- Xcode 15.0以降
- Swift 5.9以降
- Command Line Tools: `xcode-select --install`

## ビルド設定

### 最適化レベル

デバッグビルド（デフォルト）：
- 最適化なし
- デバッグシンボル含む
- アサーション有効

リリースビルド：
- 完全な最適化
- デバッグシンボル削除
- アサーション無効

### ビルド設定

Package.swiftの主要な設定：
- プラットフォーム：macOS 13.0以降
- Swift言語バージョン：5.9
- プロダクトタイプ：実行可能ファイル

## トラブルシューティング

### ビルドキャッシュの問題

```bash
swift package clean
rm -rf .build
swift build
```

### Xcode Derived Data

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### 権限の問題

```bash
chmod +x .build/debug/ClipPilot
```

## パフォーマンスプロファイリング

### Time Profiler

1. Product → Profile (⌘I)
2. 「Time Profiler」を選択
3. Recordをクリック

### メモリーリーク

1. Product → Profile (⌘I)
2. 「Leaks」を選択
3. Recordをクリック

## 継続的インテグレーション

### GitHub Actionsの例

```yaml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: swift build -c release
      - name: Test
        run: swift test
```

## 次のステップ

ビルド後：

1. コア機能をテスト（コピー/ペースト）
2. アクセシビリティ権限を確認
3. メニューバー統合を確認
4. グローバルホットキー（⌥⌘V）をテスト
5. ログで警告/エラーを確認

## サポート

ビルドに関する問題：
- GitHubのIssuesを確認
- README.mdのトラブルシューティングセクションを確認
- 環境要件を確認
