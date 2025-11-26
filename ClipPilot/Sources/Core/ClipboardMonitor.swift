import Foundation
import AppKit
import Combine

class ClipboardMonitor {
    private let logger = AppLogger.clipboard

    private let pasteboard = NSPasteboard.general
    private var timer: Timer?
    private var lastChangeCount: Int
    private let historyStore: HistoryStore
    private var lastProcessedContent: String?
    private let energyManager = EnergyManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
        self.lastChangeCount = pasteboard.changeCount

        // エネルギーマネージャーの間隔変更を監視
        energyManager.$currentInterval
            .sink { [weak self] _ in
                self?.restartMonitoring()
            }
            .store(in: &cancellables)
    }

    func startMonitoring() {
        // 最適なポーリング間隔でタイマー開始
        let interval = energyManager.getOptimalPollingInterval()

        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            self?.checkPasteboard()
        }

        logger.info("📋 Clipboard monitoring started with interval: \(interval)s")
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        logger.info("📋 Clipboard monitoring stopped")
    }

    private func restartMonitoring() {
        guard timer != nil else { return }
        startMonitoring()
    }

    private func checkPasteboard() {
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        // Get active application
        let activeApp = NSWorkspace.shared.frontmostApplication
        let appBundleIdentifier = activeApp?.bundleIdentifier
        let appName = activeApp?.localizedName

        // Check if app is excluded
        if let bundleId = appBundleIdentifier,
           Preferences.shared.excludedApps.contains(bundleId) {
            return
        }

        // Process clipboard content
        processClipboardContent(
            appBundleIdentifier: appBundleIdentifier,
            appName: appName
        )
    }

    private func processClipboardContent(
        appBundleIdentifier: String?,
        appName: String?
    ) {
        // Check for image
        if let imageData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData),
           let pngData = image.pngData() {

            // Check size limit
            let sizeKB = pngData.count / 1024
            if sizeKB <= Preferences.shared.maxImageSizeKB {
                historyStore.addItem(
                    type: .image,
                    imageData: pngData,
                    appBundleIdentifier: appBundleIdentifier,
                    appName: appName
                )
            }
            return
        }

        // Check for RTF
        if let rtfData = pasteboard.data(forType: .rtf) {
            historyStore.addItem(
                type: .rtf,
                rtfData: rtfData,
                appBundleIdentifier: appBundleIdentifier,
                appName: appName
            )
            return
        }

        // Check for plain text
        if let text = pasteboard.string(forType: .string),
           !text.isEmpty {

            // Avoid adding the same content repeatedly
            if text == lastProcessedContent {
                return
            }
            lastProcessedContent = text

            // Check length limit
            if text.count <= Preferences.shared.maxTextLength {
                historyStore.addItem(
                    type: .text,
                    textContent: text,
                    appBundleIdentifier: appBundleIdentifier,
                    appName: appName
                )
            }
        }
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
