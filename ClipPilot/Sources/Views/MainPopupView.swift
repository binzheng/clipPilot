import SwiftUI

struct MainPopupView: View {
    @ObservedObject var historyStore: HistoryStore
    @State private var selectedTab: Tab

    let onSelect: (ClipboardItem) -> Void
    let onClose: () -> Void

    enum Tab {
        case history
        case favorites
    }

    init(historyStore: HistoryStore, onSelect: @escaping (ClipboardItem) -> Void, onClose: @escaping () -> Void, initialTab: Tab = .history) {
        self.historyStore = historyStore
        self.onSelect = onSelect
        self.onClose = onClose
        self._selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(
                    title: NSLocalizedString("history", comment: ""),
                    icon: "clock.fill",
                    isSelected: selectedTab == .history
                ) {
                    selectedTab = .history
                }

                TabButton(
                    title: NSLocalizedString("favorites", comment: ""),
                    icon: "star.fill",
                    isSelected: selectedTab == .favorites
                ) {
                    selectedTab = .favorites
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Content area
            Group {
                if selectedTab == .history {
                    PopupSearchView(
                        historyStore: historyStore,
                        onSelect: onSelect,
                        onClose: onClose
                    )
                } else {
                    FavoritesView(
                        historyStore: historyStore,
                        onSelect: onSelect,
                        onClose: onClose
                    )
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}
