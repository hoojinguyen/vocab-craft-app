import SwiftUI
#if canImport(UIKit)
import UIKit

// MARK: - Native CAEmitterLayer Confetti View (ProMotion 120Hz GPU Particle Engine)
public struct ConfettiParticleView: UIViewRepresentable {
    public init() {}

    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -20)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)

        let colors: [UIColor] = [.systemTeal, .systemGreen, .systemYellow, .systemOrange, .systemPink]
        var cells: [CAEmitterCell] = []

        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 5.0
            cell.velocity = 180
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2.0
            cell.spinRange = 4.0
            cell.scale = 0.08
            cell.scaleRange = 0.04
            cell.contents = createConfettiParticleImage(color: color)?.cgImage
            cells.append(cell)
        }

        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)

        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}

    private func createConfettiParticleImage(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 12, height: 12)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
#endif

// MARK: - SubTopicSessionSummaryView
public struct SubTopicSessionSummaryView: View {
    public let xpEarned: Int
    public let totalQuestions: Int
    public let correctCount: Int
    public let onRestart: () -> Void
    public let onFinish: () -> Void

    @State private var triggerSensoryHaptic = false

    public init(
        xpEarned: Int,
        totalQuestions: Int,
        correctCount: Int,
        onRestart: @escaping () -> Void,
        onFinish: @escaping () -> Void
    ) {
        self.xpEarned = xpEarned
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.onRestart = onRestart
        self.onFinish = onFinish
    }

    private var accuracyPercentage: Int {
        guard totalQuestions > 0 else { return 100 }
        return Int((Double(correctCount) / Double(totalQuestions)) * 100)
    }

    private var isPassed: Bool {
        return accuracyPercentage >= 80
    }

    public var body: some View {
        ZStack {
            #if canImport(UIKit)
            if isPassed {
                // GPU Accelerated Confetti Layer on iOS when passed
                ConfettiParticleView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            #endif

            VStack(spacing: 24) {
                Spacer()

                // Animated Badge (Trophy if Passed, Warning Seal if Failed)
                Image(systemName: isPassed ? "trophy.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(isPassed ? Color.vocabPeach : Color.vocabCoral)
                    .symbolEffect(.bounce, value: triggerSensoryHaptic)

                VStack(spacing: 8) {
                    Text(isPassed ? "CHÚC MỪNG HOÀN THÀNH CHẶNG!" : "CHƯA ĐẠT CHỈ TIÊU (CẦN ≥ 80%)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.vocabInk)
                        .multilineTextAlignment(.center)

                    Text(isPassed ? "Đã tự động đồng bộ từ vựng vào Kho cá nhân" : "Bạn cần đạt tối thiểu 80% độ chính xác để mở chặng tiếp theo")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.vocabMuted)
                        .multilineTextAlignment(.center)
                }

                // Stats Dashboard Grid
                HStack(spacing: 16) {
                    VStack(spacing: 6) {
                        Text("TỔNG THƯỞNG")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.vocabMuted)
                        Text("+\(max(0, xpEarned)) XP")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.vocabMint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vocabHairline, lineWidth: 1)
                    )

                    VStack(spacing: 6) {
                        Text("ĐỘ CHÍNH XÁC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.vocabMuted)
                        Text("\(accuracyPercentage)%")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(isPassed ? Color.vocabMint : Color.vocabCoral)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.vocabSurfaceCard)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.vocabHairline, lineWidth: 1)
                    )
                }

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    if isPassed {
                        Button(action: onFinish) {
                            HStack(spacing: 8) {
                                Text("CHUYỂN CHẶNG TIẾP THEO")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.vocabMint)
                            .foregroundColor(Color.vocabCanvas)
                            .cornerRadius(14)
                        }

                        Button(action: onRestart) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Ôn lại chặng này")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundColor(Color.vocabMuted)
                            .padding(.vertical, 8)
                        }
                    } else {
                        Button(action: onRestart) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("HỌC LẠI CHẶNG NÀY")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.vocabCoral)
                            .foregroundColor(Color.vocabCanvas)
                            .cornerRadius(14)
                        }

                        Button(action: onFinish) {
                            Text("Về trang chủ")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.vocabMuted)
                                .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color.vocabCanvas.ignoresSafeArea())
        .onAppear {
            triggerSensoryHaptic = true
        }
        .sensoryFeedback(isPassed ? .success : .error, trigger: triggerSensoryHaptic)
    }

}
