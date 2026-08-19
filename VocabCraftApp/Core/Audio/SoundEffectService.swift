import AudioToolbox
import Foundation

public protocol SoundEffectServiceProtocol: Sendable {
    func playSuccessChime()
}

public final class SoundEffectService: SoundEffectServiceProtocol, @unchecked Sendable {
    public static let shared = SoundEffectService()

    public init() {}

    public func playSuccessChime() {
        #if os(iOS)
        // 1054 is the standard pleasant UI acknowledgment chime, or 1057 / 1394
        AudioServicesPlaySystemSound(1054)
        #endif
    }
}
