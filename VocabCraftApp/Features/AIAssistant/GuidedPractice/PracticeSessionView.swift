import CraftUIKit
import SwiftUI

/// Main conversational practice interface providing speech and text interaction,
/// anti-priming scaffolding assistance, turn revision, and retrospective summary navigation.
public struct PracticeSessionView: View {
    @Environment(\.craftTheme) internal var theme

    @Bindable public var coordinator: PracticeSessionCoordinator
    public let onClose: () -> Void

    @State private var typedInput: String = ""
    @State private var showCloseDialog: Bool = false
    @State private var editingTurnId: UUID?
    @State private var editingText: String = ""
    @State private var showEditDialog: Bool = false

    public init(
        coordinator: PracticeSessionCoordinator,
        onClose: @escaping () -> Void
    ) {
        self.coordinator = coordinator
        self.onClose = onClose
    }

    internal var presentationState: PracticePresentationState {
        PracticePresentationState.make(
            from: coordinator.state,
            capability: coordinator.speech.capability(),
            summary: coordinator.summary
        )
    }

    internal var template: PracticeTemplate? {
        guard let templateId = coordinator.session?.missionSnapshot.templateId else { return nil }
        return PracticeTemplateCatalog.template(withId: templateId)
    }

    internal var currentHintContent: String {
        if let pending = coordinator.pendingPresentations.last(where: { $0.channel == .visual }) {
            return pending.content
        }
        if let exposure = coordinator.exposures.last(where: { $0.channel == .visual }) {
            return exposure.contentSnapshot
        }
        return ""
    }

    public var body: some View {
        Group {
            if let summary = coordinator.summary, coordinator.state == .completed || coordinator.state == .partial {
                PracticeSummaryView(
                    summary: summary,
                    evidence: coordinator.sessionEvidence,
                    onContinue: onClose,
                    onDelete: { id in
                        Task {
                            try? await coordinator.repository.deleteSession(id: id)
                            onClose()
                        }
                    }
                )
            } else {
                sessionLayout
            }
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .craftDialog(
            isPresented: $showCloseDialog,
            titleKey: AppStrings.GuidedPractice.sessionCloseTitle,
            messageKey: AppStrings.GuidedPractice.sessionCloseMessage,
            iconName: "xmark.circle.fill",
            iconColor: theme.colors.warning,
            primaryButtonTitleKey: AppStrings.GuidedPractice.sessionCloseConfirm,
            primaryButtonVariant: .primary,
            primaryAction: {
                Task {
                    await coordinator.finish(.partial)
                }
            },
            cancelButtonTitleKey: AppStrings.GuidedPractice.sessionCloseCancel,
            cancelButtonVariant: .outline,
            cancelAction: {}
        )
        .craftDialog(isPresented: $showEditDialog) {
            editDialogView
        }
        .task(id: coordinator.pendingPresentations.last?.id) {
            let pendingVisual = coordinator.pendingPresentations.filter { intent in
                intent.channel == .visual && intent.status == .pending
            }
            for pending in pendingVisual {
                await coordinator.confirmPresented(intentId: pending.id, at: coordinator.clock.now())
            }
        }
    }

    // MARK: - Main Session Layout

    private var sessionLayout: some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.sm)

            Divider()
                .background(theme.colors.borderDefault)

            conversationHistory
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            scaffoldingDrawer
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xs)

            Divider()
                .background(theme.colors.borderDefault)

            bottomInputDock
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.md)
        }
    }
}

// MARK: - Header Bar & Dialog Subviews

private extension PracticeSessionView {
    var headerBar: some View {
        HStack(spacing: theme.spacing.sm) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                if let template {
                    CraftText(
                        LocalizedStringKey(template.titleKey),
                        style: .headline,
                        color: theme.colors.textPrimary
                    )
                } else if let mission = coordinator.session?.missionSnapshot {
                    CraftText(
                        mission.templateId,
                        style: .headline,
                        color: theme.colors.textPrimary
                    )
                }

                if let mission = coordinator.session?.missionSnapshot {
                    CraftBadge(
                        Self.contextFamilyTitle(for: mission.contextFamily),
                        tone: .primary,
                        size: .sm
                    )
                }
            }

            Spacer()

            HStack(spacing: theme.spacing.xxs) {
                CraftIconButton(
                    iconName: "mic.fill",
                    size: .sm,
                    variant: coordinator.currentInputMode == .voice ? .filled : .subtle,
                    accessibilityLabelKey: AppStrings.GuidedPractice.modeVoice,
                    action: {
                        Task { await coordinator.switchInput(to: .voice) }
                    }
                )

                CraftIconButton(
                    iconName: "keyboard",
                    size: .sm,
                    variant: coordinator.currentInputMode == .typed ? .filled : .subtle,
                    accessibilityLabelKey: AppStrings.GuidedPractice.modeTyped,
                    action: {
                        Task { await coordinator.switchInput(to: .typed) }
                    }
                )
            }

            if coordinator.state == .paused {
                CraftIconButton(
                    iconName: "play.fill",
                    size: .sm,
                    variant: .subtle,
                    accessibilityLabelKey: AppStrings.GuidedPractice.sessionResume,
                    action: {
                        coordinator.resume()
                    }
                )
            } else {
                CraftIconButton(
                    iconName: "pause.fill",
                    size: .sm,
                    variant: .subtle,
                    accessibilityLabelKey: AppStrings.GuidedPractice.sessionPause,
                    action: {
                        Task { await coordinator.pause() }
                    }
                )
            }

            CraftIconButton(
                iconName: "xmark",
                size: .sm,
                variant: .ghost,
                accessibilityLabelKey: AppStrings.Common.close,
                action: {
                    showCloseDialog = true
                }
            )
        }
    }

    var editDialogView: some View {
        CraftDialog(
            titleKey: AppStrings.GuidedPractice.sessionEditTranscriptTitle,
            iconName: "pencil.circle.fill",
            iconColor: theme.colors.brandPrimary,
            primaryButtonTitleKey: AppStrings.GuidedPractice.sessionEditTranscriptSave,
            primaryButtonVariant: .primary,
            primaryAction: {
                showEditDialog = false
                if let turnId = editingTurnId {
                    let text = editingText
                    editingTurnId = nil
                    editingText = ""
                    Task {
                        await coordinator.replaceTranscript(turnId: turnId, text: text)
                    }
                }
            },
            cancelButtonTitleKey: AppStrings.GuidedPractice.sessionEditTranscriptCancel,
            cancelButtonVariant: .outline,
            cancelAction: {
                showEditDialog = false
                editingTurnId = nil
                editingText = ""
            }
        ) {
            CraftTextField(
                AppStrings.GuidedPractice.sessionInputPlaceholder,
                text: $editingText
            )
            .padding(.vertical, theme.spacing.xs)
        }
    }
}

// MARK: - Conversation History Subviews

private extension PracticeSessionView {
    var conversationHistory: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: theme.spacing.md) {
                    ForEach(coordinator.turns, id: \.id) { turn in
                        turnBubble(turn)
                            .id(turn.id)
                    }

                    if coordinator.state == .capturing && !coordinator.activeTurnText.isEmpty {
                        interimTurnBubble
                            .id("interimTurn")
                    }

                    if let feedback = coordinator.coachFeedback, !feedback.isEmpty {
                        coachFeedbackCard(feedback)
                            .id("coachFeedback")
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.md)
            }
            .onChange(of: coordinator.turns.count) {
                if let lastTurn = coordinator.turns.last {
                    withAnimation(theme.animations.springGentle) {
                        proxy.scrollTo(lastTurn.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: coordinator.activeTurnText) {
                if coordinator.state == .capturing {
                    proxy.scrollTo("interimTurn", anchor: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    func turnBubble(_ turn: PracticeTurn) -> some View {
        if turn.speaker == .character {
            characterBubble(turn)
        } else {
            learnerBubble(turn)
        }
    }

    func characterBubble(_ turn: PracticeTurn) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.xs) {
            CraftIcon("person.bubble.fill", size: .md, color: theme.colors.brandPrimary)
                .padding(.top, theme.spacing.xs)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                CraftCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        CraftText(
                            verbatim: turn.acceptedText,
                            style: .bodyMedium,
                            color: theme.colors.textPrimary
                        )

                        HStack {
                            Spacer()
                            CraftIconButton(
                                iconName: "speaker.wave.2.fill",
                                size: .sm,
                                variant: .ghost,
                                accessibilityLabelKey: AppStrings.GuidedPractice.sessionReplayAudio,
                                action: {
                                    Task {
                                        await coordinator.replaySpeech(text: turn.acceptedText)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: 280, alignment: .leading)

            Spacer()
        }
    }

    func learnerBubble(_ turn: PracticeTurn) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.xs) {
            Spacer()

            VStack(alignment: .trailing, spacing: theme.spacing.xxs) {
                CraftCard(style: .flat, customTint: theme.colors.brandPrimary.opacity(0.12)) {
                    VStack(alignment: .trailing, spacing: theme.spacing.xs) {
                        CraftText(
                            verbatim: turn.acceptedText,
                            style: .bodyMedium,
                            color: theme.colors.textPrimary
                        )

                        HStack(spacing: theme.spacing.xs) {
                            CraftBadge(
                                PracticeSummaryView.inputModeBadgeTitle(for: turn.inputMode),
                                tone: .primary,
                                size: .sm
                            )

                            Spacer()

                            CraftIconButton(
                                iconName: "pencil",
                                size: .sm,
                                variant: .ghost,
                                accessibilityLabelKey: AppStrings.GuidedPractice.sessionEditTranscript,
                                action: {
                                    editingTurnId = turn.id
                                    editingText = turn.acceptedText
                                    showEditDialog = true
                                }
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: 280, alignment: .trailing)
        }
    }

    var interimTurnBubble: some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: theme.spacing.xxs) {
                CraftBadge(
                    AppStrings.GuidedPractice.sessionListening,
                    tone: .primary,
                    size: .sm
                )

                CraftCard(style: .outlined, customBorderColor: theme.colors.brandPrimary) {
                    CraftText(
                        verbatim: coordinator.activeTurnText,
                        style: .bodyMedium,
                        color: theme.colors.textPrimary
                    )
                }
            }
            .frame(maxWidth: 280, alignment: .trailing)
        }
    }

    func coachFeedbackCard(_ feedback: String) -> some View {
        CraftCard(style: .outlined, customBorderColor: theme.colors.brandPrimary) {
            HStack(alignment: .top, spacing: theme.spacing.sm) {
                CraftIcon(
                    "lightbulb.fill",
                    size: .sm,
                    color: theme.colors.brandPrimary
                )

                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    CraftText(
                        AppStrings.GuidedPractice.sessionCoachNote,
                        style: .label,
                        color: theme.colors.brandPrimary
                    )

                    CraftText(
                        verbatim: feedback,
                        style: .caption,
                        color: theme.colors.textSecondary
                    )
                }

                Spacer()
            }
        }
    }
}

// MARK: - Scaffolding Drawer & Input Docks

private extension PracticeSessionView {
    var scaffoldingDrawer: some View {
        VStack(spacing: theme.spacing.xs) {
            if coordinator.currentSupport != .none {
                CraftCard(style: .outlined) {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        HStack {
                            CraftBadge(
                                Self.supportLevelTitle(for: coordinator.currentSupport),
                                tone: .warning,
                                size: .sm
                            )

                            Spacer()

                            CraftButton(
                                AppStrings.GuidedPractice.retryLessSupport,
                                variant: .outline,
                                size: .sm,
                                action: {
                                    Task {
                                        await coordinator.retryWithLessSupport()
                                    }
                                }
                            )
                        }

                        if !currentHintContent.isEmpty {
                            CraftText(
                                verbatim: currentHintContent,
                                style: .bodyMedium,
                                color: theme.colors.textPrimary
                            )
                        }
                    }
                }
            }

            HStack(spacing: theme.spacing.sm) {
                CraftButton(
                    AppStrings.GuidedPractice.helpButton,
                    iconName: "questionmark.circle",
                    variant: .secondary,
                    size: .sm,
                    action: {
                        Task {
                            await coordinator.requestHelp(fullModel: false)
                        }
                    }
                )
                .disabled(!presentationState.canRequestHelp)

                Spacer()

                CraftButton(
                    AppStrings.GuidedPractice.fullModelButton,
                    variant: .ghost,
                    size: .sm,
                    action: {
                        Task {
                            await coordinator.requestHelp(fullModel: true)
                        }
                    }
                )
                .disabled(!presentationState.canRequestHelp)
            }
        }
    }

    @ViewBuilder
    var bottomInputDock: some View {
        if coordinator.currentInputMode == .voice {
            voiceInputDock
        } else {
            typedInputDock
        }
    }

    var voiceInputDock: some View {
        VStack(spacing: theme.spacing.xs) {
            CraftTactileMicHubView(
                speechState: micSpeechState,
                customSubtitle: micCustomSubtitle,
                onTapMic: {
                    if coordinator.state == .capturing {
                        Task {
                            await coordinator.finishCapture()
                        }
                    } else if presentationState.canCapture {
                        Task {
                            await coordinator.startCapture()
                        }
                    }
                }
            )
            .disabled(!presentationState.canCapture && coordinator.state != .capturing)
        }
    }

    var micSpeechState: CraftSpeechState {
        if coordinator.state == .capturing {
            return .listening(audioLevels: [0.3, 0.7, 0.5])
        }
        if coordinator.state == .processing || coordinator.state == .saving {
            return .processing
        }
        if coordinator.state == .preparing {
            return .preparing
        }
        if coordinator.state == .paused {
            return .idle
        }
        return .idle
    }

    var micCustomSubtitle: String? {
        if coordinator.state == .capturing {
            return AppStrings.GuidedPractice.sessionTapToFinishText
        }
        if coordinator.state == .processing || coordinator.state == .saving {
            return AppStrings.GuidedPractice.sessionProcessingText
        }
        if coordinator.state == .paused {
            return AppStrings.GuidedPractice.sessionPausedBadgeText
        }
        if presentationState.canCapture {
            return AppStrings.GuidedPractice.sessionTapToSpeakText
        }
        return nil
    }

    var typedInputDock: some View {
        HStack(spacing: theme.spacing.xs) {
            CraftTextField(
                AppStrings.GuidedPractice.sessionInputPlaceholder,
                text: $typedInput
            )

            CraftButton(
                AppStrings.GuidedPractice.sessionSend,
                variant: .primary,
                size: .md,
                action: {
                    let text = typedInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    typedInput = ""
                    Task {
                        await coordinator.submit(text: text, mode: .typed)
                    }
                }
            )
            .disabled(typedInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !presentationState.canSubmit)
        }
    }
}

// MARK: - Presentation Helpers

public extension PracticeSessionView {
    nonisolated static func contextFamilyTitle(for family: PracticeContextFamily) -> LocalizedStringKey {
        switch family {
        case .dining: return AppStrings.GuidedPractice.contextDining
        case .shopping: return AppStrings.GuidedPractice.contextShopping
        case .planning: return AppStrings.GuidedPractice.contextPlanning
        case .social: return AppStrings.GuidedPractice.contextSocial
        case .travel: return AppStrings.GuidedPractice.contextTravel
        case .work: return AppStrings.GuidedPractice.contextWork
        }
    }

    nonisolated static func supportLevelTitle(for level: PracticeSupportLevel) -> LocalizedStringKey {
        switch level {
        case .none: return AppStrings.GuidedPractice.supportNone
        case .intent: return AppStrings.GuidedPractice.supportIntent
        case .lexical: return AppStrings.GuidedPractice.supportLexical
        case .frame: return AppStrings.GuidedPractice.supportFrame
        case .model: return AppStrings.GuidedPractice.supportModel
        }
    }
}
