import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Practice Assessment Validation Tests")
struct PracticeAssessmentTests {
    private let validator = AssessPracticeTurnUseCase()

    @Test("unicodeQuoteMustExistInRawAcceptedText asserts exact Unicode quotation match and rejects foreign words")
    func unicodeQuoteMustExistInRawAcceptedText() throws {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let request = PracticeAIRequest(
            mission: mission,
            acceptedTurns: [],
            supportBudget: .none,
            providerIdentity: "test_provider"
        )
        let turn = PracticeTurn(
            id: UUID(),
            sessionId: mission.id,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I’d recommend the grilled salmon",
            acceptedText: "I’d recommend the grilled salmon, it is very fresh.",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-1",
            sessionRevision: 1,
            timestamp: PracticeFixtures.baseDate
        )
        let validResponse = PracticeAIResponse(
            characterReply: "That sounds delicious! I'll take your recommendation.",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "I’d recommend"
                )
            ]
        )

        let validated = try validator.validate(
            response: validResponse,
            request: request,
            turn: turn,
            exposures: [],
            uncertainWordIds: []
        )

        #expect(validated.evidence.first?.quotedSpan == "I’d recommend")

        let foreignWord = PracticeAIResponse(
            characterReply: "Sounds good!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 99999,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "I’d recommend"
                )
            ]
        )

        #expect(throws: PracticeFailure.self) {
            try validator.validate(
                response: foreignWord,
                request: request,
                turn: turn,
                exposures: [],
                uncertainWordIds: []
            )
        }
    }

    @Test("invented quote not present in accepted text is strictly rejected")
    func rejectsInventedQuote() throws {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let request = PracticeAIRequest(
            mission: mission,
            acceptedTurns: [],
            supportBudget: .none,
            providerIdentity: "test_provider"
        )
        let turn = PracticeTurn(
            id: UUID(),
            sessionId: mission.id,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I want the fish",
            acceptedText: "I would like to order the fish.",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-2",
            sessionRevision: 1,
            timestamp: PracticeFixtures.baseDate
        )
        let response = PracticeAIResponse(
            characterReply: "Coming right up!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "I want to order" // not present in raw acceptedText
                )
            ]
        )

        #expect(throws: PracticeFailure.self) {
            try validator.validate(
                response: response,
                request: request,
                turn: turn,
                exposures: [],
                uncertainWordIds: []
            )
        }
    }

    @Test("foreign objectiveId not in mission objectives is strictly rejected")
    func rejectsForeignObjectiveId() throws {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let request = PracticeAIRequest(
            mission: mission,
            acceptedTurns: [],
            supportBudget: .none,
            providerIdentity: "test_provider"
        )
        let turn = PracticeTurn(
            id: UUID(),
            sessionId: mission.id,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "Hello",
            acceptedText: "Hello there.",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-3",
            sessionRevision: 1,
            timestamp: PracticeFixtures.baseDate
        )
        let foreignObjectiveInWord = PracticeAIResponse(
            characterReply: "Hi!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "unknown_objective",
                    usageVerdict: .appropriate,
                    quotedSpan: "Hello"
                )
            ]
        )

        #expect(throws: PracticeFailure.self) {
            try validator.validate(
                response: foreignObjectiveInWord,
                request: request,
                turn: turn,
                exposures: [],
                uncertainWordIds: []
            )
        }

        let foreignObjectiveDirect = PracticeAIResponse(
            characterReply: "Hi!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "unknown_objective", intentVerdict: .achieved)
            ],
            wordAssessments: []
        )

        #expect(throws: PracticeFailure.self) {
            try validator.validate(
                response: foreignObjectiveDirect,
                request: request,
                turn: turn,
                exposures: [],
                uncertainWordIds: []
            )
        }
    }

    @Test("empty or whitespace-only characterReply is strictly rejected")
    func rejectsEmptyCharacterReply() throws {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let request = PracticeAIRequest(
            mission: mission,
            acceptedTurns: [],
            supportBudget: .none,
            providerIdentity: "test_provider"
        )
        let turn = PracticeTurn(
            id: UUID(),
            sessionId: mission.id,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "Hello",
            acceptedText: "Hello.",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-4",
            sessionRevision: 1,
            timestamp: PracticeFixtures.baseDate
        )
        let response = PracticeAIResponse(
            characterReply: "   \n\t  ",
            objectiveAssessments: [],
            wordAssessments: []
        )

        #expect(throws: PracticeFailure.self) {
            try validator.validate(
                response: response,
                request: request,
                turn: turn,
                exposures: [],
                uncertainWordIds: []
            )
        }
    }

    @Test("inflection only valid if span actually exists in raw acceptedText")
    func inflectionOnlyValidIfSpanExistsInAcceptedText() throws {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let request = PracticeAIRequest(
            mission: mission,
            acceptedTurns: [],
            supportBudget: .none,
            providerIdentity: "test_provider"
        )
        let turn = PracticeTurn(
            id: UUID(),
            sessionId: mission.id,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I hesitated for a moment",
            acceptedText: "I hesitated before making my choice.",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-5",
            sessionRevision: 1,
            timestamp: PracticeFixtures.baseDate
        )

        // "hesitated" exists in raw text -> valid
        let validResponse = PracticeAIResponse(
            characterReply: "Take your time!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "hesitated"
                )
            ]
        )
        let result = try validator.validate(
            response: validResponse,
            request: request,
            turn: turn,
            exposures: [],
            uncertainWordIds: []
        )
        #expect(result.evidence.first?.quotedSpan == "hesitated")

        // "hesitating" does NOT exist in raw text -> invalid
        let invalidResponse = PracticeAIResponse(
            characterReply: "Take your time!",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "hesitating"
                )
            ]
        )
        #expect(throws: PracticeFailure.self) {
            try validator.validate(
                response: invalidResponse,
                request: request,
                turn: turn,
                exposures: [],
                uncertainWordIds: []
            )
        }
    }

    @Test("all fixture cases from JSON validate correctly against pedagogical rules")
    func allFixtureCasesValidateCorrectly() throws {
        let cases = try PracticeFixtures.loadAssessmentCases()
        #expect(cases.count >= 8)

        let policy = CommunicationProgressPolicy(configuration: .v1)

        for fixture in cases {
            let mission = try PracticeMission(
                id: UUID(),
                templateId: "fixture_template",
                templateVersion: 1,
                targetWordIds: fixture.targetWordIds,
                wordSnapshots: fixture.targetWordIds.map {
                    PracticeFixtures.wordSnapshot(wordId: $0, lemma: "word_\($0)")
                },
                objectiveIds: fixture.objectiveIds,
                contextFamily: .dining,
                difficulty: PracticeFixtures.difficulty(),
                selectionReasons: [.communicationDue],
                policyVersion: 1,
                createdAt: PracticeFixtures.baseDate
            )
            let request = PracticeAIRequest(
                mission: mission,
                acceptedTurns: [],
                supportBudget: .none,
                providerIdentity: "fixture_provider"
            )
            let turn = PracticeTurn(
                id: UUID(),
                sessionId: mission.id,
                sequence: 1,
                speaker: .learner,
                inputMode: fixture.inputMode,
                originalText: fixture.acceptedText,
                acceptedText: fixture.acceptedText,
                transcriptStatus: fixture.transcriptStatus,
                generationStatus: .succeeded,
                requestId: "fixture-\(fixture.id)",
                sessionRevision: 1,
                timestamp: Date(timeIntervalSince1970: 1_700_000_100)
            )

            if fixture.expectedValid {
                let validated = try validator.validate(
                    response: fixture.response,
                    request: request,
                    turn: turn,
                    exposures: fixture.exposures,
                    uncertainWordIds: Set(fixture.uncertainWordIds)
                )

                if let expectedUsage = fixture.expectedUsageVerdict, let firstEvidence = validated.evidence.first {
                    #expect(firstEvidence.usageVerdict == expectedUsage)
                }
                if let expectedIntent = fixture.expectedIntentVerdict, let firstObjective = validated.objectiveResults.first {
                    #expect(firstObjective.intentVerdict == expectedIntent)
                }
                if let expectedReliability = fixture.expectedReliability, let firstEvidence = validated.evidence.first {
                    #expect(firstEvidence.transcriptReliability == expectedReliability)
                }
                if let expectedPrimed = fixture.expectedPrimed, let firstEvidence = validated.evidence.first {
                    #expect(firstEvidence.primed == expectedPrimed)
                }
                if let expectedSpan = fixture.expectedQuotedSpan, let firstEvidence = validated.evidence.first {
                    #expect(firstEvidence.quotedSpan == expectedSpan)
                }

                // If STT is uncertain, verify progress rebuild does not advance stage
                if fixture.transcriptStatus == .uncertain, let firstEvidence = validated.evidence.first {
                    let progress = policy.rebuild(
                        wordId: firstEvidence.wordId,
                        mode: fixture.inputMode,
                        evidence: [firstEvidence],
                        now: turn.timestamp.addingTimeInterval(10)
                    )
                    #expect(progress.stage == .noEvidence)
                }
            } else {
                #expect(throws: PracticeFailure.self) {
                    try validator.validate(
                        response: fixture.response,
                        request: request,
                        turn: turn,
                        exposures: fixture.exposures,
                        uncertainWordIds: Set(fixture.uncertainWordIds)
                    )
                }
            }
        }
    }

    @Test("prior scaffolding exposures determine primed state accurately")
    func priorScaffoldingDeterminesPrimedState() throws {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let request = PracticeAIRequest(
            mission: mission,
            acceptedTurns: [],
            supportBudget: .none,
            providerIdentity: "test_provider"
        )
        let turnTimestamp = Date(timeIntervalSince1970: 1_700_000_500)
        let turn = PracticeTurn(
            id: UUID(),
            sessionId: mission.id,
            sequence: 1,
            speaker: .learner,
            inputMode: .voice,
            originalText: "I want the menu",
            acceptedText: "May I see the menu?",
            transcriptStatus: .final,
            generationStatus: .succeeded,
            requestId: "req-prime",
            sessionRevision: 1,
            timestamp: turnTimestamp
        )
        let response = PracticeAIResponse(
            characterReply: "Here is the menu.",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "menu"
                )
            ]
        )

        // 1. Exposure before turn with lexical support -> primed
        let priorLexicalExposure = SupportExposure(
            id: UUID(),
            sessionId: mission.id,
            wordIds: [101],
            level: .lexical,
            origin: .learnerRequested,
            contentSnapshot: "menu",
            presentedAt: turnTimestamp.addingTimeInterval(-10),
            channel: .visual
        )
        let primedResult = try validator.validate(
            response: response,
            request: request,
            turn: turn,
            exposures: [priorLexicalExposure],
            uncertainWordIds: []
        )
        #expect(primedResult.evidence.first?.primed == true)

        // 2. Exposure after turn -> not primed
        let futureExposure = SupportExposure(
            id: UUID(),
            sessionId: mission.id,
            wordIds: [101],
            level: .lexical,
            origin: .coachSuggested,
            contentSnapshot: "menu",
            presentedAt: turnTimestamp.addingTimeInterval(10),
            channel: .visual
        )
        let unprimedResult = try validator.validate(
            response: response,
            request: request,
            turn: turn,
            exposures: [futureExposure],
            uncertainWordIds: []
        )
        #expect(unprimedResult.evidence.first?.primed == false)

        // 3. Exposure before turn with intent support only -> not primed
        let intentExposure = SupportExposure(
            id: UUID(),
            sessionId: mission.id,
            wordIds: [101],
            level: .intent,
            origin: .coachSuggested,
            contentSnapshot: "Ask for the food list",
            presentedAt: turnTimestamp.addingTimeInterval(-10),
            channel: .visual
        )
        let intentResult = try validator.validate(
            response: response,
            request: request,
            turn: turn,
            exposures: [intentExposure],
            uncertainWordIds: []
        )
        #expect(intentResult.evidence.first?.primed == false)

        // 4. Uncertain word ID -> primed
        let uncertainResult = try validator.validate(
            response: response,
            request: request,
            turn: turn,
            exposures: [],
            uncertainWordIds: [101]
        )
        #expect(uncertainResult.evidence.first?.primed == true)
    }
}
