import CraftUIKit
import SwiftUI

/// Progress information for a learning path.
public struct PathProgressInfo: Sendable, Equatable {
    public let completedUnits: Int
    public let totalUnits: Int
    public let percent: Int

    public init(completedUnits: Int, totalUnits: Int) {
        self.completedUnits = completedUnits
        self.totalUnits = totalUnits
        self.percent = totalUnits > 0 ? Int((Double(completedUnits) / Double(totalUnits)) * 100) : 0
    }
}

/// Modal bottom sheet allowing learners to review and switch between curated learning paths.
///
/// Features:
/// - Presentation detents: `[.medium, .large]`.
/// - Displays the 4 curated learning paths with CEFR badges, theme icons, localized titles, and descriptions.
/// - Shows overall completion progress via `CraftProgressBar` and bilingual progress string.
/// - Active path indicator with checkmark badge.
/// - Preserves progress across path switches and triggers haptic feedback.
@MainActor
public struct LearningPathSwitchSheet: View {
    @Environment(\.appContainer) private var appContainer
    @Environment(\.craftTheme) private var theme
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss

    public let activePathId: String?
    public let initialPaths: [LearningPathDTO]?
    public var onSelectPath: (@MainActor @Sendable (LearningPathDTO) -> Void)?

    @State private var paths: [LearningPathDTO] = []
    @State private var pathProgress: [String: PathProgressInfo] = [:]
    @State private var isLoading: Bool = false

    public init(
        activePathId: String? = nil,
        initialPaths: [LearningPathDTO]? = nil,
        onSelectPath: (@MainActor @Sendable (LearningPathDTO) -> Void)? = nil
    ) {
        self.activePathId = activePathId
        self.initialPaths = initialPaths
        self.onSelectPath = onSelectPath
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView

            if isLoading && paths.isEmpty {
                loadingView
            } else {
                pathListView
            }
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .task {
            await loadPathsAndProgress()
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                CraftText(
                    AppStrings.LearningPath.switcherTitle,
                    style: .titleMedium,
                    color: theme.colors.textPrimary
                )
                .fontWeight(.bold)

                CraftText(
                    AppStrings.LearningPath.switcherSubtitle,
                    style: .bodyMedium,
                    color: theme.colors.textSecondary
                )
            }

            Spacer()

            CraftIconButton(
                symbol: .close,
                size: .md,
                shape: .circle,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.Common.close,
                action: {
                    CraftHaptics.shared.light()
                    dismiss()
                }
            )
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.top, theme.spacing.lg)
        .padding(.bottom, theme.spacing.md)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: theme.spacing.base) {
            Spacer()
            ProgressView()
                .tint(theme.colors.brandPrimary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Path List

    private var pathListView: some View {
        ScrollView {
            VStack(spacing: theme.spacing.md) {
                ForEach(paths) { path in
                    pathCard(for: path)
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.xs)
            .padding(.bottom, theme.spacing.xl)
        }
    }

    // MARK: - Path Card

    private func pathCard(for path: LearningPathDTO) -> some View {
        let active = isPathActive(path)
        let progress = pathProgress[path.id] ?? defaultProgress(for: path)

        return CraftCard(
            style: .tactile3D,
            isPressable: !active,
            customBorderColor: active ? theme.colors.brandPrimary : theme.colors.borderDefault,
            action: {
                guard !active else { return }
                CraftHaptics.shared.selection()
                onSelectPath?(path)
                dismiss()
            }
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Top row: Icon + CEFR badge + Active indicator
                HStack(alignment: .center, spacing: theme.spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(active ? theme.colors.brandPrimary.opacity(0.15) : theme.colors.surfaceSubtle)
                            .frame(width: 40, height: 40)

                        CraftIcon(
                            iconName(for: path),
                            size: .md,
                            color: active ? theme.colors.brandPrimary : theme.colors.textPrimary
                        )
                    }

                    CraftBadge(
                        localizedLevels(for: path),
                        iconName: nil,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm
                    )

                    Spacer()

                    if active {
                        CraftBadge(
                            AppStrings.LearningPath.activeBadge,
                            symbol: .check,
                            variant: .subtle,
                            tone: .success,
                            size: .sm
                        )
                    }
                }

                // Title and Description
                VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                    CraftText(
                        localizedTitle(for: path),
                        style: .headline,
                        color: theme.colors.textPrimary
                    )
                    .fontWeight(.bold)

                    if let description = localizedDescription(for: path), !description.isEmpty {
                        CraftText(
                            description,
                            style: .caption,
                            color: theme.colors.textSecondary
                        )
                        .lineLimit(2)
                    }
                }

                // Overall progress bar
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    CraftText(
                        AppStrings.LearningPath.progress(
                            completed: progress.completedUnits,
                            total: progress.totalUnits,
                            percent: progress.percent
                        ),
                        style: .caption,
                        color: theme.colors.textSecondary
                    )

                    CraftProgressBar(
                        progress: progress.totalUnits > 0
                            ? Double(progress.completedUnits) / Double(progress.totalUnits)
                            : 0.0,
                        height: 6,
                        tintColor: active ? theme.colors.brandPrimary : theme.colors.brandPrimary.opacity(0.7),
                        trackColor: theme.colors.surfaceSubtle
                    )
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(active ? [.isSelected] : [.isButton])
        .accessibilityLabel("\(localizedTitle(for: path)), \(localizedLevels(for: path))")
        .accessibilityHint(active ? AppStrings.LearningPath.activeBadgeText : AppStrings.LearningPath.switchActionText)
    }

    // MARK: - Helpers

    private func isPathActive(_ path: LearningPathDTO) -> Bool {
        if let activePathId, !activePathId.isEmpty {
            return path.id == activePathId || path.code == activePathId
        }
        return path.sortOrder == 0
    }

    private func localizedTitle(for path: LearningPathDTO) -> String {
        let isVietnamese = locale.identifier.hasPrefix("vi")
        if isVietnamese {
            return path.titleVi.isEmpty ? path.titleEn : path.titleVi
        } else {
            return path.titleEn.isEmpty ? path.titleVi : path.titleEn
        }
    }

    private func localizedDescription(for path: LearningPathDTO) -> String? {
        let isVietnamese = locale.identifier.hasPrefix("vi")
        if isVietnamese {
            return path.descriptionVi ?? path.descriptionEn
        } else {
            return path.descriptionEn ?? path.descriptionVi
        }
    }

    private func localizedLevels(for path: LearningPathDTO) -> String {
        let min = path.targetLevelMin.trimmingCharacters(in: .whitespacesAndNewlines)
        let max = path.targetLevelMax.trimmingCharacters(in: .whitespacesAndNewlines)
        if !min.isEmpty && !max.isEmpty && min != max {
            return "\(min) – \(max)"
        } else if !min.isEmpty {
            return min
        } else if !max.isEmpty {
            return max
        }
        return "A1 – C2"
    }

    private func iconName(for path: LearningPathDTO) -> String {
        switch path.iconKey {
        case "compass":
            return "safari"
        case "airplane", "airplane.departure":
            return "airplane.departure"
        case "briefcase", "briefcase.fill":
            return "briefcase.fill"
        case "graduationcap", "graduationcap.fill":
            return "graduationcap.fill"
        default:
            return path.iconKey.isEmpty ? "map.fill" : path.iconKey
        }
    }

    private func defaultProgress(for path: LearningPathDTO) -> PathProgressInfo {
        let total: Int = switch path.code {
        case "essential-english-mastery": 48
        case "daily-life-travel": 26
        case "business-career": 10
        case "academic-research": 16
        default: 10
        }
        return PathProgressInfo(completedUnits: 0, totalUnits: total)
    }

    private func loadPathsAndProgress() async {
        isLoading = true
        defer { isLoading = false }

        let loadedPaths: [LearningPathDTO]
        if let initialPaths, !initialPaths.isEmpty {
            loadedPaths = initialPaths
        } else {
            let fetched = (try? await appContainer.vocabularyDataSource.fetchLearningPaths()) ?? []
            loadedPaths = fetched.count >= Self.fallbackPaths.count ? fetched : Self.fallbackPaths
        }
        self.paths = loadedPaths.sorted { $0.sortOrder < $1.sortOrder }

        let allProgress = (try? await appContainer.stageProgressRepository.fetchAllStageProgress()) ?? []
        let completedCheckpointDeckIds = Set(
            allProgress
                .filter { $0.isCompleted && $0.stageId.hasPrefix("checkpoint_") }
                .map { String($0.stageId.dropFirst("checkpoint_".count)) }
        )

        var progressMap: [String: PathProgressInfo] = [:]
        for path in self.paths {
            let decks = (try? await appContainer.vocabularyDataSource.fetchTopicDecks(for: path.id)) ?? []
            let total = decks.isEmpty ? defaultProgress(for: path).totalUnits : decks.count
            let completed = decks.filter { completedCheckpointDeckIds.contains($0.id) }.count
            progressMap[path.id] = PathProgressInfo(completedUnits: completed, totalUnits: total)
        }
        self.pathProgress = progressMap
    }

    public static let fallbackPaths: [LearningPathDTO] = [
        LearningPathDTO(
            id: "7147ba7e-0728-471d-97af-f3e2262a6d23",
            code: "essential-english-mastery",
            titleEn: "Core Curriculum: Comprehensive English",
            titleVi: "Lộ Trình Cốt Lõi: Tiếng Anh Toàn Diện",
            descriptionEn: "Complete mastery across all essential grammar and vocabulary from A1 to C2.",
            descriptionVi: "Toàn diện ngữ pháp và từ vựng cốt lõi từ căn bản đến nâng cao A1 đến C2.",
            goalCategory: "general",
            targetLevelMin: "A1",
            targetLevelMax: "C2",
            iconKey: "compass",
            themeKey: "ocean_blue",
            sortOrder: 0
        ),
        LearningPathDTO(
            id: "c11e8a24-9b2f-4e67-881a-637dc44d3201",
            code: "daily-life-travel",
            titleEn: "Everyday Life & Travel Fluency",
            titleVi: "Giao Tiếp Đời Sống & Du Lịch Thực Tế",
            descriptionEn: "Essential conversational fluency for travel, dining, shopping, and everyday situations.",
            descriptionVi: "Giao tiếp trôi chảy tự tin khi đi du lịch, ăn uống, mua sắm và đời sống thường ngày.",
            goalCategory: "travel",
            targetLevelMin: "A1",
            targetLevelMax: "B1",
            iconKey: "airplane.departure",
            themeKey: "forest_green",
            sortOrder: 1
        ),
        LearningPathDTO(
            id: "d22f9b35-0c30-4f78-992b-748ed55e4312",
            code: "business-career",
            titleEn: "Business & Workplace Excellence",
            titleVi: "Tiếng Anh Công Sở & Phát Triển Sự Nghiệp",
            descriptionEn: "Professional vocabulary for meetings, negotiations, presentations, and leadership.",
            descriptionVi: "Từ vựng chuyên nghiệp phục vụ hội họp, đàm phán, thuyết trình và phát triển sự nghiệp.",
            goalCategory: "business",
            targetLevelMin: "B1",
            targetLevelMax: "B2",
            iconKey: "briefcase.fill",
            themeKey: "ocean_blue",
            sortOrder: 2
        ),
        LearningPathDTO(
            id: "e33a0c46-1d41-4089-aa3c-859fe66f5423",
            code: "academic-research",
            titleEn: "Academic Mastery & Critical Inquiries",
            titleVi: "Tiếng Anh Học Thuật & Nghiên Cứu Chuyên Sâu",
            descriptionEn: "Advanced lexicon and rhetoric for university research, thesis writing, and debates.",
            descriptionVi: "Vốn từ học thuật chuyên sâu phục vụ nghiên cứu, viết luận và tư duy phản biện.",
            goalCategory: "academic",
            targetLevelMin: "B2",
            targetLevelMax: "C2",
            iconKey: "graduationcap.fill",
            themeKey: "royal_purple",
            sortOrder: 3
        )
    ]
}

#if canImport(PreviewsMacros)
#Preview("LearningPathSwitchSheet") {
    LearningPathSwitchSheet(
        activePathId: "7147ba7e-0728-471d-97af-f3e2262a6d23",
        initialPaths: LearningPathSwitchSheet.fallbackPaths,
        onSelectPath: { _ in }
    )
}
#endif
