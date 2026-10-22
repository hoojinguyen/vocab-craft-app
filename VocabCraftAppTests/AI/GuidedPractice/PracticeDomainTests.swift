import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Practice Domain & Snapshot Tests")
struct PracticeDomainTests {

    @Test("roundTripRetainsCheckpoint preserves session snapshot and revision")
    func roundTripRetainsCheckpoint() throws {
        let original = PracticeFixtures.sessionSnapshot(
            revision: 5,
            wordId: 101,
            sessionId: UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PracticeSessionSnapshot.self, from: data)

        #expect(decoded == original)
        #expect(decoded.session.revision == original.session.revision)
    }

    @Test("wordId 101 is preserved as Int64 across snapshots")
    func wordIdPreservedAsInt64() throws {
        let largeWordId: Int64 = 101
        let mission = try PracticeFixtures.mission(wordIds: [largeWordId])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(mission)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PracticeMission.self, from: data)

        #expect(decoded.targetWordIds == [101])
        #expect(decoded.wordSnapshots.first?.wordId == 101)
        #expect(decoded == mission)
    }

    @Test("pending intent and revision are preserved across serialization")
    func pendingIntentAndRevisionPreserved() throws {
        let sessionId = UUID(uuidString: "22222222-3333-4444-5555-666666666666")!
        let intentId = UUID(uuidString: "33333333-4444-5555-6666-777777777777")!
        let intent = PracticePresentationIntent(
            id: intentId,
            sessionId: sessionId,
            turnId: nil,
            content: "Try saying: May I have...",
            channel: .visual,
            possibleWordIds: [101],
            proposedLevel: .lexical,
            status: .pending
        )

        let checkpoint = PracticeCheckpoint(
            pendingTurnId: nil,
            requestId: "req-123",
            presentationIntents: [intent],
            exposureUncertainWordIds: [101],
            currentSupportLevel: .lexical,
            objectiveResults: [
                PracticeObjectiveResult(
                    objectiveId: "order_food",
                    intentVerdict: .achieved,
                    opportunityObserved: true
                )
            ],
            difficultyOutcomes: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(checkpoint)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PracticeCheckpoint.self, from: data)

        #expect(decoded == checkpoint)
        #expect(decoded.presentationIntents.first?.status == .pending)
        #expect(decoded.presentationIntents.first?.proposedLevel == .lexical)
        #expect(decoded.exposureUncertainWordIds == [101])
    }

    @Test("editedTranscript is distinct from voice input mode")
    func editedTranscriptDistinctFromVoice() throws {
        let voice = PracticeInputMode.voice
        let edited = PracticeInputMode.editedTranscript
        let typed = PracticeInputMode.typed

        #expect(voice != edited)
        #expect(voice != typed)
        #expect(edited != typed)
        #expect(voice.rawValue == "voice")
        #expect(edited.rawValue == "editedTranscript")
        #expect(typed.rawValue == "typed")

        let sessionId = UUID()
        let evidenceVoice = PracticeFixtures.evidence(
            sessionId: sessionId,
            at: Date(timeIntervalSince1970: 1_700_000_000),
            mode: .voice,
            primed: false
        )
        let evidenceEdited = PracticeFixtures.evidence(
            sessionId: sessionId,
            at: Date(timeIntervalSince1970: 1_700_000_000),
            mode: .editedTranscript,
            primed: false
        )

        #expect(evidenceVoice.inputMode == .voice)
        #expect(evidenceEdited.inputMode == .editedTranscript)
        #expect(evidenceVoice != evidenceEdited)
    }

    @Test("ManualPracticeClock sleep completes only when advance is sufficient")
    func manualPracticeClockSleepBehavior() async throws {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = ManualPracticeClock(initialDate: baseDate)

        #expect(clock.now() == baseDate)

        final class FlagBox: @unchecked Sendable {
            var isFinished = false
            let lock = NSLock()
            func setFinished() {
                lock.lock()
                isFinished = true
                lock.unlock()
            }
            func getFinished() -> Bool {
                lock.lock()
                defer { lock.unlock() }
                return isFinished
            }
        }

        let flag = FlagBox()
        let sleepTask = Task {
            try await clock.sleep(for: .seconds(10))
            flag.setFinished()
        }

        // Wait deterministically until sleep continuation is registered
        await clock.waitForSleepers(count: 1)

        // Advance by 4 seconds: should NOT complete yet
        clock.advance(by: .seconds(4))
        await Task.yield()
        #expect(flag.getFinished() == false)
        #expect(clock.now() == baseDate.addingTimeInterval(4))

        // Advance by remaining 6 seconds: should complete
        clock.advance(by: .seconds(6))
        _ = try await sleepTask.value
        #expect(flag.getFinished() == true)
        #expect(clock.now() == baseDate.addingTimeInterval(10))
    }

    @Test("difficulty validation rejects out-of-bounds values")
    func difficultyValidation() throws {
        let valid = try PracticeDifficulty(taskConstraints: 0, characterDirectness: 1, contextNovelty: 2)
        #expect(valid.taskConstraints == 0)
        #expect(valid.characterDirectness == 1)
        #expect(valid.contextNovelty == 2)

        #expect(throws: PracticeDomainError.self) {
            _ = try PracticeDifficulty(taskConstraints: -1, characterDirectness: 0, contextNovelty: 0)
        }
        #expect(throws: PracticeDomainError.self) {
            _ = try PracticeDifficulty(taskConstraints: 0, characterDirectness: 3, contextNovelty: 0)
        }
        #expect(throws: PracticeDomainError.self) {
            _ = try PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 5)
        }
    }

    @Test("mission validation rejects duplicate word IDs")
    func missionDuplicateWordValidation() throws {
        let wordSnapshot = PracticeWordSnapshot(
            wordId: 101,
            lemma: "menu",
            definitionEn: "a list of food",
            definitionVi: "thực đơn"
        )
        let diff = try PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0)

        #expect(throws: PracticeDomainError.self) {
            _ = try PracticeMission(
                id: UUID(),
                templateId: "dining_01",
                templateVersion: 1,
                targetWordIds: [101, 101],
                wordSnapshots: [wordSnapshot],
                objectiveIds: ["order"],
                contextFamily: .dining,
                difficulty: diff,
                selectionReasons: [.communicationDue],
                policyVersion: 1,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        }
    }

    @Test("mission validation rejects unsupported policy version")
    func missionUnsupportedPolicyVersion() throws {
        let wordSnapshot = PracticeWordSnapshot(
            wordId: 101,
            lemma: "menu",
            definitionEn: "a list of food",
            definitionVi: "thực đơn"
        )
        let diff = try PracticeDifficulty(taskConstraints: 0, characterDirectness: 0, contextNovelty: 0)

        #expect(throws: PracticeDomainError.self) {
            _ = try PracticeMission(
                id: UUID(),
                templateId: "dining_01",
                templateVersion: 1,
                targetWordIds: [101],
                wordSnapshots: [wordSnapshot],
                objectiveIds: ["order"],
                contextFamily: .dining,
                difficulty: diff,
                selectionReasons: [.communicationDue],
                policyVersion: 999,
                createdAt: Date(timeIntervalSince1970: 1_700_000_000)
            )
        }
    }

    @Test("PracticeFixtures provide deterministic values without production defaults")
    func fixtureDeterminism() throws {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        #expect(mission.targetWordIds == [101])
        #expect(mission.contextFamily == .dining)
        #expect(mission.difficulty.taskConstraints == 0)

        let session = PracticeFixtures.session()
        #expect(session.revision == 1)
        #expect(session.initialInputMode == .voice)

        let evidence = PracticeFixtures.evidence(
            sessionId: session.id,
            at: Date(timeIntervalSince1970: 1_700_000_000),
            mode: .voice,
            primed: false
        )
        #expect(evidence.usageVerdict == .appropriate)
        #expect(evidence.intentVerdict == .achieved)
        #expect(evidence.transcriptReliability == .usable)
        #expect(evidence.supportExposureIds.isEmpty)
        #expect(evidence.contextFamily == .dining)

        let context = PracticeFixtures.learningContext()
        #expect(!context.words.isEmpty)
        #expect(context.recentReflexWordIds.contains(101))
    }

    @Test("PracticePolicyConfiguration defaults match v1 spec")
    func policyConfigurationV1Spec() {
        let config = PracticePolicyConfiguration.v1
        #expect(config.version == 1)
        #expect(config.transferDelay == 86_400)
        #expect(config.assistedDelay == 86_400)
        #expect(config.familiarDelay == 259_200)
        #expect(config.transferredDelay == 604_800)
        #expect(config.generationTimeout == 30)
        #expect(config.ttsPreparationTimeout == 20)
    }

    @Test("PracticeFailure codes round trip cleanly and conform to Error")
    func failureCodesRoundTrip() throws {
        let failure = PracticeFailure(
            code: .timeout,
            message: "Request timed out",
            underlyingError: "timed_out_after_30s"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(failure)
        let decoded = try JSONDecoder().decode(PracticeFailure.self, from: data)

        #expect(decoded == failure)
        #expect(decoded.code == .timeout)
        #expect(decoded.message == "Request timed out")
    }
}
