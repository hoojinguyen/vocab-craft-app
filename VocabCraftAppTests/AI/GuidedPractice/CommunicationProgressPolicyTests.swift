import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Communication Progress Policy Tests")
struct CommunicationProgressPolicyTests {
    private let policy = CommunicationProgressPolicy(configuration: .v1)
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeEvidence(
        id: UUID = UUID(),
        sessionId: UUID = UUID(),
        wordId: Int64 = 101,
        timestamp: Date,
        mode: PracticeInputMode = .voice,
        usage: PracticeUsageVerdict = .appropriate,
        intent: PracticeIntentVerdict = .achieved,
        reliability: PracticeTranscriptReliability = .usable,
        primed: Bool = false,
        supportExposureIds: [UUID] = [],
        family: PracticeContextFamily = .dining,
        status: PracticeEvidenceStatus = .valid
    ) -> WordUseEvidence {
        WordUseEvidence(
            id: id,
            sessionId: sessionId,
            turnId: UUID(),
            wordId: wordId,
            objectiveId: "test_objective",
            usageVerdict: usage,
            intentVerdict: intent,
            transcriptReliability: reliability,
            supportExposureIds: supportExposureIds,
            primed: primed,
            contextFamily: family,
            inputMode: mode,
            quotedSpan: "test",
            assessmentVersion: 1,
            providerIdentity: "test_provider",
            status: status,
            timestamp: timestamp,
            turnRevision: 1,
            opportunityId: "test_opportunity"
        )
    }

    @Test("sameSessionCountsOnce preserves practicing stage for same session")
    func sameSessionCountsOnce() {
        let sessionId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let firstEvidence = makeEvidence(
            sessionId: sessionId,
            timestamp: baseDate
        )
        let secondEvidence = makeEvidence(
            sessionId: sessionId,
            timestamp: baseDate.addingTimeInterval(300)
        )

        let twoSameSession = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(600)
        )

        #expect(twoSameSession.stage == .practicing)
        #expect(twoSameSession.independentEvidenceIds == [firstEvidence.id])
        #expect(twoSameSession.lastIndependentUseAt == firstEvidence.timestamp)
    }

    @Test("twoDifferentSessions promotes to independentFamiliar")
    func twoDifferentSessionsPromotesToIndependentFamiliar() {
        let firstSession = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondSession = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let firstEvidence = makeEvidence(
            sessionId: firstSession,
            timestamp: baseDate
        )
        let secondEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(3600)
        )

        let twoDifferentSessions = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(4000)
        )

        #expect(twoDifferentSessions.stage == .independentFamiliar)
        #expect(twoDifferentSessions.independentEvidenceIds == [firstEvidence.id, secondEvidence.id])
        #expect(twoDifferentSessions.lastIndependentUseAt == secondEvidence.timestamp)
    }

    @Test("transferRequires86400SecondsAndNewFamily enforces time and context boundaries")
    func transferRequires86400SecondsAndNewFamily() {
        let firstSession = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondSession = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

        let firstEvidence = makeEvidence(
            sessionId: firstSession,
            timestamp: baseDate,
            family: .dining
        )

        // Case A: 86399 seconds with new context family -> stays independentFamiliar
        let underEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(86_399),
            family: .shopping
        )
        let at86399Seconds = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, underEvidence],
            now: baseDate.addingTimeInterval(87_000)
        )
        #expect(at86399Seconds.stage == .independentFamiliar)

        // Case B: 86400 seconds with SAME context family -> stays independentFamiliar
        let sameFamilyEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(86_400),
            family: .dining
        )
        let at86400SecondsSameFamily = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, sameFamilyEvidence],
            now: baseDate.addingTimeInterval(87_000)
        )
        #expect(at86400SecondsSameFamily.stage == .independentFamiliar)

        // Case C: 86400 seconds with NEW context family -> transferred
        let transferredEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(86_400),
            family: .shopping
        )
        let at86400SecondsNewFamily = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, transferredEvidence],
            now: baseDate.addingTimeInterval(87_000)
        )
        #expect(at86400SecondsNewFamily.stage == .transferred)
    }

    @Test("nextPracticeAt schedules correctly for assisted, familiar, and transferred stages")
    func nextPracticeAtSchedulesCorrectly() {
        // Assisted (or practicing): lastAttempt + 86,400s
        let lastAttempt = baseDate
        let assistedEvidence = makeEvidence(
            sessionId: UUID(),
            timestamp: lastAttempt,
            primed: true
        )
        let assisted = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [assistedEvidence],
            now: baseDate.addingTimeInterval(60)
        )
        #expect(assisted.stage == .practicing)
        #expect(assisted.nextPracticeAt == lastAttempt.addingTimeInterval(86_400))

        // Familiar: lastEligibleUse + 259,200s (3 days)
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(sessionId: firstSession, timestamp: baseDate)
        let lastEligibleUseFamiliar = baseDate.addingTimeInterval(3600)
        let secondEvidence = makeEvidence(sessionId: secondSession, timestamp: lastEligibleUseFamiliar)
        let familiar = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: lastEligibleUseFamiliar.addingTimeInterval(60)
        )
        #expect(familiar.stage == .independentFamiliar)
        #expect(familiar.nextPracticeAt == lastEligibleUseFamiliar.addingTimeInterval(259_200))

        // Transferred: lastEligibleUse + 604,800s (7 days)
        let thirdSession = UUID()
        let lastEligibleUseTransferred = baseDate.addingTimeInterval(86_400)
        let thirdEvidence = makeEvidence(
            sessionId: thirdSession,
            timestamp: lastEligibleUseTransferred,
            family: .shopping
        )
        let transferred = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, thirdEvidence],
            now: lastEligibleUseTransferred.addingTimeInterval(60)
        )
        #expect(transferred.stage == .transferred)
        #expect(transferred.nextPracticeAt == lastEligibleUseTransferred.addingTimeInterval(604_800))
    }

    @Test("clockRollbackDoesNotPromote guards stage and minimum schedule deadline")
    func clockRollbackDoesNotPromote() {
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(sessionId: firstSession, timestamp: baseDate, family: .dining)
        let secondEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(86_400),
            family: .shopping
        )

        // Device clock rolled back to before the latest event timestamp
        let rolledBackNow = baseDate.addingTimeInterval(-10_000)

        let result = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: rolledBackNow
        )

        #expect(result.stage == .transferred)
        // Schedule must not be placed earlier than the latest event timestamp + delay
        let minSchedule = secondEvidence.timestamp.addingTimeInterval(604_800)
        #expect(result.nextPracticeAt == minSchedule)
        #expect(result.nextPracticeAt! >= minSchedule)
    }

    @Test("primed does not promote to independent use")
    func primedDoesNotPromote() {
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(sessionId: firstSession, timestamp: baseDate, primed: true)
        let secondEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(3600),
            primed: true
        )

        let result = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(7200)
        )

        #expect(result.stage == .practicing)
        #expect(result.independentEvidenceIds.isEmpty)
        #expect(result.lastIndependentUseAt == nil)
    }

    @Test("assisted with support exposures does not promote to independent use")
    func assistedDoesNotPromote() {
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(
            sessionId: firstSession,
            timestamp: baseDate,
            supportExposureIds: [UUID()]
        )
        let secondEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(3600),
            supportExposureIds: [UUID()]
        )

        let result = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(7200)
        )

        #expect(result.stage == .practicing)
        #expect(result.independentEvidenceIds.isEmpty)
        #expect(result.lastIndependentUseAt == nil)
    }

    @Test("editedTranscript does not promote voice progress")
    func editedTranscriptDoesNotPromote() {
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(sessionId: firstSession, timestamp: baseDate, mode: .editedTranscript)
        let secondEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(3600),
            mode: .editedTranscript
        )

        // Querying for voice mode ignores editedTranscript evidence
        let voiceResult = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(7200)
        )
        #expect(voiceResult.stage == .noEvidence)

        // Querying for editedTranscript mode never promotes to independent
        let editedResult = policy.rebuild(
            wordId: 101,
            mode: .editedTranscript,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(7200)
        )
        #expect(editedResult.stage == .practicing)
        #expect(editedResult.independentEvidenceIds.isEmpty)
    }

    @Test("uncertain outcome does not change existing stage or schedule")
    func uncertainOutcomeDoesNotPromoteOrChangeExistingStageAndSchedule() {
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(sessionId: firstSession, timestamp: baseDate)
        let secondEvidence = makeEvidence(sessionId: secondSession, timestamp: baseDate.addingTimeInterval(3600))

        let baseline = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(4000)
        )
        #expect(baseline.stage == .independentFamiliar)
        let expectedSchedule = baseline.nextPracticeAt

        // Later attempt has uncertain usage
        let thirdSession = UUID()
        let uncertainEvidence = makeEvidence(
            sessionId: thirdSession,
            timestamp: baseDate.addingTimeInterval(10_000),
            usage: .uncertain
        )

        let afterUncertain = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence, uncertainEvidence],
            now: baseDate.addingTimeInterval(12_000)
        )

        #expect(afterUncertain.stage == .independentFamiliar)
        #expect(afterUncertain.nextPracticeAt == expectedSchedule)
    }

    @Test("superseded evidence is ignored completely")
    func supersededEvidenceIsIgnored() {
        let sessionId = UUID()
        let supersededEvidence = makeEvidence(
            sessionId: sessionId,
            timestamp: baseDate,
            status: .superseded
        )

        let result = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [supersededEvidence],
            now: baseDate.addingTimeInterval(100)
        )

        #expect(result.stage == .noEvidence)
        #expect(result.nextPracticeAt == nil)
    }

    @Test("typed input does not promote voice progress and voice does not promote typed")
    func typedDoesNotPromoteVoice() {
        let firstSession = UUID()
        let secondSession = UUID()
        let typedEvidence1 = makeEvidence(sessionId: firstSession, timestamp: baseDate, mode: .typed)
        let typedEvidence2 = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(3600),
            mode: .typed
        )

        let voiceResult = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [typedEvidence1, typedEvidence2],
            now: baseDate.addingTimeInterval(4000)
        )
        #expect(voiceResult.stage == .noEvidence)

        let typedResult = policy.rebuild(
            wordId: 101,
            mode: .typed,
            evidence: [typedEvidence1, typedEvidence2],
            now: baseDate.addingTimeInterval(4000)
        )
        #expect(typedResult.stage == .independentFamiliar)
    }

    @Test("unusable voice transcript does not promote to independent familiar")
    func unusableVoiceTranscriptDoesNotPromote() {
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(sessionId: firstSession, timestamp: baseDate, reliability: .usable)
        let secondNeedsConfirmation = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(3600),
            reliability: .needsConfirmation
        )

        let result = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondNeedsConfirmation],
            now: baseDate.addingTimeInterval(4000)
        )

        #expect(result.stage == .practicing)
        #expect(result.independentEvidenceIds == [firstEvidence.id])
    }

    @Test("deletion or empty evidence rebuilds cleanly to noEvidence")
    func deletionRebuildsToNoEvidence() {
        let result = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [],
            now: baseDate
        )

        #expect(result.stage == .noEvidence)
        #expect(result.independentEvidenceIds.isEmpty)
        #expect(result.lastIndependentUseAt == nil)
        #expect(result.nextPracticeAt == nil)
        #expect(result.recentOutcome == nil)
        #expect(result.policyVersion == 1)
    }

    @Test("timezone change does not affect transfer calculation")
    func timezoneChangeDoesNotAffectTransfer() {
        let firstSession = UUID()
        let secondSession = UUID()
        let firstEvidence = makeEvidence(sessionId: firstSession, timestamp: baseDate, family: .dining)
        let secondEvidence = makeEvidence(
            sessionId: secondSession,
            timestamp: baseDate.addingTimeInterval(86_400),
            family: .shopping
        )

        // Elapsed UTC seconds is constant regardless of current time zone
        let result = policy.rebuild(
            wordId: 101,
            mode: .voice,
            evidence: [firstEvidence, secondEvidence],
            now: baseDate.addingTimeInterval(90_000)
        )

        #expect(result.stage == .transferred)
    }
}
