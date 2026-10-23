import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Practice Presentation State Tests")
struct PracticePresentationStateTests {
    @Test("Processing state disables submit and capture")
    func processingDisablesSubmitAndCapture() {
        let presentation = PracticePresentationState.make(
            from: .processing,
            capability: .standardCloud
        )
        #expect(!presentation.canSubmit)
        #expect(!presentation.canCapture)
        #expect(presentation.isProcessing)
        #expect(!presentation.canRequestHelp)
    }

    @Test("Paused state does not capture automatically")
    func pausedDoesNotCaptureAutomatically() {
        let presentation = PracticePresentationState.make(
            from: .paused,
            capability: .standardCloud
        )
        #expect(!presentation.canCapture)
        #expect(!presentation.canSubmit)
        #expect(presentation.isPaused)
        #expect(!presentation.canRequestHelp)
    }

    @Test("Mandatory contract: unsaved summary never looks cleanly completed")
    func unsavedSummaryNeverLooksCompleted() {
        let summary = PracticeSummary(
            sessionId: UUID(),
            status: .completed,
            objectiveResults: [],
            perWordProgress: [],
            evidenceIds: [],
            persisted: false
        )
        let presentation = PracticePresentationState.make(
            from: .completed,
            capability: .standardCloud,
            summary: summary
        )
        #expect(presentation.showUnsaved)
        #expect(summary.persisted == false)
    }

    @Test("Awaiting learner state allows submit and capture when speech capable")
    func awaitingLearnerAllowsSubmitAndCapture() {
        let presentation = PracticePresentationState.make(
            from: .awaitingLearner,
            capability: .standardCloud
        )
        #expect(presentation.canSubmit)
        #expect(presentation.canCapture)
        #expect(presentation.canRequestHelp)
        #expect(!presentation.isProcessing)
        #expect(!presentation.isCapturing)
        #expect(!presentation.isPaused)
    }

    @Test("Awaiting learner state disables capture when speech capability unavailable")
    func awaitingLearnerDisablesCaptureWithoutSpeechCapability() {
        let textOnlyCapability = PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: true,
            canCaptureSpeech: false,
            canPlaySpeech: false,
            providerIdentity: "textOnly"
        )
        let presentation = PracticePresentationState.make(
            from: .awaitingLearner,
            capability: textOnlyCapability
        )
        #expect(presentation.canSubmit)
        #expect(!presentation.canCapture)
        #expect(presentation.canRequestHelp)
    }

    @Test("Capturing state marks active capturing and disallows new capture start")
    func capturingStateProperties() {
        let presentation = PracticePresentationState.make(
            from: .capturing,
            capability: .standardCloud
        )
        #expect(presentation.canSubmit)
        #expect(!presentation.canCapture)
        #expect(presentation.isCapturing)
        #expect(!presentation.canRequestHelp)
    }

    @Test("Recoverable error state enables showUnsaved and error flag")
    func recoverableErrorStateProperties() {
        let presentation = PracticePresentationState.make(
            from: .recoverableError,
            capability: .standardCloud
        )
        #expect(!presentation.canSubmit)
        #expect(!presentation.canCapture)
        #expect(presentation.showUnsaved)
        #expect(presentation.isError)
    }
}
