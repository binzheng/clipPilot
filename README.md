# ClipPilot

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue.svg" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Xcode-15.0+-blue.svg" alt="Xcode 15.0+">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
</p>

macOS用の強力なネイティブクリップボードマネージャー。クリップボード履歴の追跡、検索、再利用を簡単に行えます。

## 機能

### コア機能

- 📋 **自動クリップボード監視** - リアルタイムで全てのクリップボード変更を記録（200-500msポーリング）
- 🔍 **強力な検索** - 全文検索でクリップボードアイテムを素早く検索
- 🎯 **スマートフィルタリング** - タイプ別フィルタ（テキスト、RTF、画像）
- 📌 **重要アイテムのピン留め** - よく使うアイテムを上部に固定
- 🎨 **リッチコンテンツ対応** - テキスト、リッチテキスト（RTF）、サムネイル付き画像
- ⚡ **グローバルホットキー** - ⌥⌘V で履歴に即座にアクセス（カスタマイズ可能）
- 🍎 **メニューバー統合** - 最近のアイテムに素早くアクセス

### プライバシーとセキュリティ

- 🔒 **アプリ除外機能** - パスワードマネージャーや機密アプリを監視から除外
- 🛡️ **アクセシビリティ権限** - 透明性のある権限処理とセットアップガイド
- 📝 **プライバシー第一** - 全データはローカル保存、デフォルトでクラウド同期なし

### カスタマイズ

- ⚙️ **設定可能な制限** - 最大アイテム数（デフォルト500）、保持日数（デフォルト30日）
- 📏 **サイズ制限** - 最大テキスト長と画像サイズを設定可能
- 🚀 **ログイン時起動** - macOS起動時に自動起動
- 🌐 **国際化対応** - 日本語と英語のローカライズ

### パフォーマンス

- 💾 **効率的なストレージ** - Core Dataによる自動クリーンアップ
- 🖼️ **画像最適化** - 高速プレビュー用サムネイル生成
- 🧹 **スマートクリーンアップ** - 設定に基づいた古いアイテムの自動削除
- ⚡ **重複検出** - 重複エントリの防止

## 必要環境

- macOS 13.0以降
- Xcode 15.0以降
- Swift 5.9以降
- アクセシビリティ権限（ペースト機能用）

## インストール

### ソースからビルド

1. **リポジトリをクローン**

   ```bash
   cd /path/to/your/projects
   git clone <repository-url>
   cd clipPilot
   ```
2. **Xcodeで開く**

   ```bash
   cd ClipPilot
   open Package.swift
   ```

   または、Xcodeで`ClipPilot/Package.swift`を開く
3. **コード署名を設定**

   - Xcodeでプロジェクトを開く
   - 「ClipPilot」ターゲットを選択
   - 「Signing & Capabilities」に移動
   - 開発チームを選択
   - 「Automatically manage signing」にチェックが入っていることを確認
4. **ビルドして実行**

   - デスティネーションで「My Mac」を選択
   - ⌘R でビルドして実行
   - または Product → Build (⌘B) でビルドのみ

### 初回起動セットアップ

ClipPilotを初めて起動する際、権限の付与が必要です：

1. **アクセシビリティ権限**

   - ClipPilotがアクセシビリティアクセスの許可を求めます
   - 「設定を開く」をクリックしてシステム環境設定へ
   - **セキュリティとプライバシー → プライバシー → アクセシビリティ** に移動
   - 鍵アイコンをクリックして変更を許可
   - リストから「ClipPilot」を見つけてチェックボックスにチェック
   - ClipPilotがリストにない場合は、「+」をクリックして手動で追加
2. **インストールの確認**

   - メニューバーにクリップボードアイコンが表示されます
   - ⌥⌘V を押してポップアップウィンドウを開く
   - テキストをコピーしてクリップボード監視が機能していることを確認

## 使い方

### グローバルホットキー

**⌥⌘V**（Option+Command+V）を押すとClipPilotポップアップウィンドウが開きます。

### メニューバー

メニューバーのクリップボードアイコンをクリックすると：

- 最近のクリップボードアイテムを表示（直近5件）
- 設定にアクセス
- 履歴をクリア
- アプリケーションを終了

### ポップアップウィンドウ

ポップアップウィンドウの機能：

- **検索バー** - クリップボード履歴を検索
- **フィルタボタン** - すべて、テキスト、RTF、画像でフィルタリング
- **アイテムリスト** - 最新順にソート（ピン留めアイテムが最初に表示）
- **コンテキストメニュー** - アイテムを右クリックでオプション表示：
  - ペースト - アクティブなアプリケーションにペースト
  - クリップボードにコピー - ペーストせずにコピー
  - ピン留め/ピン解除 - ピン状態の切り替え
  - 削除 - 履歴から削除

### キーボードショートカット

- **⌥⌘V** - ClipPilotポップアップを開く
- **ESC** - ポップアップウィンドウを閉じる
- **⌘,** - 設定を開く（メニューバーメニューから）
- **⌘Q** - アプリケーションを終了

## 設定

### 設定ウィンドウ

メニューバー → 設定、またはメニューを開いているときに⌘, で設定にアクセスできます。

#### 一般タブ

- **ログイン時に起動** - ログイン時にClipPilotを自動起動
- **グローバルショートカット** - 現在は⌥⌘V に固定（将来のアップデートでカスタマイズ可能）
- **権限** - システムのアクセシビリティ設定へ素早くアクセス

#### 履歴タブ

- **最大履歴アイテム数** - デフォルト：500アイテム
- **最大履歴保持日数** - デフォルト：30日
- **最大テキスト長** - デフォルト：10,000文字
- **最大画像サイズ** - デフォルト：5,000 KB

#### 除外タブ

特定のアプリケーションがアクティブな場合、クリップボード監視を停止します：

**一般的なパスワードマネージャー：**

- キーチェーンアクセス：`com.apple.keychainaccess`
- 1Password：`com.agilebits.onepassword7`
- LastPass：`com.lastpass.LastPass`

**除外の追加方法：**

1. アプリのバンドル識別子を見つける：
   ```bash
   osascript -e 'id of app "AppName"'
   ```
2. 設定 → 除外タブで追加
3. 「追加」ボタンをクリック

## 配布用ビルド

### リリースビルドの作成

1. **アプリケーションをアーカイブ**

   ```bash
   xcodebuild -scheme ClipPilot -configuration Release archive -archivePath build/ClipPilot.xcarchive
   ```
2. **アプリをエクスポート**

   ```bash
   xcodebuild -exportArchive -archivePath build/ClipPilot.xcarchive -exportPath build -exportOptionsPlist exportOptions.plist
   ```
3. **exportOptions.plistを作成**

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>method</key>
       <string>mac-application</string>
       <key>teamID</key>
       <string>YOUR_TEAM_ID</string>
   </dict>
   </plist>
   ```

### コード署名

App Store外で配布する場合：

1. **Developer ID証明書**

   - Apple Developer Portalから Developer ID Application 証明書を取得
   - 証明書をキーチェーンにインストール
2. **アプリケーションに署名**

   ```bash
   codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" ClipPilot.app
   ```
3. **署名を検証**

   ```bash
   codesign --verify --verbose ClipPilot.app
   spctl --assess --verbose ClipPilot.app
   ```
4. **公証（推奨）**

   ```bash
   xcrun notarytool submit ClipPilot.zip --apple-id your@email.com --password app-specific-password --team-id YOUR_TEAM_ID
   ```

### DMGインストーラーの作成（オプション）

`create-dmg`を使用：

1. **create-dmgをインストール**

   ```bash
   brew install create-dmg
   ```
2. **DMGを作成**

   ```bash
   create-dmg \
     --volname "ClipPilot" \
     --volicon "ClipPilot.icns" \
     --window-pos 200 120 \
     --window-size 600 400 \
     --icon-size 100 \
     --icon "ClipPilot.app" 175 120 \
     --hide-extension "ClipPilot.app" \
     --app-drop-link 425 120 \
     "ClipPilot-1.0.dmg" \
     "build/"
   ```

## テスト

### ユニットテストの実行

```bash
swift test
```

Xcodeでは：

- ⌘U で全てのテストを実行
- Product → Test でテストを実行

### テストカバレッジ

テストスイートに含まれるもの：

- 履歴ストア操作（追加、削除、検索、ピン留め）
- 重複検出
- 検索とフィルタリング
- 設定管理
- パフォーマンスベンチマーク

## アーキテクチャ

### プロジェクト構造

```
ClipPilot/
├── Sources/
│   ├── App/
│   │   ├── ClipPilotApp.swift      # SwiftUIアプリエントリーポイント
│   │   └── AppDelegate.swift        # AppKitライフサイクル管理
│   ├── Core/
│   │   ├── ClipboardMonitor.swift   # クリップボードポーリング（200-500ms）
│   │   ├── GlobalHotkeyManager.swift # Carbonベースのホットキー登録
│   │   └── PasteService.swift       # CGEventベースのペーストシミュレーション
│   ├── Models/
│   │   ├── ClipboardItem.swift      # Core Dataエンティティ
│   │   └── HistoryStore.swift       # Core Dataスタックと操作
│   ├── Views/
│   │   ├── PopupWindow.swift        # フローティングウィンドウコンテナ
│   │   ├── PopupSearchView.swift    # メイン検索とリストUI
│   │   ├── HistoryItemRow.swift     # リストアイテムコンポーネント
│   │   ├── MenuBarController.swift  # ステータスバー管理
│   │   └── SettingsView.swift       # 設定UI
│   ├── Utilities/
│   │   ├── Constants.swift          # アプリ全体の定数
│   │   └── Preferences.swift        # UserDefaultsラッパー
│   └── Resources/
│       ├── en.lproj/               # 英語ローカライズ
│       └── ja.lproj/               # 日本語ローカライズ
├── Tests/
│   └── ClipPilotTests/
└── Package.swift
```

### 主要コンポーネント

**ClipboardMonitor**

- `NSPasteboard.general` を300msごとにポーリング
- `changeCount` で変更を検出
- 除外アプリケーションをフィルタリング
- テキスト、RTF、画像データを抽出

**HistoryStore**

- Core Data永続化
- 自動重複検出
- 検索とフィルタリング
- 制限に基づいたクリーンアップ

**GlobalHotkeyManager**

- グローバルホットキー用Carbon Event Manager
- イベントハンドラー登録
- 修飾キーマッピング

**PasteService**

- キーボードシミュレーション用CGEvent API
- 一時的なクリップボード操作
- Cmd+V イベント送信

## プライバシーポリシー

ClipPilotはあなたのプライバシーを尊重します：

- **ローカルストレージのみ** - 全てのクリップボードデータはCore Dataを使用してMacにローカル保存
- **ネットワークアクセスなし** - ClipPilotはインターネットに接続せず、外部へデータを送信しません
- **除外アプリ** - 監視から除外するアプリを設定可能（パスワードマネージャーを推奨）
- **ユーザーコントロール** - いつでも履歴をクリア、重要アイテムをピン留め可能
- **透明性** - オープンソースコード、隠れた機能なし

### 推奨される除外設定

以下を除外することを推奨します：

- パスワードマネージャー（1Password、LastPass、Bitwardenなど）
- 銀行アプリケーション
- 機密情報を扱う全てのアプリ

## 既知の制限事項

1. **アクセシビリティ要件**

   - ペースト機能にアクセシビリティ権限が必要
   - システム環境設定で手動で有効化する必要があります
2. **ポーリングベースの監視**

   - 200-500msのポーリングを使用（macOSにはネイティブなクリップボード変更通知がない）
   - わずかなCPUオーバーヘッド（最小限に最適化済み）
3. **ペーストメカニズム**

   - CGEventシミュレーションに依存（アクセシビリティアクセスが必要）
   - 一部のアプリでは動作しない可能性（合成イベントをブロックするアプリ）
   - 代替手段：「クリップボードにコピー」を使用して手動でペースト
4. **RTFの制限**

   - RTFコンテンツは表示と検索のためプレーンテキストに変換
   - ペースト時は完全なフォーマットを保持
5. **大きな画像**

   - 非常に大きな画像はパフォーマンスに影響する可能性
   - デフォルト制限：5MB（設定可能）
6. **バックグラウンドアプリ**

   - LSUIElementをtrueに設定（Dockアイコンなし）
   - メニューバーまたはホットキーからのみアクセス

## トラブルシューティング

### クリップボードが監視されない

1. ClipPilotが実行中であることを確認（メニューバーにアイコンがあるか確認）
2. アクティブなアプリが除外リストにないか確認
3. 別のアプリからテキストをコピーしてみる

### ペーストが機能しない

1. アクセシビリティ権限が付与されているか確認：
   ```bash
   sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' 'SELECT * FROM access WHERE service="kTCCServiceAccessibility"'
   ```
2. アクセシビリティ設定でClipPilotを削除して再追加
3. 権限付与後にClipPilotを再起動

### ホットキーが機能しない

1. ⌥⌘V を使用している他のアプリとの競合を確認
2. メニューバー → すべてのアイテムを表示 をクリックしてみる
3. Carbon Event Manager権限を確認

### CPUの高使用率

1. Constants.swiftでポーリング間隔を調整（0.3秒から増やす）
2. 設定で最大履歴アイテム数を減らす
3. 履歴から古いアイテムをクリア

## 開発

### 前提条件

```bash
# Xcode Command Line Toolsをインストール
xcode-select --install

# Swiftバージョンを確認
swift --version
```

### ビルド

```bash
# デバッグバージョンをビルド
swift build

# リリースバージョンをビルド
swift build -c release

# ビルドをクリーン
swift package clean
```

### テスト

```bash
# 全てのテストを実行
swift test

# 特定のテストを実行
swift test --filter ClipPilotTests.testAddTextItem
```

### コードスタイル

- Swift API Design Guidelinesに従う
- SwiftLintを使用（オプション、含まれていません）
- 公開APIをドキュメント化
- 関数を集中的かつ簡潔に保つ

## コントリビューション

貢献を歓迎します！以下を行ってください：

1. リポジトリをフォーク
2. 機能ブランチを作成
3. 新機能のテストを記述
4. 全てのテストが通ることを確認
5. プルリクエストを提出

## ライセンス

MITライセンス - 詳細はLICENSEファイルを参照

## 謝辞

- SwiftUIとAppKitで構築
- 永続化にCore Dataを使用
- グローバルホットキーにCarbon Event Managerを使用
- ペースト機能にCGEvent APIを使用

## サポート

問題、質問、提案については：

- GitHubでissueを作成
- 既存のissueで解決策を確認
- 上記のトラブルシューティングセクションを確認

## ロードマップ

将来の機能拡張：

- [ ]  iCloud同期（オプション）
- [ ]  正規表現ベースのテキスト変換
- [ ]  スニペット管理
- [ ]  画像のOCR（Visionフレームワーク）
- [ ]  UIでカスタマイズ可能なホットキー
- [ ]  履歴のインポート/エクスポート
- [ ]  暗号化ストレージオプション
- [ ]  複数クリップボードサポート

---

**macOSの生産性向上のために❤️を込めて作成**
