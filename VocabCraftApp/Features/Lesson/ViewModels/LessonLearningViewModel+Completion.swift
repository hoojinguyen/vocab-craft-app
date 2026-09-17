import Foundation

// MARK: - Lesson Completion & Persistence
extension LessonLearningViewModel {
    func finishLesson() {
        guard completionTask == nil else { return }
        ttsService.stop()
        cleanup()

        let stars = mistakeCount == 0 ? 3 : (mistakeCount <= 2 ? 2 : 1)
        let isCheckpoint = stageId.hasPrefix("checkpoint_")
        let xpEarned = isCheckpoint ? 80 : 25
        let accuracy = totalAnswered > 0 ? Double(correctAnswers) / Double(totalAnswered) : 1.0

        let summaryModel = LessonSummaryModel(
            stageId: stageId,
            deckId: deckId,
            stars: stars,
            xpEarned: xpEarned,
            accuracyFraction: accuracy,
            learnedWords: words,
            weakWordIds: Array(weakWordIds)
        )

        self.summary = summaryModel
        self.steps.append(.summary(summary: summaryModel))

        self.completionTask = Task {
            do {
                let result = try await completeLessonUseCase.execute(
                    stageId: stageId,
                    deckId: deckId,
                    stars: stars,
                    weakWordIds: Array(weakWordIds),
                    progressFraction: 1.0
                )
                await MainActor.run {
                    self.isCompleted = true
                }
                return result
            } catch {
                await MainActor.run {
                    self.persistenceError = error
                    self.completionTask = nil
                }
                throw error
            }
        }
    }

    @discardableResult
    public func retryCompletion() async throws -> LessonCompletionResult? {
        if isCompleted {
            return nil
        }
        if let completionTask {
            return try await completionTask.value
        }
        guard let summary else { return nil }
        persistenceError = nil
        let task = Task {
            do {
                let result = try await completeLessonUseCase.execute(
                    stageId: stageId,
                    deckId: deckId,
                    stars: summary.stars,
                    weakWordIds: Array(weakWordIds),
                    progressFraction: 1.0
                )
                await MainActor.run {
                    self.isCompleted = true
                }
                return result
            } catch {
                await MainActor.run {
                    self.persistenceError = error
                    self.completionTask = nil
                }
                throw error
            }
        }
        self.completionTask = task
        return try await task.value
    }

    @discardableResult
    public func awaitCompletion() async throws -> LessonCompletionResult? {
        if let completionTask {
            return try await completionTask.value
        }
        if !isCompleted && summary != nil {
            return try await retryCompletion()
        }
        return nil
    }
}
