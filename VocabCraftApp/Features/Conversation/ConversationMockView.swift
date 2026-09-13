#if DEBUG
import CraftUIKit
import SwiftUI

/// Development-only surface. No microphone or network is used.
public struct ConversationMockView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @State private var session: ConversationMockSession?
    @State private var translated: Set<String> = []
    @State private var followsCurrent = true
    @State private var simulateFailure = false
    @State private var confirmsReplacement = false
    private let onClose: () -> Void

    public init(onClose: @escaping () -> Void = {}) { self.onClose = onClose }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            HStack {
                Text(AppStrings.Conversation.title).font(theme.typography.titleMedium)
                Spacer()
                CraftButton(AppStrings.Conversation.close, variant: .ghost, size: .sm) {
                    session?.pause()
                    onClose()
                }
            }
            Text(AppStrings.Conversation.simulationNotice)
                .font(theme.typography.caption).foregroundStyle(theme.colors.textSecondary)
            if let session {
                transcript(session)
                ConversationMockControls(session: session, simulateFailure: $simulateFailure,
                                         onGenerate: requestReplacement)
            } else {
                Text(AppStrings.Lesson.loadErrorText)
            }
        }
        .padding(theme.spacing.base)
        .background(theme.colors.canvasBackground)
        .foregroundStyle(theme.colors.textPrimary)
        .task { loadSession() }
        .task(id: session?.pendingResolutionToken) { await simulateTurn() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session?.pause() }
        }
        .onDisappear { session?.pause() }
        .confirmationDialog(AppStrings.Conversation.confirmReplaceTitle, isPresented: $confirmsReplacement) {
            Button(AppStrings.Conversation.replace) { generate() }
            Button(AppStrings.Conversation.cancel, role: .cancel) {}
        } message: { Text(AppStrings.Conversation.confirmReplaceMessage) }
    }

    private func transcript(_ session: ConversationMockSession) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text(verbatim: locale.language.languageCode?.identifier == "vi"
                         ? session.conversation.situationVi : session.conversation.situation)
                        .font(theme.typography.titleLarge)
                    ForEach(session.conversation.turns) { turn in
                        CraftConversationTurnView(
                            speaker: turn.speaker == .speakerA ? .speakerA : .speakerB,
                            english: turn.english, vietnamese: turn.vietnamese,
                            isCurrent: turn.id == session.activeTurnID,
                            isPassed: session.passedTurnIDs.contains(turn.id),
                            showsTranslation: translated.contains(turn.id)
                        ) {
                            if translated.contains(turn.id) { translated.remove(turn.id) } else { translated.insert(turn.id) }
                        }
                        .id(turn.id)
                    }
                }
            }
            .simultaneousGesture(DragGesture().onChanged { _ in followsCurrent = false })
            .onChange(of: session.activeTurnID) { _, turn in
                if followsCurrent, let turn { proxy.scrollTo(turn, anchor: .center) }
            }
            .onChange(of: session.conversation.id) { _, _ in
                translated = []
                followsCurrent = true
                if let first = session.conversation.turns.first { proxy.scrollTo(first.id, anchor: .top) }
            }
            .overlay(alignment: .bottomTrailing) {
                if !followsCurrent {
                    CraftButton(AppStrings.Conversation.returnToCurrent, variant: .secondary, size: .sm) {
                        followsCurrent = true
                        if let turn = session.activeTurnID { proxy.scrollTo(turn, anchor: .center) }
                    }
                }
            }
        }
    }

    private func loadSession() {
        guard session == nil, let scripts = try? SampleConversationRepository.loadScripts(),
              let first = scripts.first else { return }
        let storage = ConversationUserDefaultsStorage()
        let script = scripts.first { $0.id == storage.load()?.conversationID } ?? first
        session = ConversationMockSession.restore(conversation: script, storage: storage)
            ?? ConversationMockSession(conversation: script, storage: storage)
    }

    private func simulateTurn() async {
        guard let session else { return }
        let token = session.pendingResolutionToken
        let phase = session.phase
        switch phase {
        case .partnerPlayback, .listening: break
        default: return
        }
        do { try await Task.sleep(for: .seconds(2)) } catch { return }
        guard !Task.isCancelled, token == session.pendingResolutionToken else { return }
        switch phase {
        case .partnerPlayback: session.finishPartnerTurn()
        case .listening: session.resolve(session.selectedOutcome, token: token)
        default: break
        }
    }

    private func requestReplacement() {
        guard let session else { return }
        if session.phase != .preview && session.phase != .completed { confirmsReplacement = true } else { generate() }
    }

    private func generate() {
        Task {
            await session?.requestNewConversation(from: SampleConversationRepository(simulatesFailure: simulateFailure))
        }
    }
}

#Preview {
    ConversationMockView()
}
#endif
