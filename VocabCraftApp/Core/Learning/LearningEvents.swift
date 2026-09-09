import Foundation

// MARK: - Enums

public enum ExerciseKind: String, Codable, Sendable, CaseIterable {
    case recognitionChoice = "recognition_choice"
    case recallText = "recall_text"
    case recallSpeech = "recall_speech"
    case applicationText = "application_text"
    case applicationSpeech = "application_speech"
    case pronunciation
}

public enum Capability: String, Codable, Sendable, CaseIterable {
    case recognition
    case recall
    case application
}

public enum InputMode: String, Codable, Sendable, CaseIterable {
    case text
    case audio
}

public enum ResponseMode: String, Codable, Sendable, CaseIterable {
    case choice
    case text
    case speech
}

public enum ExerciseOutcome: String, Codable, Sendable, CaseIterable {
    case correct
    case incorrect
    case unscored
}

// MARK: - Validation Helpers

enum LearningEventValidation {
    static func validateExerciseConstraints<K: CodingKey>(
        exerciseKind: ExerciseKind,
        capability: Capability?,
        container: KeyedDecodingContainer<K>,
        capabilityKey: K
    ) throws {
        if exerciseKind == .pronunciation {
            guard capability == nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: capabilityKey,
                    in: container,
                    debugDescription: "Pronunciation-only must have capability null"
                )
            }
        } else {
            guard capability != nil else {
                throw DecodingError.dataCorruptedError(
                    forKey: capabilityKey,
                    in: container,
                    debugDescription: "Non-pronunciation exercise must have non-null capability"
                )
            }
        }
    }

    struct ScoreValidationContext {
        let evaluatorVersion: String
        let outcome: ExerciseOutcome
        let scoreMilli: Int?
        let pronunciationScoreMilli: Int?
    }

    static func validateEvaluatorAndScores<K: CodingKey>(
        context: ScoreValidationContext,
        container: KeyedDecodingContainer<K>,
        outcomeKey: K,
        scoreMilliKey: K,
        pronunciationScoreMilliKey: K
    ) throws {
        if context.evaluatorVersion == "unscored" && context.outcome != .unscored {
            throw DecodingError.dataCorruptedError(
                forKey: outcomeKey,
                in: container,
                debugDescription: "Unscored cannot be evaluated with outcome correct/incorrect"
            )
        }

        if context.outcome == .unscored && context.scoreMilli != nil {
            throw DecodingError.dataCorruptedError(
                forKey: scoreMilliKey,
                in: container,
                debugDescription: "score_milli must be null when outcome is unscored"
            )
        }

        if let score = context.scoreMilli, !(0...1000).contains(score) {
            throw DecodingError.dataCorruptedError(
                forKey: scoreMilliKey,
                in: container,
                debugDescription: "score_milli must be between 0 and 1000"
            )
        }

        if let pronScore = context.pronunciationScoreMilli, !(0...1000).contains(pronScore) {
            throw DecodingError.dataCorruptedError(
                forKey: pronunciationScoreMilliKey,
                in: container,
                debugDescription: "pronunciation_score_milli must be between 0 and 1000"
            )
        }
    }
}

// MARK: - PracticeAttempt

public struct PracticeAttempt: Codable, Hashable, Sendable, Identifiable {
    public var id: AttemptID { attemptID }
    public let eventType: String
    public let attemptID: AttemptID
    public let originProfileID: ProfileID
    public let deviceID: DeviceID
    public let deviceSequence: Int
    public let eventSchemaVersion: Int
    public let senseID: SenseID
    public let senseRevision: Int
    public let contentVersion: Int
    public let lessonID: LessonID?
    public let lessonRevision: Int?
    public let exerciseKind: ExerciseKind
    public let capability: Capability?
    public let inputModes: [InputMode]
    public let responseMode: ResponseMode
    public let outcome: ExerciseOutcome
    public let scoreMilli: Int?
    public let hintCount: Int
    public let retryCount: Int
    public let responseTimeMs: Int
    public let occurredAt: String
    public let elapsedSincePreviousMs: Int?
    public let clientSRSAlgorithmVersion: String
    public let evaluatorVersion: String
    public let pronunciationScoreMilli: Int?

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case attemptID = "attempt_id"
        case originProfileID = "origin_profile_id"
        case deviceID = "device_id"
        case deviceSequence = "device_sequence"
        case eventSchemaVersion = "event_schema_version"
        case senseID = "sense_id"
        case senseRevision = "sense_revision"
        case contentVersion = "content_version"
        case lessonID = "lesson_id"
        case lessonRevision = "lesson_revision"
        case exerciseKind = "exercise_kind"
        case capability
        case inputModes = "input_modes"
        case responseMode = "response_mode"
        case outcome
        case scoreMilli = "score_milli"
        case hintCount = "hint_count"
        case retryCount = "retry_count"
        case responseTimeMs = "response_time_ms"
        case occurredAt = "occurred_at"
        case elapsedSincePreviousMs = "elapsed_since_previous_ms"
        case clientSRSAlgorithmVersion = "client_srs_algorithm_version"
        case evaluatorVersion = "evaluator_version"
        case pronunciationScoreMilli = "pronunciation_score_milli"
    }

    public init(
        attemptID: AttemptID,
        originProfileID: ProfileID,
        deviceID: DeviceID,
        deviceSequence: Int,
        eventSchemaVersion: Int = 1,
        senseID: SenseID,
        senseRevision: Int,
        contentVersion: Int,
        lessonID: LessonID? = nil,
        lessonRevision: Int? = nil,
        exerciseKind: ExerciseKind,
        capability: Capability?,
        inputModes: [InputMode],
        responseMode: ResponseMode,
        outcome: ExerciseOutcome,
        scoreMilli: Int? = nil,
        hintCount: Int = 0,
        retryCount: Int = 0,
        responseTimeMs: Int,
        occurredAt: String,
        elapsedSincePreviousMs: Int? = nil,
        clientSRSAlgorithmVersion: String = "none",
        evaluatorVersion: String,
        pronunciationScoreMilli: Int? = nil
    ) {
        self.eventType = "practice_attempt"
        self.attemptID = attemptID
        self.originProfileID = originProfileID
        self.deviceID = deviceID
        self.deviceSequence = deviceSequence
        self.eventSchemaVersion = eventSchemaVersion
        self.senseID = senseID
        self.senseRevision = senseRevision
        self.contentVersion = contentVersion
        self.lessonID = lessonID
        self.lessonRevision = lessonRevision
        self.exerciseKind = exerciseKind
        self.capability = capability
        self.inputModes = inputModes
        self.responseMode = responseMode
        self.outcome = outcome
        self.scoreMilli = scoreMilli
        self.hintCount = hintCount
        self.retryCount = retryCount
        self.responseTimeMs = responseTimeMs
        self.occurredAt = occurredAt
        self.elapsedSincePreviousMs = elapsedSincePreviousMs
        self.clientSRSAlgorithmVersion = clientSRSAlgorithmVersion
        self.evaluatorVersion = evaluatorVersion
        self.pronunciationScoreMilli = pronunciationScoreMilli
    }

    public init(
        submission: AttemptSubmission,
        originProfileID: ProfileID,
        deviceID: DeviceID,
        deviceSequence: Int
    ) {
        self.init(
            attemptID: submission.attemptID,
            originProfileID: originProfileID,
            deviceID: deviceID,
            deviceSequence: deviceSequence,
            eventSchemaVersion: submission.eventSchemaVersion,
            senseID: submission.senseID,
            senseRevision: submission.senseRevision,
            contentVersion: submission.contentVersion,
            lessonID: submission.lessonID,
            lessonRevision: submission.lessonRevision,
            exerciseKind: submission.exerciseKind,
            capability: submission.capability,
            inputModes: submission.inputModes,
            responseMode: submission.responseMode,
            outcome: submission.outcome,
            scoreMilli: submission.scoreMilli,
            hintCount: submission.hintCount,
            retryCount: submission.retryCount,
            responseTimeMs: submission.responseTimeMs,
            occurredAt: submission.occurredAt,
            elapsedSincePreviousMs: submission.elapsedSincePreviousMs,
            clientSRSAlgorithmVersion: submission.clientSRSAlgorithmVersion,
            evaluatorVersion: submission.evaluatorVersion,
            pronunciationScoreMilli: submission.pronunciationScoreMilli
        )
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        eventType = try container.decode(String.self, forKey: .eventType)
        guard eventType == "practice_attempt" else {
            throw DecodingError.dataCorruptedError(forKey: .eventType, in: container, debugDescription: "event_type must be 'practice_attempt'")
        }

        attemptID = try container.decode(AttemptID.self, forKey: .attemptID)
        originProfileID = try container.decode(ProfileID.self, forKey: .originProfileID)
        deviceID = try container.decode(DeviceID.self, forKey: .deviceID)

        deviceSequence = try container.decode(Int.self, forKey: .deviceSequence)
        guard deviceSequence >= 1 else {
            throw DecodingError.dataCorruptedError(forKey: .deviceSequence, in: container, debugDescription: "device_sequence must be >= 1")
        }

        eventSchemaVersion = try container.decode(Int.self, forKey: .eventSchemaVersion)
        guard eventSchemaVersion == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .eventSchemaVersion, in: container, debugDescription: "event_schema_version must be 1")
        }

        senseID = try container.decode(SenseID.self, forKey: .senseID)
        senseRevision = try container.decode(Int.self, forKey: .senseRevision)
        contentVersion = try container.decode(Int.self, forKey: .contentVersion)
        lessonID = try container.decodeIfPresent(LessonID.self, forKey: .lessonID)
        lessonRevision = try container.decodeIfPresent(Int.self, forKey: .lessonRevision)
        exerciseKind = try container.decode(ExerciseKind.self, forKey: .exerciseKind)
        capability = try container.decodeIfPresent(Capability.self, forKey: .capability)

        try LearningEventValidation.validateExerciseConstraints(
            exerciseKind: exerciseKind,
            capability: capability,
            container: container,
            capabilityKey: .capability
        )

        inputModes = try container.decode([InputMode].self, forKey: .inputModes)
        guard !inputModes.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .inputModes, in: container, debugDescription: "input_modes must not be empty")
        }

        responseMode = try container.decode(ResponseMode.self, forKey: .responseMode)
        outcome = try container.decode(ExerciseOutcome.self, forKey: .outcome)
        scoreMilli = try container.decodeIfPresent(Int.self, forKey: .scoreMilli)
        hintCount = try container.decode(Int.self, forKey: .hintCount)
        retryCount = try container.decode(Int.self, forKey: .retryCount)
        responseTimeMs = try container.decode(Int.self, forKey: .responseTimeMs)
        occurredAt = try container.decode(String.self, forKey: .occurredAt)
        elapsedSincePreviousMs = try container.decodeIfPresent(Int.self, forKey: .elapsedSincePreviousMs)
        clientSRSAlgorithmVersion = try container.decode(String.self, forKey: .clientSRSAlgorithmVersion)
        evaluatorVersion = try container.decode(String.self, forKey: .evaluatorVersion)
        pronunciationScoreMilli = try container.decodeIfPresent(Int.self, forKey: .pronunciationScoreMilli)

        let scoreContext = LearningEventValidation.ScoreValidationContext(
            evaluatorVersion: evaluatorVersion,
            outcome: outcome,
            scoreMilli: scoreMilli,
            pronunciationScoreMilli: pronunciationScoreMilli
        )
        try LearningEventValidation.validateEvaluatorAndScores(
            context: scoreContext,
            container: container,
            outcomeKey: .outcome,
            scoreMilliKey: .scoreMilli,
            pronunciationScoreMilliKey: .pronunciationScoreMilli
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(attemptID, forKey: .attemptID)
        try container.encode(originProfileID, forKey: .originProfileID)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encode(deviceSequence, forKey: .deviceSequence)
        try container.encode(eventSchemaVersion, forKey: .eventSchemaVersion)
        try container.encode(senseID, forKey: .senseID)
        try container.encode(senseRevision, forKey: .senseRevision)
        try container.encode(contentVersion, forKey: .contentVersion)
        try container.encodeIfPresent(lessonID, forKey: .lessonID)
        try container.encodeIfPresent(lessonRevision, forKey: .lessonRevision)
        try container.encode(exerciseKind, forKey: .exerciseKind)
        try container.encodeIfPresent(capability, forKey: .capability)
        try container.encode(inputModes, forKey: .inputModes)
        try container.encode(responseMode, forKey: .responseMode)
        try container.encode(outcome, forKey: .outcome)
        try container.encodeIfPresent(scoreMilli, forKey: .scoreMilli)
        try container.encode(hintCount, forKey: .hintCount)
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(responseTimeMs, forKey: .responseTimeMs)
        try container.encode(occurredAt, forKey: .occurredAt)
        try container.encodeIfPresent(elapsedSincePreviousMs, forKey: .elapsedSincePreviousMs)
        try container.encode(clientSRSAlgorithmVersion, forKey: .clientSRSAlgorithmVersion)
        try container.encode(evaluatorVersion, forKey: .evaluatorVersion)
        try container.encodeIfPresent(pronunciationScoreMilli, forKey: .pronunciationScoreMilli)
    }
}

// MARK: - LessonCompletion

public struct LessonCompletion: Codable, Hashable, Sendable, Identifiable {
    public var id: EventID { eventID }
    public let eventType: String
    public let eventID: EventID
    public let originProfileID: ProfileID
    public let deviceID: DeviceID
    public let deviceSequence: Int
    public let eventSchemaVersion: Int
    public let lessonID: LessonID
    public let lessonRevision: Int
    public let contentVersion: Int
    public let completedAt: String

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case eventID = "event_id"
        case originProfileID = "origin_profile_id"
        case deviceID = "device_id"
        case deviceSequence = "device_sequence"
        case eventSchemaVersion = "event_schema_version"
        case lessonID = "lesson_id"
        case lessonRevision = "lesson_revision"
        case contentVersion = "content_version"
        case completedAt = "completed_at"
    }

    public init(
        eventID: EventID,
        originProfileID: ProfileID,
        deviceID: DeviceID,
        deviceSequence: Int,
        eventSchemaVersion: Int = 1,
        lessonID: LessonID,
        lessonRevision: Int,
        contentVersion: Int,
        completedAt: String
    ) {
        self.eventType = "lesson_completion"
        self.eventID = eventID
        self.originProfileID = originProfileID
        self.deviceID = deviceID
        self.deviceSequence = deviceSequence
        self.eventSchemaVersion = eventSchemaVersion
        self.lessonID = lessonID
        self.lessonRevision = lessonRevision
        self.contentVersion = contentVersion
        self.completedAt = completedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        eventType = try container.decode(String.self, forKey: .eventType)
        guard eventType == "lesson_completion" else {
            throw DecodingError.dataCorruptedError(
                forKey: .eventType,
                in: container,
                debugDescription: "event_type must be 'lesson_completion'"
            )
        }

        eventID = try container.decode(EventID.self, forKey: .eventID)
        originProfileID = try container.decode(ProfileID.self, forKey: .originProfileID)
        deviceID = try container.decode(DeviceID.self, forKey: .deviceID)

        deviceSequence = try container.decode(Int.self, forKey: .deviceSequence)
        guard deviceSequence >= 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .deviceSequence,
                in: container,
                debugDescription: "device_sequence must be >= 1"
            )
        }

        eventSchemaVersion = try container.decode(Int.self, forKey: .eventSchemaVersion)
        guard eventSchemaVersion == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .eventSchemaVersion,
                in: container,
                debugDescription: "event_schema_version must be 1"
            )
        }

        lessonID = try container.decode(LessonID.self, forKey: .lessonID)
        lessonRevision = try container.decode(Int.self, forKey: .lessonRevision)
        contentVersion = try container.decode(Int.self, forKey: .contentVersion)
        completedAt = try container.decode(String.self, forKey: .completedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(eventID, forKey: .eventID)
        try container.encode(originProfileID, forKey: .originProfileID)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encode(deviceSequence, forKey: .deviceSequence)
        try container.encode(eventSchemaVersion, forKey: .eventSchemaVersion)
        try container.encode(lessonID, forKey: .lessonID)
        try container.encode(lessonRevision, forKey: .lessonRevision)
        try container.encode(contentVersion, forKey: .contentVersion)
        try container.encode(completedAt, forKey: .completedAt)
    }
}

// MARK: - Polymorphic LearningEvent

public enum LearningEvent: Codable, Sendable {
    case practiceAttempt(PracticeAttempt)
    case lessonCompletion(LessonCompletion)

    enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .eventType)
        switch type {
        case "practice_attempt":
            self = .practiceAttempt(try PracticeAttempt(from: decoder))
        case "lesson_completion":
            self = .lessonCompletion(try LessonCompletion(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .eventType,
                in: container,
                debugDescription: "Unsupported event_type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .practiceAttempt(let attempt):
            try attempt.encode(to: encoder)
        case .lessonCompletion(let completion):
            try completion.encode(to: encoder)
        }
    }
}

// MARK: - AttemptSubmission

public struct AttemptSubmission: Codable, Hashable, Sendable, Identifiable {
    public var id: AttemptID { attemptID }
    public let attemptID: AttemptID
    public let eventSchemaVersion: Int
    public let senseID: SenseID
    public let senseRevision: Int
    public let contentVersion: Int
    public let lessonID: LessonID?
    public let lessonRevision: Int?
    public let exerciseKind: ExerciseKind
    public let capability: Capability?
    public let inputModes: [InputMode]
    public let responseMode: ResponseMode
    public let outcome: ExerciseOutcome
    public let scoreMilli: Int?
    public let hintCount: Int
    public let retryCount: Int
    public let responseTimeMs: Int
    public let occurredAt: String
    public let elapsedSincePreviousMs: Int?
    public let clientSRSAlgorithmVersion: String
    public let evaluatorVersion: String
    public let pronunciationScoreMilli: Int?

    enum CodingKeys: String, CodingKey {
        case attemptID = "attempt_id"
        case eventSchemaVersion = "event_schema_version"
        case senseID = "sense_id"
        case senseRevision = "sense_revision"
        case contentVersion = "content_version"
        case lessonID = "lesson_id"
        case lessonRevision = "lesson_revision"
        case exerciseKind = "exercise_kind"
        case capability
        case inputModes = "input_modes"
        case responseMode = "response_mode"
        case outcome
        case scoreMilli = "score_milli"
        case hintCount = "hint_count"
        case retryCount = "retry_count"
        case responseTimeMs = "response_time_ms"
        case occurredAt = "occurred_at"
        case elapsedSincePreviousMs = "elapsed_since_previous_ms"
        case clientSRSAlgorithmVersion = "client_srs_algorithm_version"
        case evaluatorVersion = "evaluator_version"
        case pronunciationScoreMilli = "pronunciation_score_milli"
    }

    public init(
        attemptID: AttemptID,
        eventSchemaVersion: Int = 1,
        senseID: SenseID,
        senseRevision: Int,
        contentVersion: Int,
        lessonID: LessonID? = nil,
        lessonRevision: Int? = nil,
        exerciseKind: ExerciseKind,
        capability: Capability?,
        inputModes: [InputMode],
        responseMode: ResponseMode,
        outcome: ExerciseOutcome,
        scoreMilli: Int? = nil,
        hintCount: Int = 0,
        retryCount: Int = 0,
        responseTimeMs: Int,
        occurredAt: String,
        elapsedSincePreviousMs: Int? = nil,
        clientSRSAlgorithmVersion: String = "none",
        evaluatorVersion: String,
        pronunciationScoreMilli: Int? = nil
    ) {
        self.attemptID = attemptID
        self.eventSchemaVersion = eventSchemaVersion
        self.senseID = senseID
        self.senseRevision = senseRevision
        self.contentVersion = contentVersion
        self.lessonID = lessonID
        self.lessonRevision = lessonRevision
        self.exerciseKind = exerciseKind
        self.capability = capability
        self.inputModes = inputModes
        self.responseMode = responseMode
        self.outcome = outcome
        self.scoreMilli = scoreMilli
        self.hintCount = hintCount
        self.retryCount = retryCount
        self.responseTimeMs = responseTimeMs
        self.occurredAt = occurredAt
        self.elapsedSincePreviousMs = elapsedSincePreviousMs
        self.clientSRSAlgorithmVersion = clientSRSAlgorithmVersion
        self.evaluatorVersion = evaluatorVersion
        self.pronunciationScoreMilli = pronunciationScoreMilli
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        attemptID = try container.decode(AttemptID.self, forKey: .attemptID)
        eventSchemaVersion = try container.decode(Int.self, forKey: .eventSchemaVersion)
        guard eventSchemaVersion == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .eventSchemaVersion,
                in: container,
                debugDescription: "event_schema_version must be 1"
            )
        }

        senseID = try container.decode(SenseID.self, forKey: .senseID)
        senseRevision = try container.decode(Int.self, forKey: .senseRevision)
        contentVersion = try container.decode(Int.self, forKey: .contentVersion)
        lessonID = try container.decodeIfPresent(LessonID.self, forKey: .lessonID)
        lessonRevision = try container.decodeIfPresent(Int.self, forKey: .lessonRevision)
        exerciseKind = try container.decode(ExerciseKind.self, forKey: .exerciseKind)
        capability = try container.decodeIfPresent(Capability.self, forKey: .capability)

        try LearningEventValidation.validateExerciseConstraints(
            exerciseKind: exerciseKind,
            capability: capability,
            container: container,
            capabilityKey: .capability
        )

        inputModes = try container.decode([InputMode].self, forKey: .inputModes)
        guard !inputModes.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .inputModes,
                in: container,
                debugDescription: "input_modes must not be empty"
            )
        }

        responseMode = try container.decode(ResponseMode.self, forKey: .responseMode)
        outcome = try container.decode(ExerciseOutcome.self, forKey: .outcome)
        scoreMilli = try container.decodeIfPresent(Int.self, forKey: .scoreMilli)
        hintCount = try container.decode(Int.self, forKey: .hintCount)
        retryCount = try container.decode(Int.self, forKey: .retryCount)
        responseTimeMs = try container.decode(Int.self, forKey: .responseTimeMs)
        occurredAt = try container.decode(String.self, forKey: .occurredAt)
        elapsedSincePreviousMs = try container.decodeIfPresent(Int.self, forKey: .elapsedSincePreviousMs)
        clientSRSAlgorithmVersion = try container.decode(String.self, forKey: .clientSRSAlgorithmVersion)
        evaluatorVersion = try container.decode(String.self, forKey: .evaluatorVersion)
        pronunciationScoreMilli = try container.decodeIfPresent(Int.self, forKey: .pronunciationScoreMilli)

        let scoreContext = LearningEventValidation.ScoreValidationContext(
            evaluatorVersion: evaluatorVersion,
            outcome: outcome,
            scoreMilli: scoreMilli,
            pronunciationScoreMilli: pronunciationScoreMilli
        )
        try LearningEventValidation.validateEvaluatorAndScores(
            context: scoreContext,
            container: container,
            outcomeKey: .outcome,
            scoreMilliKey: .scoreMilli,
            pronunciationScoreMilliKey: .pronunciationScoreMilli
        )
    }

    public func enrich(
        originProfileID: ProfileID,
        deviceID: DeviceID,
        deviceSequence: Int
    ) -> PracticeAttempt {
        PracticeAttempt(
            submission: self,
            originProfileID: originProfileID,
            deviceID: deviceID,
            deviceSequence: deviceSequence
        )
    }
}
