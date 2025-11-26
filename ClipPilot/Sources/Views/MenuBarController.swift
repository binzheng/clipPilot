import AppKit

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
        appDelegate?.toggleMenuPopover(from: sender)
    }
}
