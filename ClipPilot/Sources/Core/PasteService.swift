import Foundation
import AppKit
import Carbon

class PasteService {
    static let shared = PasteService()
    private let logger = AppLogger.paste

    private init() {}

    func paste(item: ClipboardItem) {
        // Clear and set new content
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }

        case .rtf:
            if let rtfData = item.rtfData {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            // Also set plain text as fallback
            if let rtfData = item.rtfData,
               let attrString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                pasteboard.setString(attrString.string, forType: .string)
            }

        case .image:
            if let imageData = item.imageData,
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        }

        // Wait a bit for clipboard to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.sendPasteCommand()
        }
    }

    private func sendPasteCommand() {
        // Check accessibility permission
        let trusted = AXIsProcessTrusted()
        guard trusted else {
            logger.warning("Accessibility permission not granted")
            return
        }

        // Verify frontmost application exists
        guard NSWorkspace.shared.frontmostApplication != nil else {
            return
        }

        // Send Cmd+V
        let source = CGEventSource(stateID: .combinedSessionState)

        // Key down: V with Command modifier
        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vKeyDown?.flags = .maskCommand

        // Key up: V
        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vKeyUp?.flags = .maskCommand

        // Post events
        vKeyDown?.post(tap: .cghidEventTap)
        usleep(10000) // 10ms
        vKeyUp?.post(tap: .cghidEventTap)
    }

    func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }

        case .rtf:
            if let rtfData = item.rtfData {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            if let rtfData = item.rtfData,
               let attrString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                pasteboard.setString(attrString.string, forType: .string)
            }

        case .image:
            if let imageData = item.imageData,
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
        }
    }
}
