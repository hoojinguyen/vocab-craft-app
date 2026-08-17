import SwiftUI

public struct ReflexCountdownOverlayView: View {
    public let count: Int

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(count > 0 ? "\(count)" : "GO!")
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .foregroundColor(.vocabPeach)
                    .scaleEffect(count > 0 ? 1.0 : 1.3)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: count)
                    .accessibilityLabel(count > 0 ? "Đếm ngược \(count)" : "Bắt đầu!")

                Text("Chuẩn bị nói từ tiếng Anh...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
