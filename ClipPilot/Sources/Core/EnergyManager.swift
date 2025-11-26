import Foundation
import IOKit.ps
import AppKit

/// エネルギー効率を管理し、バッテリー状態に応じてポーリング間隔を最適化
class EnergyManager: ObservableObject {
    private let logger = AppLogger.energy
    static let shared = EnergyManager()

    // ポーリング間隔の設定
    private let normalInterval: TimeInterval = 0.3      // 通常: 300ms
    private let batteryInterval: TimeInterval = 0.5     // バッテリー駆動: 500ms
    private let idleInterval: TimeInterval = 2.0        // アイドル時: 2秒
    private let backgroundInterval: TimeInterval = 1.0  // バックグラウンド: 1秒

    @Published private(set) var currentInterval: TimeInterval = 0.3
    @Published private(set) var isOnBattery: Bool = false
    @Published private(set) var isIdle: Bool = false

    private var idleTimer: Timer?
    private var lastActivityTime: Date = Date()
    private let idleThreshold: TimeInterval = 60.0 // 60秒でアイドル判定

    private init() {
        updateBatteryStatus()
        startMonitoring()
        updatePollingInterval()
    }

    // MARK: - Battery Monitoring

    /// バッテリー状態を取得
    private func updateBatteryStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            isOnBattery = false
            return
        }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            // 電源の種類を確認
            if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
                isOnBattery = (powerSource == kIOPSBatteryPowerValue)
                break
            }
        }
    }

    // MARK: - Idle Detection

    /// アイドル状態を検出
    private func checkIdleState() {
        let idleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .mouseMoved
        )

        // キーボード操作もチェック
        let keyIdleTime = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )

        // 最後のアクティビティからの経過時間
        let minIdleTime = min(idleTime, keyIdleTime)

        isIdle = minIdleTime > idleThreshold
    }

    // MARK: - Monitoring

    /// 監視開始
    private func startMonitoring() {
        // バッテリー状態の監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerSourceChanged),
            name: NSNotification.Name(kIOPSNotifyPowerSource as String),
            object: nil
        )

        // アプリケーションのアクティブ状態監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // アイドル状態のチェックタイマー
        idleTimer = Timer.scheduledTimer(
            withTimeInterval: 10.0,
            repeats: true
        ) { [weak self] _ in
            self?.checkIdleState()
            self?.updatePollingInterval()
        }
    }

    @objc private func powerSourceChanged() {
        updateBatteryStatus()
        updatePollingInterval()
    }

    @objc private func appDidBecomeActive() {
        lastActivityTime = Date()
        isIdle = false
        updatePollingInterval()
    }

    @objc private func appDidResignActive() {
        updatePollingInterval()
    }

    // MARK: - Interval Calculation

    /// 最適なポーリング間隔を計算
    private func updatePollingInterval() {
        let newInterval: TimeInterval

        // エネルギー最適化が無効の場合は常に通常の間隔を使用
        guard Preferences.shared.energyOptimizationEnabled else {
            if currentInterval != normalInterval {
                currentInterval = normalInterval
                logger.info("⚡️ Energy: Optimization disabled, using normal interval: \(normalInterval)s")
            }
            return
        }

        // 優先度: アイドル > バッテリー > バックグラウンド > 通常
        if isIdle {
            // アイドル状態では大幅に間隔を延長
            newInterval = idleInterval
        } else if isOnBattery {
            // バッテリー駆動時は少し延長
            newInterval = batteryInterval
        } else if !NSApp.isActive {
            // バックグラウンド時は中程度に延長
            newInterval = backgroundInterval
        } else {
            // 通常の状態
            newInterval = normalInterval
        }

        if newInterval != currentInterval {
            currentInterval = newInterval

            // ログ出力
            logger.info("⚡️ Energy: Polling interval changed to \(newInterval)s (battery: \(isOnBattery), idle: \(isIdle), active: \(NSApp.isActive))")
        }
    }

    // MARK: - Public API

    /// 現在の推奨ポーリング間隔を取得
    func getOptimalPollingInterval() -> TimeInterval {
        return currentInterval
    }

    /// ユーザーアクティビティを記録（将来の拡張用）
    func recordActivity() {
        lastActivityTime = Date()
        if isIdle {
            isIdle = false
            updatePollingInterval()
        }
    }

    /// エネルギー状態の説明を取得（デバッグ用）
    func getStatusDescription() -> String {
        var status: [String] = []
        status.append("Interval: \(currentInterval)s")
        status.append("Power: \(isOnBattery ? "Battery" : "AC")")
        status.append("State: \(isIdle ? "Idle" : "Active")")
        status.append("App: \(NSApp.isActive ? "Foreground" : "Background")")
        return status.joined(separator: " | ")
    }

    deinit {
        idleTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
