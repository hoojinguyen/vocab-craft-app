import AppIntents
import SwiftUI
#if !WIDGET_EXTENSION && canImport(VocabCraftApp)
import VocabCraftApp
#endif
import WidgetKit

public struct VocabWidgetView: View {
    @Environment(\.widgetFamily) private var family
    public var entry: VocabWidgetEntry

    public init(entry: VocabWidgetEntry) {
        self.entry = entry
    }

    private var lemma: String {
        entry.card?.lemma ?? String(localized: "app.widget.placeholder.lemma")
    }

    private var ipa: String {
        entry.card?.ipa ?? String(localized: "app.widget.placeholder.ipa")
    }

    private var definitionVi: String {
        entry.card?.definitionVi ?? String(localized: "app.widget.placeholder.definition")
    }

    private var exampleEn: String {
        entry.card?.exampleEn ?? String(localized: "app.widget.placeholder.example")
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
                Text(lemma)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Spacer()
                if !ipa.isEmpty {
                    Text(ipa)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(definitionVi)
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
                Text(lemma)
                    .font(.title2)
                    .fontWeight(.bold)

                if !ipa.isEmpty {
                    Text(ipa)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text(definitionVi)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(2)

            if !exampleEn.isEmpty {
                Text(exampleEn)
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
            Text(lemma)
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
        }
    }

    private var accessoryInlineView: some View {
        Text("\(lemma): \(definitionVi)")
            .lineLimit(1)
    }
}
