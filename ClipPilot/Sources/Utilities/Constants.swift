import Foundation
import Carbon.HIToolbox

// Virtual key codes
let kVK_ANSI_V: UInt16 = 0x09
let kVK_ANSI_C: UInt16 = 0x08
let kVK_ANSI_F: UInt16 = 0x03

struct Constants {
    // Polling interval
    static let pollingInterval: TimeInterval = 0.3

    // History limits
    static let defaultMaxHistoryItems = 500
    static let defaultMaxHistoryDays = 30

    // Text limits
    static let defaultMaxTextLength = 10000
    static let previewTextLength = 100

    // Image limits
    static let defaultMaxImageSizeKB = 5000
    static let thumbnailSize: CGFloat = 64

    // Preferences keys
    struct PreferenceKeys {
        static let maxHistoryItems = "maxHistoryItems"
        static let maxHistoryDays = "maxHistoryDays"
        static let maxTextLength = "maxTextLength"
        static let maxImageSizeKB = "maxImageSizeKB"
        static let excludedApps = "excludedApps"
        static let launchAtLogin = "launchAtLogin"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let energyOptimization = "energyOptimization"
    }
}
