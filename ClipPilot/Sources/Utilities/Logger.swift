import Foundation
import os.log

/// アプリケーション全体で使用する統一ログシステム
/// os.Loggerを使用して構造化ログを提供
struct AppLogger {
    private let logger: Logger

    // MARK: - Subsystems

    private static let subsystem = "com.clippilot"

    // MARK: - Categories

    /// クリップボード監視とデータ処理
    static let clipboard = AppLogger(category: "clipboard")

    /// エネルギー管理とバッテリー最適化
    static let energy = AppLogger(category: "energy")

    /// ペースト操作とキーボード制御
    static let paste = AppLogger(category: "paste")

    /// ホットキーとショートカット
    static let hotkey = AppLogger(category: "hotkey")

    /// データストアと永続化
    static let store = AppLogger(category: "store")

    /// UI操作とビュー
    static let ui = AppLogger(category: "ui")

    /// アプリケーションライフサイクル
    static let app = AppLogger(category: "app")

    // MARK: - Initialization

    private init(category: String) {
        self.logger = Logger(subsystem: Self.subsystem, category: category)
    }

    // MARK: - Logging Methods

    /// デバッグ情報（開発時のみ）
    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    /// 一般的な情報ログ
    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    /// 注意が必要な状況
    func notice(_ message: String) {
        logger.notice("\(message, privacy: .public)")
    }

    /// 警告（エラーではないが問題の可能性）
    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    /// エラー（回復可能）
    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }

    /// クリティカルエラー（システムに重大な影響）
    func critical(_ message: String) {
        logger.critical("\(message, privacy: .public)")
    }

    /// システム障害
    func fault(_ message: String) {
        logger.fault("\(message, privacy: .public)")
    }
}
