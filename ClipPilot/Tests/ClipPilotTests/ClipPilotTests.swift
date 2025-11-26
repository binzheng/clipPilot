import XCTest
@testable import ClipPilot
import CoreData

final class ClipPilotTests: XCTestCase {
    var historyStore: HistoryStore!

    override func setUp() {
        super.setUp()
        historyStore = HistoryStore.shared
        // Clean up before each test
        historyStore.clearAll(excludePinned: false)
    }

    override func tearDown() {
        // Clean up after each test
        historyStore.clearAll(excludePinned: false)
        super.tearDown()
    }

    // MARK: - History Store Tests

    func testAddTextItem() {
        // Given
        let testText = "Test clipboard content"

        // When
        historyStore.addItem(
            type: .text,
            textContent: testText,
            appBundleIdentifier: "com.test.app",
            appName: "Test App"
        )

        // Then
        historyStore.loadItems()
        XCTAssertEqual(historyStore.items.count, 1)
        XCTAssertEqual(historyStore.items.first?.textContent, testText)
        XCTAssertEqual(historyStore.items.first?.type, .text)
        XCTAssertFalse(historyStore.items.first?.isPinned ?? true)
    }

    func testDuplicateSuppression() {
        // Given
        let testText = "Duplicate content"

        // When
        historyStore.addItem(type: .text, textContent: testText)
        let initialCount = historyStore.items.count

        historyStore.addItem(type: .text, textContent: testText)

        // Then
        historyStore.loadItems()
        XCTAssertEqual(historyStore.items.count, initialCount, "Duplicate items should not be added")
    }

    func testTogglePin() {
        // Given
        historyStore.addItem(type: .text, textContent: "Test item")
        historyStore.loadItems()
        guard let item = historyStore.items.first else {
            XCTFail("No item found")
            return
        }

        // When
        let initialPinState = item.isPinned
        historyStore.togglePin(item)
        historyStore.loadItems()

        // Then
        XCTAssertNotEqual(item.isPinned, initialPinState)
    }

    func testDeleteItem() {
        // Given
        historyStore.addItem(type: .text, textContent: "Item to delete")
        historyStore.loadItems()
        guard let item = historyStore.items.first else {
            XCTFail("No item found")
            return
        }

        // When
        historyStore.deleteItem(item)
        historyStore.loadItems()

        // Then
        XCTAssertEqual(historyStore.items.count, 0)
    }

    func testClearAllExcludingPinned() {
        // Given
        historyStore.addItem(type: .text, textContent: "Regular item 1")
        historyStore.addItem(type: .text, textContent: "Regular item 2")
        historyStore.addItem(type: .text, textContent: "Pinned item")

        historyStore.loadItems()
        if let pinnedItem = historyStore.items.first(where: { $0.textContent == "Pinned item" }) {
            historyStore.togglePin(pinnedItem)
        }

        // When
        historyStore.clearAll(excludePinned: true)
        historyStore.loadItems()

        // Then
        XCTAssertEqual(historyStore.items.count, 1)
        XCTAssertTrue(historyStore.items.first?.isPinned ?? false)
    }

    func testClearAll() {
        // Given
        historyStore.addItem(type: .text, textContent: "Item 1")
        historyStore.addItem(type: .text, textContent: "Item 2")
        historyStore.addItem(type: .text, textContent: "Pinned item")

        historyStore.loadItems()
        if let pinnedItem = historyStore.items.last {
            historyStore.togglePin(pinnedItem)
        }

        // When
        historyStore.clearAll(excludePinned: false)
        historyStore.loadItems()

        // Then
        XCTAssertEqual(historyStore.items.count, 0)
    }

    func testSearchItems() {
        // Given
        historyStore.addItem(type: .text, textContent: "Apple pie recipe")
        historyStore.addItem(type: .text, textContent: "Banana bread instructions")
        historyStore.addItem(type: .text, textContent: "Apple juice ingredients")

        // When
        let results = historyStore.searchItems(query: "apple", type: nil)

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.textContent?.localizedCaseInsensitiveContains("apple") ?? false })
    }

    func testFilterByType() {
        // Given
        historyStore.addItem(type: .text, textContent: "Text item")
        historyStore.addItem(type: .rtf, rtfData: Data())

        // When
        let textResults = historyStore.searchItems(query: "", type: .text)

        // Then
        XCTAssertEqual(textResults.count, 1)
        XCTAssertEqual(textResults.first?.type, .text)
    }

    func testMaxLengthEnforcement() {
        // Given
        let longText = String(repeating: "a", count: Preferences.shared.maxTextLength + 100)

        // When
        historyStore.addItem(type: .text, textContent: longText)
        historyStore.loadItems()

        // Then
        XCTAssertEqual(historyStore.items.count, 0, "Items exceeding max length should not be added")
    }

    func testPreviewTextTruncation() {
        // Given
        let longText = String(repeating: "x", count: 200)
        historyStore.addItem(type: .text, textContent: longText)
        historyStore.loadItems()

        guard let item = historyStore.items.first else {
            XCTFail("No item found")
            return
        }

        // When
        let preview = item.previewText

        // Then
        XCTAssertLessThanOrEqual(preview.count, Constants.previewTextLength + 3) // +3 for "..."
        XCTAssertTrue(preview.hasSuffix("..."))
    }

    // MARK: - Preferences Tests

    func testPreferencesDefaults() {
        // Given
        let preferences = Preferences.shared

        // Then
        XCTAssertGreaterThan(preferences.maxHistoryItems, 0)
        XCTAssertGreaterThan(preferences.maxHistoryDays, 0)
        XCTAssertGreaterThan(preferences.maxTextLength, 0)
        XCTAssertGreaterThan(preferences.maxImageSizeKB, 0)
    }

    func testExcludedAppsManagement() {
        // Given
        let preferences = Preferences.shared
        let testApp = "com.test.excluded"

        // When
        preferences.excludedApps.append(testApp)

        // Then
        XCTAssertTrue(preferences.excludedApps.contains(testApp))

        // Cleanup
        preferences.excludedApps.removeAll { $0 == testApp }
        XCTAssertFalse(preferences.excludedApps.contains(testApp))
    }

    // MARK: - ClipboardItem Tests

    func testClipboardItemCreation() {
        // Given
        let context = historyStore.context
        let testText = "Test content"

        // When
        let item = ClipboardItem.create(
            in: context,
            type: .text,
            textContent: testText,
            appBundleIdentifier: "com.test.app",
            appName: "Test App"
        )

        // Then
        XCTAssertNotNil(item.id)
        XCTAssertEqual(item.textContent, testText)
        XCTAssertEqual(item.type, .text)
        XCTAssertFalse(item.isPinned)
        XCTAssertNotNil(item.timestamp)
    }

    func testDisplayText() {
        // Given
        let context = historyStore.context

        // When - Text item
        let textItem = ClipboardItem.create(
            in: context,
            type: .text,
            textContent: "  Test content  "
        )

        // Then
        XCTAssertEqual(textItem.displayText, "Test content")
    }

    // MARK: - Performance Tests

    func testAddManyItemsPerformance() {
        measure {
            for i in 0..<100 {
                historyStore.addItem(type: .text, textContent: "Item \(i)")
            }
        }
    }

    func testSearchPerformance() {
        // Given
        for i in 0..<500 {
            historyStore.addItem(type: .text, textContent: "Test item number \(i)")
        }

        // When/Then
        measure {
            _ = historyStore.searchItems(query: "test", type: nil)
        }
    }
}
