import SwiftUI
import AppKit

class PopupWindow: NSWindow {
    init<Content: View>(contentView: Content) {
        // Get screen dimensions
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)

        // Window size (reduced to half width)
        let windowWidth: CGFloat = 300
        let windowHeight: CGFloat = 500

        // Center on screen
        let windowRect = NSRect(
            x: screenRect.midX - windowWidth / 2,
            y: screenRect.midY - windowHeight / 2,
            width: windowWidth,
            height: windowHeight
        )

        super.init(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        self.title = "ClipPilot"
        self.isReleasedWhenClosed = false
        self.level = .floating
        self.contentView = NSHostingView(rootView: contentView)
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.backgroundColor = NSColor.controlBackgroundColor

        // Make window appear above all other windows
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
}
