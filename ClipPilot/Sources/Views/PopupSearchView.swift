import SwiftUI

struct PopupSearchView: View {
    @ObservedObject var historyStore: HistoryStore
    @State private var searchText = ""
    @State private var selectedType: ClipboardItemType? = nil
    @State private var selectedItem: ClipboardItem?
    @State private var showFavoritesOnly = false

    let onSelect: (ClipboardItem) -> Void
    let onClose: () -> Void

    var filteredItems: [ClipboardItem] {
        var items = historyStore.searchItems(query: searchText, type: selectedType)
        if showFavoritesOnly {
            items = items.filter { $0.isPinned }
        }
        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // 隠しキーボードショートカット（Cmd+1〜9）をレイアウトに影響しないようゼロサイズで配置
            ForEach(1...9, id: \.self) { number in
                Button("") {
                    selectItemByNumber(number)
                }
                .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: .command)
                .frame(width: 0, height: 0)
                .opacity(0)
            }

            // Search and filter bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField(NSLocalizedString("search_placeholder", comment: ""), text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .frame(height: 24)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()
                    .frame(height: 20)

                // Type filter buttons
                HStack(spacing: 4) {
                    FilterButton(
                        title: NSLocalizedString("favorites", comment: ""),
                        icon: "star.fill",
                        isSelected: showFavoritesOnly
                    ) {
                        showFavoritesOnly.toggle()
                    }

                    Divider()
                        .frame(height: 20)

                    FilterButton(
                        title: NSLocalizedString("all", comment: ""),
                        icon: "doc.on.doc",
                        isSelected: selectedType == nil && !showFavoritesOnly
                    ) {
                        selectedType = nil
                        showFavoritesOnly = false
                    }

                    FilterButton(
                        title: NSLocalizedString("text", comment: ""),
                        icon: "textformat",
                        isSelected: selectedType == .text
                    ) {
                        selectedType = .text
                        showFavoritesOnly = false
                    }

                    FilterButton(
                        title: NSLocalizedString("rtf", comment: ""),
                        icon: "doc.richtext",
                        isSelected: selectedType == .rtf
                    ) {
                        selectedType = .rtf
                        showFavoritesOnly = false
                    }

                    FilterButton(
                        title: NSLocalizedString("image", comment: ""),
                        icon: "photo",
                        isSelected: selectedType == .image
                    ) {
                        selectedType = .image
                        showFavoritesOnly = false
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Items list
            if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text(NSLocalizedString("no_items", comment: ""))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            HistoryItemRow(
                                item: item,
                                isSelected: selectedItem?.id == item.id,
                                onToggleFavorite: {
                                    historyStore.togglePin(item)
                                },
                                itemNumber: index < 9 ? index + 1 : nil
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
                                onSelect(item)
                            }
                            .contextMenu {
                                Button(NSLocalizedString("paste", comment: "")) {
                                    onSelect(item)
                                }

                                Button(NSLocalizedString("copy", comment: "")) {
                                    PasteService.shared.copyToClipboard(item: item)
                                }

                                Divider()

                                Button(item.isPinned ? NSLocalizedString("unpin", comment: "") : NSLocalizedString("pin", comment: "")) {
                                    historyStore.togglePin(item)
                                }

                                Divider()

                                Button(NSLocalizedString("delete", comment: "")) {
                                    historyStore.deleteItem(item)
                                }
                            }
                        }
                    }
                }
                .background(Color(NSColor.controlBackgroundColor))
            }

            Divider()

            // Bottom toolbar
            HStack {
                Text("\(filteredItems.count) " + NSLocalizedString("items", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(NSLocalizedString("clear_all", comment: "")) {
                    showClearConfirmation()
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)

                Button(NSLocalizedString("close", comment: "")) {
                    onClose()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            historyStore.loadItems()
        }
    }

    private func selectItemByNumber(_ number: Int) {
        // Convert 1-based number to 0-based index
        let index = number - 1

        // Check if index is valid
        guard index >= 0 && index < filteredItems.count else {
            return
        }

        // Get the item at the specified index
        let item = filteredItems[index]

        // Select and paste the item
        selectedItem = item
        onSelect(item)
    }

    private func showClearConfirmation() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("clear_confirmation", comment: "")
        alert.informativeText = NSLocalizedString("clear_description", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("clear_all", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("clear_unpinned", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("cancel", comment: ""))

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            historyStore.clearAll(excludePinned: false)
        } else if response == .alertSecondButtonReturn {
            historyStore.clearAll(excludePinned: true)
        }
    }
}

struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}
