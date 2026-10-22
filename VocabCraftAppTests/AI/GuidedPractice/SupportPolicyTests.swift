import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Support Policy Tests")
struct SupportPolicyTests {
    private let policy = SupportPolicy()
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeExposure(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        wordIds: [Int64] = [101],
        level: PracticeSupportLevel = .lexical,
        origin: SupportOrigin = .learnerRequested,
        presentedAt: Date,
        channel: PracticePresentationChannel = .visual
    ) -> SupportExposure {
        SupportExposure(
            id: id,
            sessionId: sessionId,
            turnId: UUID(),
            wordIds: wordIds,
            level: level,
            origin: origin,
            contentSnapshot: "test scaffolding",
            presentedAt: presentedAt,
            channel: channel
        )
    }

    @Test("nextLevel advances sequentially across support tiers")
    func nextLevelProgression() {
        #expect(policy.nextLevel(current: .none) == .intent)
        #expect(policy.nextLevel(current: .intent) == .lexical)
        #expect(policy.nextLevel(current: .lexical) == .frame)
        #expect(policy.nextLevel(current: .frame) == .model)
        #expect(policy.nextLevel(current: .model) == .model)
    }

    @Test("nextLevel with requestFullModel jumps straight to model")
    func requestFullModelJumpsToModel() {
        #expect(policy.nextLevel(current: .none, requestFullModel: true) == .model)
        #expect(policy.nextLevel(current: .intent, requestFullModel: true) == .model)
        #expect(policy.nextLevel(current: .lexical, requestFullModel: true) == .model)
        #expect(policy.nextLevel(current: .frame, requestFullModel: true) == .model)
        #expect(policy.nextLevel(current: .model, requestFullModel: true) == .model)
    }

    @Test("retryLevel fades support down by one tier")
    func retryLevelFadesOneStep() {
        #expect(policy.retryLevel(afterSuccessful: .model) == .frame)
        #expect(policy.retryLevel(afterSuccessful: .frame) == .lexical)
        #expect(policy.retryLevel(afterSuccessful: .lexical) == .intent)
        #expect(policy.retryLevel(afterSuccessful: .intent) == .none)
        #expect(policy.retryLevel(afterSuccessful: .none) == .none)
    }

    @Test("successfulFrameRetryStillPrimed verifies fade and residual priming")
    func successfulFrameRetryStillPrimed() {
        let attemptStart = baseDate.addingTimeInterval(120)
        let earlierModel = [
            makeExposure(
                wordIds: [101],
                level: .model,
                presentedAt: baseDate.addingTimeInterval(30)
            )
        ]

        #expect(policy.retryLevel(afterSuccessful: .frame) == .lexical)
        #expect(policy.isPrimed(wordId: 101, exposures: earlierModel, uncertainWordIds: [], before: attemptStart))
    }

    @Test("exposure presented at or after attempt start does not prime current attempt")
    func exposureAtOrAfterAttemptStartDoesNotPrime() {
        let attemptStart = baseDate.addingTimeInterval(100)
        let concurrentExposure = [
            makeExposure(
                wordIds: [101],
                level: .model,
                presentedAt: attemptStart
            ),
            makeExposure(
                wordIds: [101],
                level: .lexical,
                presentedAt: attemptStart.addingTimeInterval(10)
            )
        ]

        #expect(!policy.isPrimed(wordId: 101, exposures: concurrentExposure, uncertainWordIds: [], before: attemptStart))
    }

    @Test("intent and none exposure tiers do not prime target word")
    func intentAndNoneLevelsDoNotPrime() {
        let attemptStart = baseDate.addingTimeInterval(60)
        let nonPrimingExposures = [
            makeExposure(
                wordIds: [101],
                level: .none,
                presentedAt: baseDate.addingTimeInterval(10)
            ),
            makeExposure(
                wordIds: [101],
                level: .intent,
                presentedAt: baseDate.addingTimeInterval(20)
            )
        ]

        #expect(!policy.isPrimed(wordId: 101, exposures: nonPrimingExposures, uncertainWordIds: [], before: attemptStart))
    }

    @Test("lexical, frame, and model exposure tiers prime target word")
    func lexicalFrameModelPrime() {
        let attemptStart = baseDate.addingTimeInterval(100)

        let lexicalExp = [makeExposure(wordIds: [101], level: .lexical, presentedAt: baseDate.addingTimeInterval(10))]
        let frameExp = [makeExposure(wordIds: [101], level: .frame, presentedAt: baseDate.addingTimeInterval(10))]
        let modelExp = [makeExposure(wordIds: [101], level: .model, presentedAt: baseDate.addingTimeInterval(10))]

        #expect(policy.isPrimed(wordId: 101, exposures: lexicalExp, uncertainWordIds: [], before: attemptStart))
        #expect(policy.isPrimed(wordId: 101, exposures: frameExp, uncertainWordIds: [], before: attemptStart))
        #expect(policy.isPrimed(wordId: 101, exposures: modelExp, uncertainWordIds: [], before: attemptStart))
    }

    @Test("uncertainWordIds triggers conservative priming even without prior exposures")
    func uncertainWordIdsConservativePriming() {
        let attemptStart = baseDate.addingTimeInterval(60)
        #expect(policy.isPrimed(wordId: 101, exposures: [], uncertainWordIds: [101], before: attemptStart))
        #expect(!policy.isPrimed(wordId: 202, exposures: [], uncertainWordIds: [101], before: attemptStart))
    }

    @Test("empty wordIds in exposure conservatively primes all mission words")
    func wholeMissionExposurePrimesTargetWords() {
        let attemptStart = baseDate.addingTimeInterval(60)
        let wholeMissionExposure = [
            makeExposure(
                wordIds: [],
                level: .lexical,
                presentedAt: baseDate.addingTimeInterval(20)
            )
        ]

        #expect(policy.isPrimed(wordId: 101, exposures: wholeMissionExposure, uncertainWordIds: [], before: attemptStart))
        #expect(policy.isPrimed(wordId: 202, exposures: wholeMissionExposure, uncertainWordIds: [], before: attemptStart))
    }

    @Test("exposure for different word does not prime target word")
    func unrelatedWordExposureDoesNotPrime() {
        let attemptStart = baseDate.addingTimeInterval(60)
        let otherWordExposure = [
            makeExposure(
                wordIds: [999],
                level: .model,
                presentedAt: baseDate.addingTimeInterval(20)
            )
        ]

        #expect(!policy.isPrimed(wordId: 101, exposures: otherWordExposure, uncertainWordIds: [], before: attemptStart))
    }
}
