import SwiftUI

public struct SettingsRowView<Content: View>: View {
    public let iconName: String
    public let iconColor: Color
    public let title: String
    public let content: Content

    public init(
        iconName: String,
        iconColor: Color,
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.iconName = iconName
        self.iconColor = iconColor
        self.title = title
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 30, height: 30)
                Image(systemName: iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.vocabInk)
            
            Spacer()
            
            content
        }
    }
}
