#if DEBUG
@preconcurrency import AVFoundation
import CraftUIKit
import SwiftUI

public struct ConversationLiveView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @Environment(\.appContainer) private var appContainer

    @State private var session: ConversationLiveSession?
    @State private var translated: Set<String> = []
    @State private var followsCurrent: Bool = true
    @State private var confirmsReplacement: Bool = false
    @State private var hasLoadError: Bool = false

    private let onClose: () -> Void

    public init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            header
            notice

            if let session {
                transcript(session)
                ConversationLiveControls(
                    session: session,
                    onGenerate: requestReplacement
                )
            } else {
                Text(AppStrings.Lesson.loadErrorText)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.statusDanger)
            }
        }
        .padding(theme.spacing.base)
        .background(theme.colors.canvasBackground)
        .foregroundStyle(theme.colors.textPrimary)
        .task { loadSession() }
        .task(id: session?.pendingResolutionToken) {
            await session?.performCurrentTurn()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { session?.pause() }
        }
        .onDisappear { session?.pause() }
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
            let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let type = typeValue.flatMap(AVAudioSession.InterruptionType.init)
            if type == nil || type == .began {
                session?.pause()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { notification in
            let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            let reason = reasonValue.flatMap(AVAudioSession.RouteChangeReason.init)
            if reason == nil || reason == .oldDeviceUnavailable {
                session?.pause()
            }
        }
        #endif
        .confirmationDialog(AppStrings.Conversation.confirmReplaceTitle, isPresented: $confirmsReplacement) {
            Button(AppStrings.Conversation.replace) { generate() }
            Button(AppStrings.Conversation.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.Conversation.confirmReplaceMessage)
        }
    }

    private var header: some View {
        HStack {
            Text(AppStrings.Conversation.title)
                .font(theme.typography.titleMedium)
            Spacer()
            CraftButton(AppStrings.Conversation.close, variant: .ghost, size: .sm) {
                session?.pause()
                onClose()
            }
        }
    }

    @ViewBuilder private var notice: some View {
        #if targetEnvironment(simulator)
        Text(AppStrings.Conversation.simulationNotice)
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.textSecondary)
        #else
        Text(AppStrings.Conversation.Live.notice)
            .font(theme.typography.caption)
            .foregroundStyle(theme.colors.textSecondary)
        #endif
    }

    private func transcript(_ session: ConversationLiveSession) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text(verbatim: locale.language.languageCode?.identifier == "vi"
                         ? session.conversation.situationVi : session.conversation.situation)
                        .font(theme.typography.titleLarge)

                    ForEach(session.conversation.turns) { turn in
                        CraftConversationTurnView(
                            speaker: turn.speaker == .speakerA ? .speakerA : .speakerB,
                            english: turn.english,
                            vietnamese: turn.vietnamese,
                            isCurrent: turn.id == session.activeTurnID,
                            isPassed: session.passedTurnIDs.contains(turn.id),
                            showsTranslation: translated.contains(turn.id)
                        ) {
                            if translated.contains(turn.id) {
                                translated.remove(turn.id)
                            } else {
                                translated.insert(turn.id)
                            }
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
        guard session == nil else { return }
        guard let scripts = try? SampleConversationRepository.loadScripts(),
              let first = scripts.first else {
            hasLoadError = true
            return
        }
        let storage = ConversationUserDefaultsStorage(key: ConversationLiveSession.liveStorageKey)
        let script = scripts.first { $0.id == storage.load()?.conversationID } ?? first
        session = appContainer.makeConversationLiveSession(conversation: script, storage: storage)
    }

    private func requestReplacement() {
        guard let session else { return }
        if session.phase != .ready && session.phase != .completed {
            confirmsReplacement = true
        } else {
            generate()
        }
    }

    private func generate() {
        Task {
            await session?.requestNewConversation(from: SampleConversationRepository())
        }
    }
}

#Preview {
    ConversationLiveView()
}
#endif
