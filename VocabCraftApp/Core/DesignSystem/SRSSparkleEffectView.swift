import SwiftUI

public struct SRSSparkleEffectView: View {
    @Binding public var isEmitting: Bool

    @State private var particles: [SparkleParticle] = []

    public init(isEmitting: Binding<Bool>) {
        self._isEmitting = isEmitting
    }

    public var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: "sparkle")
                    .font(.system(size: particle.size, weight: .bold))
                    .foregroundColor(particle.color)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(x: particle.x, y: particle.y)
            }
        }
        .allowsHitTesting(false)
        .task(id: isEmitting) {
            guard isEmitting else { return }
            burst()
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                for idx in particles.indices {
                    particles[idx].opacity = 0
                    particles[idx].scale = 0.1
                }
            }
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            particles.removeAll()
            isEmitting = false
        }
    }

    private func burst() {
        var newParticles: [SparkleParticle] = []
        let colors: [Color] = [.vocabMint, .vocabPeach, .vocabLavender, .vocabCoral]

        for i in 0..<12 {
            let angle = Double.pi * 2 / 12 * Double(i) + Double.random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 40...90)
            let particle = SparkleParticle(
                id: UUID(),
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: CGFloat.random(in: 14...22),
                color: colors[i % colors.count],
                scale: 0.2,
                opacity: 1.0
            )
            newParticles.append(particle)
        }
        particles = newParticles

        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            for idx in particles.indices {
                particles[idx].scale = 1.2
            }
        }
    }
}

struct SparkleParticle: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var scale: CGFloat
    var opacity: Double
}
