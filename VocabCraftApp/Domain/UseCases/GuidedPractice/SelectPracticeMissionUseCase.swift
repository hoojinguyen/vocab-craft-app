import Foundation

/// Selects an optimal communicative practice mission tailored to the learner's vocabulary mastery,
/// historical communication evidence, and pedagogical transfer readiness.
public struct SelectPracticeMissionUseCase: Sendable {
    public init() {}

    private struct CandidateWord: Sendable {
        let wordId: Int64
        let priorityTier: Int // 1: assisted-due, 2: communication-due, 3: no-evidence, 4: not-due
        let selectionReason: PracticeSelectionReason
        let nextReviewDate: Date
        let lastReviewDate: Date
        let isTransferCandidate: Bool
        let previousContextFamilies: Set<PracticeContextFamily>
        let isReviewEligible: Bool
    }

    /// Selects a practice mission from available templates given the current learning context.
    ///
    /// - Parameters:
    ///   - context: Aggregated learner progress snapshots, vocabulary items, and evidence history.
    ///   - templates: Available curated templates from the catalog.
    ///   - now: Current timestamp for temporal scheduling and due evaluations.
    /// - Returns: `.mission` if a valid assignment is constructed, `.needsVocabulary` if insufficient
    ///   learned words exist, or `.noCompatibleTemplate` if no template supports the candidates.
    public func select(
        context: PracticeLearningContext,
        templates: [PracticeTemplate],
        now: Date
    ) -> PracticeSelectionResult {
        let snapshotsById = Dictionary(uniqueKeysWithValues: context.words.map { ($0.wordId, $0) })
        let eligibleProgress = filterEligibleProgress(from: context, snapshotsById: snapshotsById)

        guard !eligibleProgress.isEmpty else {
            return .needsVocabulary
        }

        var candidates = buildCandidates(from: eligibleProgress, context: context, now: now)
        sortCandidates(&candidates)

        for primaryCandidate in candidates {
            let compatibleTemplates = templates.filter { template in
                template.supportedWordSenses.contains { $0.wordId == primaryCandidate.wordId }
            }
            guard !compatibleTemplates.isEmpty else { continue }

            let rankedTemplates = rankTemplates(
                compatibleTemplates: compatibleTemplates,
                for: primaryCandidate,
                allCandidates: candidates
            )

            for chosenTemplate in rankedTemplates {
                if let mission = buildMission(
                    template: chosenTemplate,
                    primaryCandidate: primaryCandidate,
                    candidates: candidates,
                    snapshotsById: snapshotsById,
                    now: now
                ) {
                    return .mission(mission)
                }
            }
        }

        return .noCompatibleTemplate
    }

    // MARK: - Private Decomposition Helpers

    private func filterEligibleProgress(
        from context: PracticeLearningContext,
        snapshotsById: [Int64: PracticeWordSnapshot]
    ) -> [UserWordProgressData] {
        var eligibleProgress: [UserWordProgressData] = []
        for progressRecord in context.progress {
            guard snapshotsById[progressRecord.wordId] != nil else { continue }
            if progressRecord.totalReviews > 0 || progressRecord.masteryLevel > 0 {
                eligibleProgress.append(progressRecord)
            }
        }
        return eligibleProgress
    }

    private func buildCandidates(
        from eligibleProgress: [UserWordProgressData],
        context: PracticeLearningContext,
        now: Date
    ) -> [CandidateWord] {
        var commByWordId: [Int64: [CommunicationProgress]] = [:]
        for communicationRecord in context.communication {
            commByWordId[communicationRecord.wordId, default: []].append(communicationRecord)
        }

        var evidenceFamiliesByWordId: [Int64: Set<PracticeContextFamily>] = [:]
        for evidenceRecord in context.evidence where evidenceRecord.status == .valid {
            evidenceFamiliesByWordId[evidenceRecord.wordId, default: []].insert(evidenceRecord.contextFamily)
        }

        var candidates: [CandidateWord] = []
        for progressRecord in eligibleProgress {
            let commRecords = commByWordId[progressRecord.wordId] ?? []
            let previousFamilies = evidenceFamiliesByWordId[progressRecord.wordId] ?? []
            let highestStage = commRecords.map(\.stage).max() ?? .noEvidence
            let isTransfer = highestStage >= .independentFamiliar
            let isReview = isTransfer || progressRecord.masteryLevel >= 4 || progressRecord.isMastered

            let (tier, reason) = evaluatePriorityTier(
                commRecords: commRecords,
                isTransfer: isTransfer,
                now: now
            )

            candidates.append(
                CandidateWord(
                    wordId: progressRecord.wordId,
                    priorityTier: tier,
                    selectionReason: reason,
                    nextReviewDate: progressRecord.nextReviewDate,
                    lastReviewDate: progressRecord.lastReviewDate,
                    isTransferCandidate: isTransfer,
                    previousContextFamilies: previousFamilies,
                    isReviewEligible: isReview
                )
            )
        }
        return candidates
    }

    private func evaluatePriorityTier(
        commRecords: [CommunicationProgress],
        isTransfer: Bool,
        now: Date
    ) -> (tier: Int, reason: PracticeSelectionReason) {
        let practicingRecords = commRecords.filter { $0.stage == .practicing }
        let independentRecords = commRecords.filter { $0.stage == .independentFamiliar || $0.stage == .transferred }

        if practicingRecords.contains(where: { ($0.nextPracticeAt ?? .distantPast) <= now }) {
            return (1, .retryAssisted)
        }
        if independentRecords.contains(where: { ($0.nextPracticeAt ?? .distantPast) <= now }) {
            return (2, .communicationDue)
        }
        if commRecords.isEmpty || commRecords.allSatisfy({ $0.stage == .noEvidence }) {
            return (3, .noCommunicationEvidence)
        }
        return (4, isTransfer ? .communicationDue : .retryAssisted)
    }

    private func sortCandidates(_ candidates: inout [CandidateWord]) {
        candidates.sort { lhs, rhs in
            if lhs.priorityTier != rhs.priorityTier {
                return lhs.priorityTier < rhs.priorityTier
            }
            if lhs.nextReviewDate != rhs.nextReviewDate {
                return lhs.nextReviewDate < rhs.nextReviewDate
            }
            if lhs.lastReviewDate != rhs.lastReviewDate {
                return lhs.lastReviewDate < rhs.lastReviewDate
            }
            return lhs.wordId < rhs.wordId
        }
    }

    private func rankTemplates(
        compatibleTemplates: [PracticeTemplate],
        for primaryCandidate: CandidateWord,
        allCandidates: [CandidateWord]
    ) -> [PracticeTemplate] {
        compatibleTemplates.sorted { templateA, templateB in
            if primaryCandidate.isTransferCandidate {
                let aIsNovel = !primaryCandidate.previousContextFamilies.contains(templateA.contextFamily)
                let bIsNovel = !primaryCandidate.previousContextFamilies.contains(templateB.contextFamily)

                if aIsNovel != bIsNovel {
                    return aIsNovel && !bIsNovel
                }

                let aTransfer = templateA.difficultyBounds.min.contextNovelty >= 1
                let bTransfer = templateB.difficultyBounds.min.contextNovelty >= 1
                if aTransfer != bTransfer {
                    return aTransfer && !bTransfer
                }
            } else {
                let aBasic = templateA.difficultyBounds.min.contextNovelty == 0
                let bBasic = templateB.difficultyBounds.min.contextNovelty == 0
                if aBasic != bBasic {
                    return aBasic && !bBasic
                }
            }

            let aSupportCount = allCandidates.filter { candidate in
                templateA.supportedWordSenses.contains { $0.wordId == candidate.wordId }
            }.count
            let bSupportCount = allCandidates.filter { candidate in
                templateB.supportedWordSenses.contains { $0.wordId == candidate.wordId }
            }.count

            if aSupportCount != bSupportCount {
                return aSupportCount > bSupportCount
            }

            return templateA.id < templateB.id
        }
    }

    private func buildMission(
        template: PracticeTemplate,
        primaryCandidate: CandidateWord,
        candidates: [CandidateWord],
        snapshotsById: [Int64: PracticeWordSnapshot],
        now: Date
    ) -> PracticeMission? {
        var targetWordIds: [Int64] = [primaryCandidate.wordId]
        var uniqueReasons: [PracticeSelectionReason] = [primaryCandidate.selectionReason]
        var focusCount = primaryCandidate.isReviewEligible ? 0 : 1
        var reviewCount = primaryCandidate.isReviewEligible ? 1 : 0

        for otherCandidate in candidates where otherCandidate.wordId != primaryCandidate.wordId {
            guard targetWordIds.count < 3 else { break }
            guard template.supportedWordSenses.contains(where: { $0.wordId == otherCandidate.wordId }) else {
                continue
            }

            if otherCandidate.isReviewEligible {
                // At most 1 review word allowed in a mission
                guard reviewCount < 1 else { continue }
                targetWordIds.append(otherCandidate.wordId)
                reviewCount += 1
            } else {
                // At most 2 focus words allowed in a mission
                guard focusCount < 2 else { continue }
                targetWordIds.append(otherCandidate.wordId)
                focusCount += 1
            }

            if !uniqueReasons.contains(otherCandidate.selectionReason) {
                uniqueReasons.append(otherCandidate.selectionReason)
            }
        }

        let missionSnapshots = targetWordIds.compactMap { snapshotsById[$0] }
        guard missionSnapshots.count == targetWordIds.count else { return nil }

        return try? PracticeMission(
            id: UUID(),
            templateId: template.id,
            templateVersion: template.version,
            targetWordIds: targetWordIds,
            wordSnapshots: missionSnapshots,
            objectiveIds: template.objectiveIds,
            contextFamily: template.contextFamily,
            difficulty: template.difficultyBounds.min,
            selectionReasons: uniqueReasons,
            policyVersion: 1,
            createdAt: now
        )
    }
}
