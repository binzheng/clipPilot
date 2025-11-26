import AppKit
import SwiftUI

class MenuBarController {
    private var statusItem: NSStatusItem?
    private let historyStore: HistoryStore
    private weak var appDelegate: AppDelegate?

    init(historyStore: HistoryStore, appDelegate: AppDelegate) {
        self.historyStore = historyStore
        self.appDelegate = appDelegate
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipPilot")
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked(_:))
            button.target = self
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        // Show popover with clipboard history
        appDelegate?.toggleMenuPopover(from: sender)
    }

    func updateMenu() {
        // Menu no longer used - keeping method for compatibility
    }

    @objc private func pasteItem(_ sender: NSMenuItem) {
        if let item = sender.representedObject as? ClipboardItem {
            PasteService.shared.paste(item: item)
        }
    }

    @objc private func showAllItems() {
        appDelegate?.showPopup()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("clear_confirmation", comment: "")
        alert.informativeText = NSLocalizedString("clear_description", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("clear_all", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel", comment: ""))

        if alert.runModal() == .alertFirstButtonReturn {
            historyStore.clearAll(excludePinned: true)
            updateMenu()
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
