import SwiftUI

struct HistoryItemRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    var onToggleFavorite: (() -> Void)? = nil
    var itemNumber: Int? = nil  // For Cmd+number shortcuts

    private var typeIcon: String {
        switch item.type {
        case .text:
            return "doc.text"
        case .rtf:
            return "doc.richtext"
        case .image:
            return "photo"
        }
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.timestamp, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            // Number badge for Cmd+number shortcuts
            if let number = itemNumber, number <= 9 {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.accentColor)
                    .cornerRadius(4)
            } else if item.isPinned {
                // Pin indicator for items without numbers
                Image(systemName: "pin.fill")
                    .foregroundColor(.accentColor)
                    .font(.caption)
                    .frame(width: 20)
            } else {
                Color.clear.frame(width: 20)
            }

            // Type icon or thumbnail
            if item.type == .image, let thumbnail = item.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .cornerRadius(4)
            } else {
                Image(systemName: typeIcon)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 40, height: 40)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.previewText)
                    .lineLimit(2)
                    .font(.body)

                HStack(spacing: 8) {
                    if let appName = item.appName {
                        Text(appName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Favorite button
            Button(action: {
                onToggleFavorite?()
            }) {
                Image(systemName: item.isPinned ? "star.fill" : "star")
                    .foregroundColor(item.isPinned ? .yellow : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(item.isPinned ? NSLocalizedString("remove_from_favorites", comment: "") : NSLocalizedString("add_to_favorites", comment: ""))

            // Type badge
            Text(item.type.rawValue.uppercased())
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}
