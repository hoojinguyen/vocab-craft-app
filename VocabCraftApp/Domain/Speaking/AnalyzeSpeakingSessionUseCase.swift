import Foundation

public actor AnalyzeSpeakingSessionUseCase {
    private struct Flight {
        let id: UUID
        let task: Task<SpeakingSessionStatus, Never>
        var callers: Int
    }

    private let repository: any SpeakingRepositoryProtocol
    private let analyzer: any SpeakingAnalyzing
    private let storage: SpeakingAudioStorage
    private var flights: [UUID: Flight] = [:]

    public init(repository: any SpeakingRepositoryProtocol, analyzer: any SpeakingAnalyzing, storage: SpeakingAudioStorage) {
        self.repository = repository
        self.analyzer = analyzer
        self.storage = storage
    }

    @discardableResult
    public func execute(sessionId: UUID) async -> SpeakingSessionStatus {
        let flight: Flight
        if var existing = flights[sessionId] {
            existing.callers += 1
            flights[sessionId] = existing
            flight = existing
        } else {
            let repository = repository
            let analyzer = analyzer
            let storage = storage
            let task = Task {
                await Self.perform(sessionId: sessionId, repository: repository, analyzer: analyzer, storage: storage)
            }
            let created = Flight(id: UUID(), task: task, callers: 1)
            flights[sessionId] = created
            flight = created
        }

        let status = await flight.task.value
        finishCaller(sessionId: sessionId, flightID: flight.id)
        return status
    }

    private func finishCaller(sessionId: UUID, flightID: UUID) {
        guard var flight = flights[sessionId], flight.id == flightID else { return }
        flight.callers -= 1
        if flight.callers == 0 {
            flights[sessionId] = nil
        } else {
            flights[sessionId] = flight
        }
    }

    private nonisolated static func perform(
        sessionId: UUID,
        repository: any SpeakingRepositoryProtocol,
        analyzer: any SpeakingAnalyzing,
        storage: SpeakingAudioStorage
    ) async -> SpeakingSessionStatus {
        do {
            guard var session = try await repository.session(id: sessionId) else { return .analysisFailed }
            if session.status == .analyzed, session.analysis != nil { return .analyzed }
            if session.status == .tooShort { return .tooShort }

            guard session.learnerTurnCount >= 2 else {
                return await persist(
                    sessionId: sessionId, status: .tooShort, analysis: nil,
                    repository: repository, storage: storage
                )
            }

            guard let fileName = session.audioFileName else {
                return await persist(
                    sessionId: sessionId, status: .analysisFailed, analysis: nil,
                    repository: repository, storage: storage
                )
            }

            let audioURL = storage.url(for: fileName)
            guard audioURL.lastPathComponent == fileName,
                  FileManager.default.fileExists(atPath: audioURL.path) else {
                session.audioFileName = nil
                try await repository.save(session)
                return await persist(
                    sessionId: sessionId, status: .analysisFailed, analysis: nil,
                    repository: repository, storage: storage
                )
            }

            do {
                let analysis = try await analyzer.analyze(session, audioURL: audioURL)
                return await persist(
                    sessionId: sessionId, status: .analyzed, analysis: analysis,
                    repository: repository, storage: storage
                )
            } catch let error as SpeakingAnalysisError where error == .audioUnavailable {
                session.audioFileName = nil
                try await repository.save(session)
                return await persist(
                    sessionId: sessionId, status: .analysisFailed, analysis: nil,
                    repository: repository, storage: storage
                )
            } catch {
                return await persist(
                    sessionId: sessionId, status: .analysisFailed, analysis: nil,
                    repository: repository, storage: storage
                )
            }
        } catch {
            return .analysisFailed
        }
    }

    private nonisolated static func persist(
        sessionId: UUID,
        status: SpeakingSessionStatus,
        analysis: SpeakingAnalysis?,
        repository: any SpeakingRepositoryProtocol,
        storage: SpeakingAudioStorage
    ) async -> SpeakingSessionStatus {
        do {
            try await repository.updateAnalysis(sessionId: sessionId, status: status, analysis: analysis)
        } catch {
            return .analysisFailed
        }

        do {
            let detachedFileNames = try await repository.detachAudio(keepingLatest: 20)
            storage.delete(fileNames: detachedFileNames)
        } catch {
            // Retention failure must not undo the analysis status already persisted.
        }
        return status
    }
}
