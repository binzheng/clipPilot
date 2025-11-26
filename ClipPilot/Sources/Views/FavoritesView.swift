import SwiftUI

struct FavoritesView: View {
    @ObservedObject var historyStore: HistoryStore
    @State private var selectedItem: ClipboardItem?
    @State private var selectedIndex: Int = 0

    let onSelect: (ClipboardItem) -> Void
    let onClose: () -> Void

    var favoriteItems: [ClipboardItem] {
        historyStore.items.filter { $0.isPinned }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hidden buttons for keyboard shortcuts (Cmd+1 through Cmd+9)
            ForEach(1...9, id: \.self) { number in
                Button("") {
                    switchToFavorite(number)
                }
                .keyboardShortcut(KeyEquivalent(Character(String(number))), modifiers: .command)
                .frame(width: 0, height: 0)
                .opacity(0)
            }

            // Header
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16, weight: .semibold))

                Text(NSLocalizedString("favorites", comment: ""))
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Favorites list
            if favoriteItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text(NSLocalizedString("no_favorites", comment: ""))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.controlBackgroundColor))
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(Array(favoriteItems.enumerated()), id: \.element.id) { index, item in
                            FavoriteItemRow(
                                item: item,
                                isSelected: selectedIndex == index,
                                onToggleFavorite: {
                                    historyStore.togglePin(item)
                                },
                                itemNumber: index < 9 ? index + 1 : nil
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIndex = index
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

                                Button(NSLocalizedString("remove_from_favorites", comment: "")) {
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
                Text("\(favoriteItems.count) " + NSLocalizedString("favorites", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("⌘1-9: " + NSLocalizedString("switch_favorites", comment: ""))
                    .font(.caption)
                    .foregroundColor(.secondary)

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

    private func switchToFavorite(_ number: Int) {
        let index = number - 1
        guard index >= 0 && index < favoriteItems.count else {
            return
        }

        selectedIndex = index
        let item = favoriteItems[index]
        selectedItem = item
        onSelect(item)
    }
}

struct FavoriteItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    var onToggleFavorite: (() -> Void)? = nil
    var itemNumber: Int? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Number badge for Cmd+number shortcuts
            if let number = itemNumber {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.yellow)
                    .cornerRadius(12)
            }

            // Item icon
            Image(systemName: iconName)
                .foregroundColor(.secondary)
                .frame(width: 20)

            // Content preview
            VStack(alignment: .leading, spacing: 4) {
                if let text = item.textContent {
                    Text(text)
                        .lineLimit(2)
                        .font(.body)
                } else if item.type == .image {
                    HStack(spacing: 4) {
                        if let imageData = item.thumbnailData ?? item.imageData,
                           let nsImage = NSImage(data: imageData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .cornerRadius(4)
                        }
                        Text(NSLocalizedString("image_item", comment: ""))
                            .foregroundColor(.secondary)
                    }
                }

                // Metadata
                HStack(spacing: 8) {
                    if let appName = item.appName {
                        Text(appName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(timeAgoString(from: item.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Star button (always filled for favorites)
            Button(action: { onToggleFavorite?() }) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
    }

    private var iconName: String {
        switch item.type {
        case .text:
            return "doc.text"
        case .rtf:
            return "doc.richtext"
        case .image:
            return "photo"
        }
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return NSLocalizedString("just_now", comment: "")
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) " + NSLocalizedString("minutes_ago", comment: "")
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) " + NSLocalizedString("hours_ago", comment: "")
        } else {
            let days = Int(interval / 86400)
            return "\(days) " + NSLocalizedString("days_ago", comment: "")
        }
    }
}
