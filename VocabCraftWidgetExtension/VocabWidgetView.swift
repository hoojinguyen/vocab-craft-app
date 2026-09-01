import AppIntents
import SwiftUI
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
@testable import VocabCraftApp
#endif
import WidgetKit

public struct VocabWidgetEntry: TimelineEntry {
    public let date: Date
    public let lemma: String
    public let ipaUs: String
    public let definitionVi: String
    public let exampleEn: String
    public let masteryLevel: Int

    public init(
        date: Date = Date(),
        lemma: String,
        ipaUs: String = "",
        definitionVi: String,
        exampleEn: String = "",
        masteryLevel: Int = 0
    ) {
        self.date = date
        self.lemma = lemma
        self.ipaUs = ipaUs
        self.definitionVi = definitionVi
        self.exampleEn = exampleEn
        self.masteryLevel = masteryLevel
    }
}

public struct VocabWidgetView: View {
    @Environment(\.widgetFamily) private var family
    public var entry: VocabWidgetEntry

    public init(entry: VocabWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        #if os(iOS)
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryInline:
            accessoryInlineView
        #endif
        default:
            mediumWidgetView
        }
    }

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.lemma)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Spacer()
                if !entry.ipaUs.isEmpty {
                    Text(entry.ipaUs)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(entry.definitionVi)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(2)

            Spacer()

            HStack(spacing: 8) {
                Button(intent: NextWordIntent()) {
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(intent: MarkLearnedIntent()) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
    }

    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.lemma)
                    .font(.title2)
                    .fontWeight(.bold)

                if !entry.ipaUs.isEmpty {
                    Text(entry.ipaUs)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: String(localized: "app.widget.level_format", defaultValue: "Level %lld"), entry.masteryLevel))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }

            Text(entry.definitionVi)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)

            if !entry.exampleEn.isEmpty {
                Text(entry.exampleEn)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            HStack {
                Button(intent: NextWordIntent()) {
                    Label(LocalizedStringKey("app.widget.next"), systemImage: "arrow.forward.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(intent: MarkLearnedIntent()) {
                    Label(LocalizedStringKey("app.widget.mastered"), systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
    }

    private var accessoryCircularView: some View {
        VStack(spacing: 2) {
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 16))
            Text(entry.lemma)
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
        }
    }

    private var accessoryInlineView: some View {
        Text("\(entry.lemma): \(entry.definitionVi)")
            .lineLimit(1)
    }
}
