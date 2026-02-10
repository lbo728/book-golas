import WidgetKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Data Model

struct BookWidgetEntry: TimelineEntry {
    let date: Date
    let bookId: String
    let bookTitle: String
    let bookAuthor: String
    let currentPage: Int
    let totalPages: Int
    let imagePath: String
    let bookStatus: String
    let isEmpty: Bool

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    static let placeholder = BookWidgetEntry(
        date: Date(),
        bookId: "",
        bookTitle: "Book Title",
        bookAuthor: "Author",
        currentPage: 42,
        totalPages: 100,
        imagePath: "",
        bookStatus: "reading",
        isEmpty: false
    )

    static let empty = BookWidgetEntry(
        date: Date(),
        bookId: "",
        bookTitle: "",
        bookAuthor: "",
        currentPage: 0,
        totalPages: 0,
        imagePath: "",
        bookStatus: "",
        isEmpty: true
    )
}

// MARK: - Timeline Provider

struct BookgolasWidgetProvider: TimelineProvider {
    private let appGroupId = "group.com.bookgolas.app"

    func placeholder(in context: Context) -> BookWidgetEntry {
        BookWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BookWidgetEntry) -> Void) {
        let entry = readEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookWidgetEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readEntry() -> BookWidgetEntry {
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            return BookWidgetEntry.empty
        }

        let bookId = defaults.string(forKey: "book_id") ?? ""
        let bookTitle = defaults.string(forKey: "book_title") ?? ""

        if bookTitle.isEmpty {
            return BookWidgetEntry.empty
        }

        return BookWidgetEntry(
            date: Date(),
            bookId: bookId,
            bookTitle: bookTitle,
            bookAuthor: defaults.string(forKey: "book_author") ?? "",
            currentPage: defaults.integer(forKey: "current_page"),
            totalPages: defaults.integer(forKey: "total_pages"),
            imagePath: defaults.string(forKey: "image_path") ?? "",
            bookStatus: defaults.string(forKey: "book_status") ?? "reading",
            isEmpty: false
        )
    }
}

// MARK: - Cover Image Loader

struct CoverImageView: View {
    let imagePath: String
    let size: CGSize

    var body: some View {
        if let data = loadImageData(),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: size.width, height: size.height)
                .overlay(
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: min(size.width, size.height) * 0.4))
                        .foregroundColor(.gray.opacity(0.5))
                )
        }
    }

    private func loadImageData() -> Data? {
        guard !imagePath.isEmpty else { return nil }

        if let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.bookgolas.app"
        ) {
            let fileURL = containerURL.appendingPathComponent(imagePath)
            if let data = try? Data(contentsOf: fileURL) {
                return data
            }
        }

        let url = URL(fileURLWithPath: imagePath)
        if FileManager.default.fileExists(atPath: imagePath),
           let data = try? Data(contentsOf: url) {
            return data
        }

        return nil
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let isSmall: Bool

    var body: some View {
        VStack(spacing: isSmall ? 6 : 8) {
            Image(systemName: "book.closed")
                .font(.system(size: isSmall ? 28 : 32))
                .foregroundColor(.gray.opacity(0.5))
            Text(NSLocalizedString("widget_empty_title", tableName: nil, bundle: .main, value: "Add a book", comment: ""))
                .font(.system(size: isSmall ? 11 : 13, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Small Widget

struct BookgolasSmallWidgetView: View {
    var entry: BookWidgetEntry

    var body: some View {
        if entry.isEmpty {
            EmptyStateView(isSmall: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetURL(URL(string: "bookgolas://book/search"))
        } else {
            VStack(spacing: 8) {
                CoverImageView(
                    imagePath: entry.imagePath,
                    size: CGSize(width: 50, height: 70)
                )

                Text(entry.bookTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)

                CircularProgressView(progress: entry.progress, lineWidth: 4)
                    .frame(width: 36, height: 36)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetURL(URL(string: "bookgolas://book/detail/\(entry.bookId)"))
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let systemImage: String
    let label: String
    let url: URL?

    var body: some View {
        if let url = url {
            Link(destination: url) {
                VStack(spacing: 2) {
                    Image(systemName: systemImage)
                        .font(.system(size: 16))
                        .foregroundColor(.accentColor)
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 36)
            }
        }
    }
}

// MARK: - Medium Widget

struct BookgolasMediumWidgetView: View {
    var entry: BookWidgetEntry

    var body: some View {
        if entry.isEmpty {
            EmptyStateView(isSmall: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetURL(URL(string: "bookgolas://book/search"))
        } else {
            HStack(spacing: 12) {
                CoverImageView(
                    imagePath: entry.imagePath,
                    size: CGSize(width: 60, height: 84)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.bookTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .foregroundColor(.primary)

                    Text(entry.bookAuthor)
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundColor(.secondary)

                    Spacer(minLength: 2)

                    HStack(spacing: 4) {
                        CircularProgressView(progress: entry.progress, lineWidth: 3)
                            .frame(width: 28, height: 28)
                        Text("p.\(entry.currentPage) / \(entry.totalPages)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                VStack(spacing: 10) {
                    QuickActionButton(
                        systemImage: "book.fill",
                        label: NSLocalizedString("widget_action_book", tableName: nil, bundle: .main, value: "Book", comment: ""),
                        url: URL(string: "bookgolas://book/detail/\(entry.bookId)")
                    )
                    QuickActionButton(
                        systemImage: "doc.viewfinder",
                        label: NSLocalizedString("widget_action_scan", tableName: nil, bundle: .main, value: "Scan", comment: ""),
                        url: URL(string: "bookgolas://book/scan/\(entry.bookId)")
                    )
                    QuickActionButton(
                        systemImage: "plus.circle",
                        label: NSLocalizedString("widget_action_add", tableName: nil, bundle: .main, value: "Add", comment: ""),
                        url: URL(string: "bookgolas://book/search")
                    )
                }
                .frame(width: 52)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Widget Entry Views with Container Background

struct BookgolasSmallEntryView: View {
    var entry: BookWidgetEntry

    var body: some View {
        BookgolasSmallWidgetView(entry: entry)
            .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct BookgolasMediumEntryView: View {
    var entry: BookWidgetEntry

    var body: some View {
        BookgolasMediumWidgetView(entry: entry)
            .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definitions

struct BookgolasSmallWidget: Widget {
    let kind: String = "BookgolasSmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookgolasWidgetProvider()) { entry in
            BookgolasSmallEntryView(entry: entry)
        }
        .configurationDisplayName("Bookgolas")
        .description("Reading progress at a glance")
        .supportedFamilies([.systemSmall])
    }
}

struct BookgolasMediumWidget: Widget {
    let kind: String = "BookgolasMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookgolasWidgetProvider()) { entry in
            BookgolasMediumEntryView(entry: entry)
        }
        .configurationDisplayName("Bookgolas")
        .description("Book info with quick actions")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Lock Screen Widgets (Accessory)

@available(iOSApplicationExtension 16.0, *)
struct BookgolasLockScreenCircularView: View {
    var entry: BookWidgetEntry

    var body: some View {
        if !entry.isEmpty {
            Gauge(value: entry.progress) {
                Image(systemName: "book.fill")
                    .font(.system(size: 10))
            } currentValueLabel: {
                Text("\(Int(entry.progress * 100))%")
                    .font(.system(size: 10, weight: .semibold))
            }
            .gaugeStyle(.accessoryCircular)
            .widgetURL(URL(string: "bookgolas://book/detail/\(entry.bookId)"))
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "book.fill")
                    .font(.system(size: 16))
            }
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct BookgolasLockScreenRectangularView: View {
    var entry: BookWidgetEntry

    var body: some View {
        if !entry.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.bookTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 9))
                    Text("p.\(entry.currentPage)/\(entry.totalPages)")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.secondary)
                Gauge(value: entry.progress) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryLinear)
            }
            .widgetURL(URL(string: "bookgolas://book/detail/\(entry.bookId)"))
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bookgolas")
                    .font(.system(size: 12, weight: .semibold))
                Text("No book in progress")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct BookgolasLockScreenInlineView: View {
    var entry: BookWidgetEntry

    var body: some View {
        if !entry.isEmpty {
            let title = entry.bookTitle.count > 10
                ? String(entry.bookTitle.prefix(10)) + "..."
                : entry.bookTitle
            ViewThatFits {
                Label("\u{1F4D6} \(title) p.\(entry.currentPage)/\(entry.totalPages)", systemImage: "")
                Label("p.\(entry.currentPage)/\(entry.totalPages)", systemImage: "book.fill")
            }
            .widgetURL(URL(string: "bookgolas://book/detail/\(entry.bookId)"))
        } else {
            Label("Bookgolas", systemImage: "book.fill")
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct BookgolasLockScreenCircularWidget: Widget {
    let kind: String = "BookgolasLockScreenCircular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookgolasWidgetProvider()) { entry in
            BookgolasLockScreenCircularView(entry: entry)
        }
        .configurationDisplayName("Reading Progress")
        .description("Circular reading progress gauge")
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct BookgolasLockScreenRectangularWidget: Widget {
    let kind: String = "BookgolasLockScreenRectangular"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookgolasWidgetProvider()) { entry in
            BookgolasLockScreenRectangularView(entry: entry)
        }
        .configurationDisplayName("Reading Details")
        .description("Book title and reading progress")
        .supportedFamilies([.accessoryRectangular])
    }
}

@available(iOSApplicationExtension 16.0, *)
struct BookgolasLockScreenInlineWidget: Widget {
    let kind: String = "BookgolasLockScreenInline"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookgolasWidgetProvider()) { entry in
            BookgolasLockScreenInlineView(entry: entry)
        }
        .configurationDisplayName("Reading Inline")
        .description("Inline reading progress text")
        .supportedFamilies([.accessoryInline])
    }
}
