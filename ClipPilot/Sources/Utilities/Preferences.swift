import Foundation
import Combine

class Preferences: ObservableObject {
    static let shared = Preferences()
    private let logger = AppLogger.app

    private let defaults = UserDefaults.standard

    @Published var maxHistoryItems: Int {
        didSet {
            defaults.set(maxHistoryItems, forKey: Constants.PreferenceKeys.maxHistoryItems)
        }
    }

    @Published var maxHistoryDays: Int {
        didSet {
            defaults.set(maxHistoryDays, forKey: Constants.PreferenceKeys.maxHistoryDays)
        }
    }

    @Published var maxTextLength: Int {
        didSet {
            defaults.set(maxTextLength, forKey: Constants.PreferenceKeys.maxTextLength)
        }
    }

    @Published var maxImageSizeKB: Int {
        didSet {
            defaults.set(maxImageSizeKB, forKey: Constants.PreferenceKeys.maxImageSizeKB)
        }
    }

    @Published var excludedApps: [String] {
        didSet {
            defaults.set(excludedApps, forKey: Constants.PreferenceKeys.excludedApps)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Constants.PreferenceKeys.launchAtLogin)
            updateLoginItem()
        }
    }

    @Published var energyOptimizationEnabled: Bool {
        didSet {
            defaults.set(energyOptimizationEnabled, forKey: Constants.PreferenceKeys.energyOptimization)
        }
    }

    private init() {
        let maxHistoryItemsValue = defaults.integer(forKey: Constants.PreferenceKeys.maxHistoryItems)
        self.maxHistoryItems = maxHistoryItemsValue == 0 ? Constants.defaultMaxHistoryItems : maxHistoryItemsValue

        let maxHistoryDaysValue = defaults.integer(forKey: Constants.PreferenceKeys.maxHistoryDays)
        self.maxHistoryDays = maxHistoryDaysValue == 0 ? Constants.defaultMaxHistoryDays : maxHistoryDaysValue

        let maxTextLengthValue = defaults.integer(forKey: Constants.PreferenceKeys.maxTextLength)
        self.maxTextLength = maxTextLengthValue == 0 ? Constants.defaultMaxTextLength : maxTextLengthValue

        let maxImageSizeKBValue = defaults.integer(forKey: Constants.PreferenceKeys.maxImageSizeKB)
        self.maxImageSizeKB = maxImageSizeKBValue == 0 ? Constants.defaultMaxImageSizeKB : maxImageSizeKBValue

        self.excludedApps = defaults.stringArray(forKey: Constants.PreferenceKeys.excludedApps) ?? []
        self.launchAtLogin = defaults.bool(forKey: Constants.PreferenceKeys.launchAtLogin)

        // エネルギー最適化はデフォルトで有効
        let energyOptValue = defaults.object(forKey: Constants.PreferenceKeys.energyOptimization) as? Bool
        self.energyOptimizationEnabled = energyOptValue ?? true
    }

    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                logger.error("Failed to update login item: \(error)")
            }
        }
    }
}

import ServiceManagement
