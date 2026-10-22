import Foundation

/// Pure domain use case validating structured AI responses and transforming assessments into verified evidence.
public struct AssessPracticeTurnUseCase: Sendable {
    private let supportPolicy: SupportPolicy

    public init(supportPolicy: SupportPolicy = SupportPolicy()) {
        self.supportPolicy = supportPolicy
    }

    /// Validates raw AI conversation response against pedagogical constraints and maps it to verified `PracticeAssessment`.
    ///
    /// - Parameters:
    ///   - response: Structured AI output to validate.
    ///   - request: Original practice request containing mission constraints.
    ///   - turn: Accepted turn containing verbatim learner input.
    ///   - exposures: Historical scaffolding exposures presented prior to or during the turn.
    ///   - uncertainWordIds: Set of word IDs with ambiguous exposure history.
    /// - Throws: `PracticeFailure(code: .domainValidation)` if constraints are violated.
    /// - Returns: Complete validated `PracticeAssessment`.
    public func validate(
        response: PracticeAIResponse,
        request: PracticeAIRequest,
        turn: PracticeTurn,
        exposures: [SupportExposure],
        uncertainWordIds: Set<Int64>
    ) throws -> PracticeAssessment {
        try validateReplyAndScope(response: response, request: request)
        try validateQuotedSpans(response: response, acceptedText: turn.acceptedText)

        let validatedEvidence = buildEvidence(
            response: response,
            request: request,
            turn: turn,
            exposures: exposures,
            uncertainWordIds: uncertainWordIds
        )
        let objectiveResults = buildObjectiveResults(from: response.objectiveAssessments)

        return PracticeAssessment(
            evidence: validatedEvidence,
            objectiveResults: objectiveResults,
            response: response
        )
    }

    // MARK: - Validation Helpers

    private func validateReplyAndScope(
        response: PracticeAIResponse,
        request: PracticeAIRequest
    ) throws {
        guard !response.characterReply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw PracticeFailure(
                code: .domainValidation,
                message: "AI response characterReply cannot be empty."
            )
        }

        let allowedWordIds = Set(request.mission.targetWordIds)
        for wordAssessment in response.wordAssessments {
            guard allowedWordIds.contains(wordAssessment.wordId) else {
                throw PracticeFailure(
                    code: .domainValidation,
                    message: "Foreign wordId \(wordAssessment.wordId) not present in mission target words \(request.mission.targetWordIds)."
                )
            }
        }

        let allowedObjectiveIds = Set(request.mission.objectiveIds)
        for objAssessment in response.objectiveAssessments {
            guard allowedObjectiveIds.contains(objAssessment.objectiveId) else {
                throw PracticeFailure(
                    code: .domainValidation,
                    message: "Foreign objectiveId \(objAssessment.objectiveId) not present in mission objectives \(request.mission.objectiveIds)."
                )
            }
        }
        for wordAssessment in response.wordAssessments {
            guard allowedObjectiveIds.contains(wordAssessment.objectiveId) else {
                throw PracticeFailure(
                    code: .domainValidation,
                    message: "ObjectiveId \(wordAssessment.objectiveId) in word assessment not present in mission objectives \(request.mission.objectiveIds)."
                )
            }
        }
    }

    private func validateQuotedSpans(
        response: PracticeAIResponse,
        acceptedText: String
    ) throws {
        for wordAssessment in response.wordAssessments {
            if let span = wordAssessment.quotedSpan {
                guard !span.isEmpty else {
                    throw PracticeFailure(
                        code: .domainValidation,
                        message: "Quoted span cannot be empty string when provided."
                    )
                }
                guard acceptedText.contains(span) else {
                    throw PracticeFailure(
                        code: .domainValidation,
                        message: "Quoted span \"\(span)\" does not exist in accepted text: \"\(acceptedText)\"."
                    )
                }
            }
        }
    }

    // MARK: - Transformation Helpers

    private func resolveReliability(
        for status: PracticeTranscriptStatus
    ) -> PracticeTranscriptReliability {
        switch status {
        case .needsConfirmation:
            return .needsConfirmation
        case .uncertain:
            return .unavailable
        case .final, .edited, .notApplicable:
            return .usable
        }
    }

    private func buildEvidence(
        response: PracticeAIResponse,
        request: PracticeAIRequest,
        turn: PracticeTurn,
        exposures: [SupportExposure],
        uncertainWordIds: Set<Int64>
    ) -> [WordUseEvidence] {
        let reliability = resolveReliability(for: turn.transcriptStatus)
        return response.wordAssessments.map { wordAssessment in
            let isPrimed = supportPolicy.isPrimed(
                wordId: wordAssessment.wordId,
                exposures: exposures,
                uncertainWordIds: uncertainWordIds,
                before: turn.timestamp
            )

            let applicableExposureIds = exposures.filter { exposure in
                (exposure.wordIds.contains(wordAssessment.wordId) || exposure.wordIds.isEmpty) &&
                exposure.presentedAt <= turn.timestamp
            }.map(\.id)

            let matchingObjective = response.objectiveAssessments.first {
                $0.objectiveId == wordAssessment.objectiveId
            }
            let intentVerdict = matchingObjective?.intentVerdict ?? .uncertain

            return WordUseEvidence(
                id: UUID(),
                sessionId: turn.sessionId,
                turnId: turn.id,
                wordId: wordAssessment.wordId,
                objectiveId: wordAssessment.objectiveId,
                usageVerdict: wordAssessment.usageVerdict,
                intentVerdict: intentVerdict,
                transcriptReliability: reliability,
                supportExposureIds: applicableExposureIds,
                primed: isPrimed,
                contextFamily: request.mission.contextFamily,
                inputMode: turn.inputMode,
                quotedSpan: wordAssessment.quotedSpan,
                assessmentVersion: 1,
                providerIdentity: request.providerIdentity,
                status: .valid,
                timestamp: turn.timestamp,
                turnRevision: turn.sessionRevision,
                opportunityId: "opp_\(wordAssessment.objectiveId)_\(wordAssessment.wordId)"
            )
        }
    }

    private func buildObjectiveResults(
        from assessments: [PracticeObjectiveAssessment]
    ) -> [PracticeObjectiveResult] {
        assessments.map { obj in
            PracticeObjectiveResult(
                objectiveId: obj.objectiveId,
                intentVerdict: obj.intentVerdict,
                opportunityObserved: obj.intentVerdict != .uncertain
            )
        }
    }
}
