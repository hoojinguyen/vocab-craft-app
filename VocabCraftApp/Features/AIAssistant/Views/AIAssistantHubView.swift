#if os(iOS)
import AVFoundation
import Speech
#endif
import CraftUIKit
import SwiftUI

public struct AIAssistantHubView: View {
    @State private var viewModel: AIAssistantHubViewModel
    @State private var activeRoomViewModel: RoleplayRoomViewModel?
    @State private var activeVoiceCallViewModel: RoleplayVoiceCallViewModel?
    @State private var showConfigSheet: Bool = false
    @State private var showPermissionDeniedAlert: Bool = false
    @State private var sampleSummary: RoleplaySessionSummary?
    private let customStore: UserSettingsStore?
    @Environment(\.appContainer) private var appContainer
    @Environment(\.craftTheme) private var theme
    @Environment(\.openURL) private var openURL

    public init(viewModel: AIAssistantHubViewModel, store: UserSettingsStore? = nil) {
        self._viewModel = State(initialValue: viewModel)
        self.customStore = store
    }

    private var settingsStore: UserSettingsStore {
        customStore ?? appContainer.userSettingsStore
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    CraftPageHeader(
                        AppStrings.AIAssistant.hubTitle,
                        alignment: .leading,
                        enableScrollFade: false
                    ) {
                        HStack(spacing: theme.spacing.xs) {
                            activePackPill

                            CraftIconButton(
                                symbol: .settings,
                                size: .md,
                                variant: .subtle,
                                accessibilityLabelKey: AppStrings.AIAssistant.configureApiKey
                            ) {
                                showConfigSheet = true
                            }
                        }
                    }

                    VStack(spacing: theme.spacing.lg) {
                        if let daily = viewModel.dailyScenario {
                            CompanionHeroCard(
                                scenario: daily,
                                wordsLearnedCount: settingsStore.todayWordsLearned,
                                onStartCall: {
                                    startVoiceCall(for: daily)
                                },
                                onStartChat: {
                                    activeRoomViewModel = appContainer.makeRoleplayRoomViewModel(for: daily)
                                }
                            )
                        }

                        topicFilterBar

                        scenarioListSection

                        Spacer(minLength: theme.spacing.xxl + 88)
                    }
                    .padding(.horizontal, theme.spacing.base)
                }
                .padding(.top, theme.spacing.xs)
            }
        }
        .task {
            if viewModel.scenarios.isEmpty {
                await viewModel.loadScenarios()
            }
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("-test-ai-config") {
                showConfigSheet = true
            } else if args.contains("-test-ai-room") {
                if let scenario = viewModel.dailyScenario ?? viewModel.scenarios.first {
                    activeRoomViewModel = appContainer.makeRoleplayRoomViewModel(for: scenario)
                }
            } else if args.contains("-test-ai-voice") {
                if let scenario = viewModel.dailyScenario ?? viewModel.scenarios.first {
                    startVoiceCall(for: scenario)
                }
            } else if args.contains("-test-ai-summary") {
                sampleSummary = RoleplaySessionSummary(
                    scenarioId: "cafe_ordering",
                    totalTurns: 6,
                    targetWordsAttempted: ["beverage", "pastry", "complimentary"],
                    targetWordsMastered: ["beverage", "pastry"],
                    fluencyScore: 85,
                    xpEarned: 30,
                    refinements: [
                        SentenceRefinementPair(
                            originalUserSentence: "I want drink coffee hot please.",
                            refinedNativeSentence: "I'd like a hot coffee, please."
                        )
                    ]
                )
            }
            #endif
        }
        .sheet(item: $sampleSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                sampleSummary = nil
            }
        }
        .sheet(isPresented: $showConfigSheet) {
            AIConfigSheet(store: settingsStore)
        }
        #if os(iOS)
        .fullScreenCover(item: $activeRoomViewModel) { roomViewModel in
            RoleplayRoomView(
                viewModel: roomViewModel,
                onDismiss: { activeRoomViewModel = nil }
            )
        }
        .fullScreenCover(item: $activeVoiceCallViewModel) { voiceCallViewModel in
            RoleplayVoiceCallView(
                viewModel: voiceCallViewModel,
                onDismiss: { activeVoiceCallViewModel = nil }
            )
        }
        #else
        .sheet(item: $activeRoomViewModel) { roomViewModel in
            RoleplayRoomView(
                viewModel: roomViewModel,
                onDismiss: { activeRoomViewModel = nil }
            )
        }
        .sheet(item: $activeVoiceCallViewModel) { voiceCallViewModel in
            RoleplayVoiceCallView(
                viewModel: voiceCallViewModel,
                onDismiss: { activeVoiceCallViewModel = nil }
            )
        }
        #endif
        .alert(
            AppStrings.AIAssistant.permissionTitle,
            isPresented: $showPermissionDeniedAlert
        ) {
            #if os(iOS)
            Button(AppStrings.AIAssistant.openSettings) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            #endif
            Button(AppStrings.Common.cancel, role: .cancel) {}
        } message: {
            Text(AppStrings.AIAssistant.permissionMessage)
        }
    }

    private var topicFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                topicPill(
                    title: AppStrings.AIAssistant.topicAll,
                    isSelected: viewModel.selectedTopic == nil
                ) {
                    viewModel.selectedTopic = nil
                }

                ForEach(ScenarioTopic.allCases, id: \.self) { topic in
                    topicPill(
                        title: localizedTopicTitle(for: topic),
                        isSelected: viewModel.selectedTopic == topic
                    ) {
                        viewModel.selectedTopic = topic
                    }
                }
            }
            .padding(.vertical, theme.spacing.xxs)
        }
    }

    private func localizedTopicTitle(for topic: ScenarioTopic) -> LocalizedStringKey {
        switch topic {
        case .dining: return AppStrings.AIAssistant.topicDining
        case .travel: return AppStrings.AIAssistant.topicTravel
        case .workplace: return AppStrings.AIAssistant.topicWorkplace
        case .dailyLife: return AppStrings.AIAssistant.topicDailyLife
        case .interview: return AppStrings.AIAssistant.topicInterview
        }
    }

    private func topicPill(
        title: LocalizedStringKey,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            CraftBadge(
                title,
                variant: isSelected ? .solid : .subtle,
                tone: isSelected ? .primary : .neutral,
                size: .md
            )
        }
        .buttonStyle(.plain)
    }

    private var scenarioListSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            Text(AppStrings.AIAssistant.scenarioSectionTitle)
                .font(theme.typography.titleMedium)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.textPrimary)

            ForEach(viewModel.filteredScenarios.filter { $0.id != viewModel.dailyScenario?.id }) { scenario in
                ScenarioListCard(
                    scenario: scenario,
                    onStartVoice: {
                        startVoiceCall(for: scenario)
                    },
                    onStartText: {
                        activeRoomViewModel = appContainer.makeRoleplayRoomViewModel(for: scenario)
                    }
                )
            }
        }
    }

    private func startVoiceCall(for scenario: RoleplayScenario) {
        #if os(iOS)
        #if targetEnvironment(simulator)
        activeVoiceCallViewModel = appContainer.makeRoleplayVoiceCallViewModel(for: scenario)
        #else
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        let micPermission = AVAudioApplication.shared.recordPermission

        if speechStatus == .denied || speechStatus == .restricted || micPermission == .denied {
            showPermissionDeniedAlert = true
            return
        }

        if speechStatus == .notDetermined || micPermission == .undetermined {
            Task {
                let speechGranted = await withCheckedContinuation { continuation in
                    SFSpeechRecognizer.requestAuthorization { status in
                        continuation.resume(returning: status == .authorized)
                    }
                }
                guard speechGranted else {
                    showPermissionDeniedAlert = true
                    return
                }
                let micGranted = await AVAudioApplication.requestRecordPermission()
                guard micGranted else {
                    showPermissionDeniedAlert = true
                    return
                }
                activeVoiceCallViewModel = appContainer.makeRoleplayVoiceCallViewModel(for: scenario)
            }
            return
        }

        activeVoiceCallViewModel = appContainer.makeRoleplayVoiceCallViewModel(for: scenario)
        #endif
        #else
        activeVoiceCallViewModel = appContainer.makeRoleplayVoiceCallViewModel(for: scenario)
        #endif
    }

    private var activePack: (any AIPackProtocol)? {
        let registry = appContainer.aiPackRegistry
        return registry.pack(for: registry.activePackId)
    }

    private var activePackPill: some View {
        let pack = activePack
        let displayName = pack?.displayName ?? appContainer.aiPackRegistry.activePackId.rawValue
        let (statusKey, tone): (LocalizedStringKey, CraftBadgeTone) = {
            guard let status = pack?.status else {
                return (AppStrings.AIPack.statusReady, .neutral)
            }
            switch status {
            case .ready:
                return (AppStrings.AIPack.statusReady, .success)
            case .needsApiKey:
                return (AppStrings.AIPack.statusNeedsKey, .warning)
            case .needsDownload, .partiallyReady:
                return (AppStrings.AIPack.statusNeedsDownload, .primary)
            case .unavailable:
                return (AppStrings.AIPack.statusNeedsKey, .neutral)
            }
        }()

        return Button {
            showConfigSheet = true
        } label: {
            HStack(spacing: theme.spacing.xxs) {
                Text(verbatim: displayName)
                    .font(theme.typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.colors.textPrimary)

                CraftBadge(
                    statusKey,
                    variant: .subtle,
                    tone: tone,
                    size: .sm
                )
            }
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, theme.spacing.xxs)
            .background(theme.colors.surfaceCard)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isButton)
    }
}
