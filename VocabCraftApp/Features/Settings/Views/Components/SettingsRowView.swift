import SwiftUI

public struct SettingsRowView<Content: View>: View {
    public let iconName: String
    public let iconColor: Color
    public let title: LocalizedStringKey
    public let subtitle: LocalizedStringKey?
    public let content: Content

    public init(
        iconName: String,
        iconColor: Color,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.vocabInk)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.vocabMuted)
                }
            }
            
            Spacer(minLength: 8)
            
            content
        }
        .padding(.vertical, 2)
    }
}
