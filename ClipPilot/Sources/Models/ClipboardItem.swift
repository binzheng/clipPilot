import Foundation
import AppKit
import CoreData

enum ClipboardItemType: String, Codable {
    case text
    case rtf
    case image
}

class ClipboardItem: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var timestamp: Date
    @NSManaged var typeRaw: String
    @NSManaged var textContent: String?
    @NSManaged var rtfData: Data?
    @NSManaged var imageData: Data?
    @NSManaged var thumbnailData: Data?
    @NSManaged var appBundleIdentifier: String?
    @NSManaged var appName: String?
    @NSManaged var isPinned: Bool

    var type: ClipboardItemType {
        get {
            ClipboardItemType(rawValue: typeRaw) ?? .text
        }
        set {
            typeRaw = newValue.rawValue
        }
    }

    var displayText: String {
        switch type {
        case .text:
            return textContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        case .rtf:
            if let rtfData = rtfData,
               let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return ""
        case .image:
            return NSLocalizedString("image_item", comment: "")
        }
    }

    var previewText: String {
        let text = displayText
        if text.count > Constants.previewTextLength {
            return String(text.prefix(Constants.previewTextLength)) + "..."
        }
        return text
    }

    var thumbnail: NSImage? {
        if let thumbnailData = thumbnailData {
            return NSImage(data: thumbnailData)
        }
        return nil
    }

    var image: NSImage? {
        if let imageData = imageData {
            return NSImage(data: imageData)
        }
        return nil
    }

    static func create(
        in context: NSManagedObjectContext,
        type: ClipboardItemType,
        textContent: String? = nil,
        rtfData: Data? = nil,
        imageData: Data? = nil,
        appBundleIdentifier: String? = nil,
        appName: String? = nil
    ) -> ClipboardItem {
        let item = ClipboardItem(context: context)
        item.id = UUID()
        item.timestamp = Date()
        item.type = type
        item.textContent = textContent
        item.rtfData = rtfData
        item.appBundleIdentifier = appBundleIdentifier
        item.appName = appName
        item.isPinned = false

        if let imageData = imageData,
           let image = NSImage(data: imageData) {
            item.imageData = imageData
            item.thumbnailData = image.resized(to: Constants.thumbnailSize)?.tiffRepresentation
        }

        return item
    }
}

extension NSImage {
    func resized(to maxSize: CGFloat) -> NSImage? {
        let originalSize = self.size
        var newSize: NSSize

        if originalSize.width > originalSize.height {
            newSize = NSSize(width: maxSize, height: maxSize * originalSize.height / originalSize.width)
        } else {
            newSize = NSSize(width: maxSize * originalSize.width / originalSize.height, height: maxSize)
        }

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: originalSize),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()

        return newImage
    }
}
