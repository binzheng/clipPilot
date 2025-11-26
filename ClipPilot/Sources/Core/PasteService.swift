import Foundation
import AppKit
import Carbon

class PasteService {
    static let shared = PasteService()
    private let logger = AppLogger.paste

    private init() {}

    func paste(item: ClipboardItem) {
        // Copy to clipboard without automatic paste
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

        logger.info("Item copied to clipboard")
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
