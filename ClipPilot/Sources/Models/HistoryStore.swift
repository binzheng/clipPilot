import Foundation
import CoreData
import Combine
import AppKit

class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    private let logger = AppLogger.store

    private let persistentContainer: NSPersistentContainer
    @Published var items: [ClipboardItem] = []

    private init() {
        // Setup Core Data model programmatically
        let model = NSManagedObjectModel()

        // ClipboardItem entity
        let entity = NSEntityDescription()
        entity.name = "ClipboardItem"
        entity.managedObjectClassName = NSStringFromClass(ClipboardItem.self)

        // Attributes
        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType
        timestampAttr.isOptional = false

        let typeRawAttr = NSAttributeDescription()
        typeRawAttr.name = "typeRaw"
        typeRawAttr.attributeType = .stringAttributeType
        typeRawAttr.isOptional = false

        let textContentAttr = NSAttributeDescription()
        textContentAttr.name = "textContent"
        textContentAttr.attributeType = .stringAttributeType
        textContentAttr.isOptional = true

        let rtfDataAttr = NSAttributeDescription()
        rtfDataAttr.name = "rtfData"
        rtfDataAttr.attributeType = .binaryDataAttributeType
        rtfDataAttr.isOptional = true

        let imageDataAttr = NSAttributeDescription()
        imageDataAttr.name = "imageData"
        imageDataAttr.attributeType = .binaryDataAttributeType
        imageDataAttr.isOptional = true

        let thumbnailDataAttr = NSAttributeDescription()
        thumbnailDataAttr.name = "thumbnailData"
        thumbnailDataAttr.attributeType = .binaryDataAttributeType
        thumbnailDataAttr.isOptional = true

        let appBundleIdentifierAttr = NSAttributeDescription()
        appBundleIdentifierAttr.name = "appBundleIdentifier"
        appBundleIdentifierAttr.attributeType = .stringAttributeType
        appBundleIdentifierAttr.isOptional = true

        let appNameAttr = NSAttributeDescription()
        appNameAttr.name = "appName"
        appNameAttr.attributeType = .stringAttributeType
        appNameAttr.isOptional = true

        let isPinnedAttr = NSAttributeDescription()
        isPinnedAttr.name = "isPinned"
        isPinnedAttr.attributeType = .booleanAttributeType
        isPinnedAttr.defaultValue = false
        isPinnedAttr.isOptional = false

        entity.properties = [
            idAttr, timestampAttr, typeRawAttr, textContentAttr,
            rtfDataAttr, imageDataAttr, thumbnailDataAttr,
            appBundleIdentifierAttr, appNameAttr, isPinnedAttr
        ]

        model.entities = [entity]

        let container = NSPersistentContainer(name: "ClipPilot", managedObjectModel: model)

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        persistentContainer = container
        loadItems()
    }

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func loadItems() {
        let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ClipboardItem.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)
        ]

        do {
            items = try context.fetch(request)
        } catch {
            logger.error("Failed to fetch items: \(error)")
        }
    }

    func addItem(
        type: ClipboardItemType,
        textContent: String? = nil,
        rtfData: Data? = nil,
        imageData: Data? = nil,
        appBundleIdentifier: String? = nil,
        appName: String? = nil
    ) {
        // Check for duplicates
        if let existing = findDuplicate(
            type: type,
            textContent: textContent,
            rtfData: rtfData,
            imageData: imageData
        ) {
            // Update timestamp and move to top
            existing.timestamp = Date()
            save()
            loadItems()
            return
        }

        // Apply limits
        if let textContent = textContent,
           textContent.count > Preferences.shared.maxTextLength {
            return
        }

        if let imageData = imageData,
           imageData.count > Preferences.shared.maxImageSizeKB * 1024 {
            return
        }

        // Create new item
        _ = ClipboardItem.create(
            in: context,
            type: type,
            textContent: textContent,
            rtfData: rtfData,
            imageData: imageData,
            appBundleIdentifier: appBundleIdentifier,
            appName: appName
        )

        save()
        loadItems()

        // Cleanup if needed
        cleanupIfNeeded()
    }

    private func findDuplicate(
        type: ClipboardItemType,
        textContent: String?,
        rtfData: Data?,
        imageData: Data?
    ) -> ClipboardItem? {
        let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")

        switch type {
        case .text:
            request.predicate = NSPredicate(
                format: "typeRaw == %@ AND textContent == %@",
                type.rawValue,
                textContent ?? ""
            )
        case .rtf:
            // For RTF, compare text representation
            if let rtfData = rtfData,
               let attrString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                let text = attrString.string
                request.predicate = NSPredicate(
                    format: "typeRaw == %@ AND textContent == %@",
                    ClipboardItemType.text.rawValue,
                    text
                )
            }
        case .image:
            // For images, no duplicate detection (too expensive)
            return nil
        }

        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            logger.error("Failed to check for duplicates: \(error)")
            return nil
        }
    }

    func togglePin(_ item: ClipboardItem) {
        item.isPinned.toggle()
        save()
        loadItems()
    }

    func deleteItem(_ item: ClipboardItem) {
        context.delete(item)
        save()
        loadItems()
    }

    func clearAll(excludePinned: Bool = true) {
        let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")

        if excludePinned {
            request.predicate = NSPredicate(format: "isPinned == NO")
        }

        do {
            let items = try context.fetch(request)
            for item in items {
                context.delete(item)
            }
            save()
            loadItems()
        } catch {
            logger.error("Failed to clear items: \(error)")
        }
    }

    func cleanupOldItems() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(
            byAdding: .day,
            value: -Preferences.shared.maxHistoryDays,
            to: Date()
        )!

        let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
        request.predicate = NSPredicate(
            format: "timestamp < %@ AND isPinned == NO",
            cutoffDate as NSDate
        )

        do {
            let items = try context.fetch(request)
            for item in items {
                context.delete(item)
            }
            save()
        } catch {
            logger.error("Failed to cleanup old items: \(error)")
        }
    }

    private func cleanupIfNeeded() {
        let maxItems = Preferences.shared.maxHistoryItems
        let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
        request.predicate = NSPredicate(format: "isPinned == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)]

        do {
            let unpinnedItems = try context.fetch(request)
            if unpinnedItems.count > maxItems {
                let itemsToDelete = unpinnedItems.dropFirst(maxItems)
                for item in itemsToDelete {
                    context.delete(item)
                }
                save()
            }
        } catch {
            logger.error("Failed to cleanup: \(error)")
        }
    }

    func searchItems(query: String, type: ClipboardItemType? = nil) -> [ClipboardItem] {
        if query.isEmpty && type == nil {
            return items
        }

        var predicates: [NSPredicate] = []

        if !query.isEmpty {
            let textPredicate = NSPredicate(format: "textContent CONTAINS[cd] %@", query)
            predicates.append(textPredicate)
        }

        if let type = type {
            let typePredicate = NSPredicate(format: "typeRaw == %@", type.rawValue)
            predicates.append(typePredicate)
        }

        let request = NSFetchRequest<ClipboardItem>(entityName: "ClipboardItem")
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ClipboardItem.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \ClipboardItem.timestamp, ascending: false)
        ]

        do {
            return try context.fetch(request)
        } catch {
            logger.error("Failed to search items: \(error)")
            return []
        }
    }

    private func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                logger.error("Failed to save context: \(error)")
            }
        }
    }
}
