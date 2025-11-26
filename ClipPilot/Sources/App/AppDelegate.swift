import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let logger = AppLogger.app

    var menuBarController: MenuBarController?
    var clipboardMonitor: ClipboardMonitor?
    var hotkeyManager: GlobalHotkeyManager?
    var historyStore: HistoryStore!
    var popupWindow: PopupWindow?
    var menuPopover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon to make this a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Initialize Core Data
        historyStore = HistoryStore.shared

        // Initialize Energy Manager (before clipboard monitor)
        _ = EnergyManager.shared

        // Check and request permissions
        checkPermissions()

        // Initialize clipboard monitor
        clipboardMonitor = ClipboardMonitor(historyStore: historyStore)
        clipboardMonitor?.startMonitoring()

        // Initialize menu bar
        menuBarController = MenuBarController(historyStore: historyStore, appDelegate: self)

        // Initialize global hotkey
        hotkeyManager = GlobalHotkeyManager()
        setupHotkey()

        // Clean up old items
        historyStore.cleanupOldItems()

        // Log energy status
        logger.info("⚡️ Energy Manager initialized: \(EnergyManager.shared.getStatusDescription())")
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stopMonitoring()
        hotkeyManager?.unregisterHotkey()
    }

    private func checkPermissions() {
        // Check accessibility permission
        let trusted = AXIsProcessTrusted()

        if !trusted {
            DispatchQueue.main.async {
                self.showPermissionAlert()
            }
        }
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("permission_required", comment: "")
        alert.informativeText = NSLocalizedString("permission_description", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("open_settings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("later", comment: ""))

        if alert.runModal() == .alertFirstButtonReturn {
            // Open System Preferences
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        }
    }

    private func setupHotkey() {
        // Register hotkey for clipboard history (⌥⌘V)
        hotkeyManager?.registerHotkey(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: [.option, .command]
        ) { [weak self] in
            self?.togglePopup()
        }

        // Register hotkey for favorites (⌥⌘F)
        hotkeyManager?.registerHotkey(
            keyCode: UInt32(kVK_ANSI_F),
            modifiers: [.option, .command]
        ) { [weak self] in
            self?.toggleFavoritesPopup()
        }
    }

    func togglePopup() {
        if menuPopover?.isShown == true {
            menuPopover?.close()
            menuPopover = nil
            return
        }

        if popupWindow?.isVisible == true {
            popupWindow?.close()
            popupWindow = nil
        } else {
            showPopup()
        }
    }

    func toggleMenuPopover(from button: NSStatusBarButton) {
        if menuPopover?.isShown == true {
            menuPopover?.close()
            menuPopover = nil
        } else {
            showPopover(from: button)
        }
    }

    func showPopup() {
        // Close any popover to avoid duplicate UI
        if menuPopover?.isShown == true {
            menuPopover?.close()
            menuPopover = nil
        }

        let contentView = MainPopupView(
            historyStore: historyStore,
            onSelect: { [weak self] item in
                self?.pasteItem(item)
                self?.popupWindow?.close()
                self?.popupWindow = nil
            },
            onClose: { [weak self] in
                self?.popupWindow?.close()
                self?.popupWindow = nil
            }
        )

        popupWindow = PopupWindow(contentView: contentView)
        popupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showPopover(from button: NSStatusBarButton) {
        // Close existing popup window if open
        if popupWindow?.isVisible == true {
            popupWindow?.close()
            popupWindow = nil
        }

        let contentView = MainPopupView(
            historyStore: historyStore,
            onSelect: { [weak self] item in
                self?.pasteItem(item)
                self?.menuPopover?.close()
                self?.menuPopover = nil
            },
            onClose: { [weak self] in
                self?.menuPopover?.close()
                self?.menuPopover = nil
            }
        )

        let hostingController = NSHostingController(rootView: contentView)
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = hostingController
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.delegate = self
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .maxY)
        menuPopover = popover

        NSApp.activate(ignoringOtherApps: true)
    }

    private func pasteItem(_ item: ClipboardItem) {
        PasteService.shared.paste(item: item)
    }

    func toggleFavoritesPopup() {
        if menuPopover?.isShown == true {
            menuPopover?.close()
            menuPopover = nil
            return
        }

        if popupWindow?.isVisible == true {
            popupWindow?.close()
            popupWindow = nil
        } else {
            showFavoritesPopup()
        }
    }

    func showFavoritesPopup() {
        // Close existing popup if open
        if popupWindow?.isVisible == true {
            popupWindow?.close()
            popupWindow = nil
        }
        if menuPopover?.isShown == true {
            menuPopover?.close()
            menuPopover = nil
        }

        // Show main popup with favorites tab selected
        let contentView = MainPopupView(
            historyStore: historyStore,
            onSelect: { [weak self] item in
                self?.pasteItem(item)
                self?.popupWindow?.close()
                self?.popupWindow = nil
            },
            onClose: { [weak self] in
                self?.popupWindow?.close()
                self?.popupWindow = nil
            },
            initialTab: .favorites
        )

        popupWindow = PopupWindow(contentView: contentView)
        popupWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func popoverDidClose(_ notification: Notification) {
        menuPopover = nil
    }
}
