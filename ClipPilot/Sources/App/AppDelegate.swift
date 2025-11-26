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
        NSApp.setActivationPolicy(.accessory)

        historyStore = HistoryStore.shared
        _ = EnergyManager.shared

        clipboardMonitor = ClipboardMonitor(historyStore: historyStore)
        clipboardMonitor?.startMonitoring()

        menuBarController = MenuBarController(historyStore: historyStore, appDelegate: self)

        hotkeyManager = GlobalHotkeyManager()
        setupHotkey()

        historyStore.cleanupOldItems()
        logger.info("⚡️ Energy Manager initialized: \(EnergyManager.shared.getStatusDescription())")
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stopMonitoring()
        hotkeyManager?.unregisterHotkey()
    }

    private func setupHotkey() {
        hotkeyManager?.registerHotkey(
            keyCode: UInt32(kVK_ANSI_V),
            modifiers: [.option, .command]
        ) { [weak self] in
            self?.togglePopup()
        }

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
        hostingController.view.wantsLayer = true
        let backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)
        hostingController.view.layer?.backgroundColor = backgroundColor.cgColor

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
        if popupWindow?.isVisible == true {
            popupWindow?.close()
            popupWindow = nil
        }
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
