import SwiftUI

/// Screen allowing the user to select words for a Mixed Reflex Drill practice session.
/// Features a navigation header, 3-tab segmented category filter (Chưa thuộc / Đã thuộc / Đã lưu),
/// quick "Chọn tất cả" toggle action, lazy scrollable list of selectable words,
/// and a sticky bottom CTA bar anchored with `.safeAreaInset(edge: .bottom)`.
public struct PracticeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var vaultViewModel: PersonalVaultViewModel

    public let onStartPractice: ([VaultWordItem]) -> Void
    public let onClose: (() -> Void)?

    public init(
        vaultViewModel: PersonalVaultViewModel,
        onStartPractice: @escaping ([VaultWordItem]) -> Void,
        onClose: (() -> Void)? = nil
    ) {
        self.vaultViewModel = vaultViewModel
        self.onStartPractice = onStartPractice
        self.onClose = onClose
    }

    private var isAllSelected: Bool {
        !vaultViewModel.vaultWords.isEmpty &&
        vaultViewModel.vaultWords.allSatisfy { vaultViewModel.selectedWordIds.contains($0.id) }
    }

    private var selectedWordsCount: Int {
        vaultViewModel.selectedWords.count
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                navigationHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // 3-Tab Segmented Filter
                segmentedFilterBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)

                // Quick Action Row (Count & Select All Toggle)
                actionToolbar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // Scrollable Word List
                wordListContent
            }
        }
        .safeAreaInset(edge: .bottom) {
            stickyBottomBar
        }
        .task {
            if vaultViewModel.vaultWords.isEmpty && !vaultViewModel.isLoading {
                await vaultViewModel.loadData()
            }
        }
    }

    // MARK: - Navigation Header
    private var navigationHeader: some View {
        HStack(alignment: .center) {
            Button(action: {
                if let onClose {
                    onClose()
                } else {
                    dismiss()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Quay lại")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(Color.vocabInk)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Text("Luyện tập")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.vocabInk)

            Spacer()

            // Selected count pill badge
            if selectedWordsCount > 0 {
                Text("\(selectedWordsCount) đã chọn")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.vocabHeroAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .clipShape(Capsule())
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - 3-Tab Segmented Filter
    private var segmentedFilterBar: some View {
        HStack(spacing: 4) {
            ForEach(VaultTabFilter.allCases, id: \.self) { tab in
                let isSelected = vaultViewModel.vaultTabFilter == tab

                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        vaultViewModel.setVaultFilter(tab)
                    }
                }) {
                    Text(tab.title)
                        .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? Color.vocabInk : Color.vocabMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(isSelected ? Color.vocabInk.opacity(0.08) : Color.clear)
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .sensoryFeedback(.selection, trigger: isSelected)
            }
        }
        .padding(4)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
    }

    // MARK: - Action Toolbar (Count & Select All Toggle)
    private var actionToolbar: some View {
        HStack {
            Text("\(vaultViewModel.vaultWords.count) từ trong danh sách")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)

            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    if isAllSelected {
                        vaultViewModel.deselectAll()
                    } else {
                        vaultViewModel.selectAll()
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isAllSelected ? "xmark.circle" : "checkmark.circle")
                        .font(.system(size: 14, weight: .semibold))
                    Text(isAllSelected ? "Bỏ chọn tất cả" : "Chọn tất cả")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color.vocabHeroAccent)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .sensoryFeedback(.selection, trigger: isAllSelected)
        }
    }

    // MARK: - Word List Content
    private var wordListContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if vaultViewModel.isLoading && vaultViewModel.vaultWords.isEmpty {
                VStack {
                    Spacer(minLength: 40)
                    ProgressView()
                        .padding(.vertical, 40)
                    Spacer(minLength: 40)
                }
            } else if vaultViewModel.vaultWords.isEmpty {
                emptyListView
                    .padding(.top, 30)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vaultViewModel.vaultWords) { word in
                        PracticeSelectionRow(
                            word: word,
                            isSelected: vaultViewModel.selectedWordIds.contains(word.id),
                            onToggle: {
                                vaultViewModel.toggleWordSelection(id: word.id)
                            },
                            onAudioTap: {
                                vaultViewModel.playAudio(for: word)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Empty State View
    private var emptyListView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(Color.vocabMuted.opacity(0.6))
                .padding(.top, 16)

            Text("Chưa có từ vựng")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.vocabInk)

            Text("Không tìm thấy từ vựng nào trong mục này.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.vocabMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.vocabSurfaceCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.vocabHairline, lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Sticky Bottom Bar
    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.vocabHairline)

            VStack(spacing: 8) {
                Button(action: {
                    let selected = vaultViewModel.selectedWords
                    guard !selected.isEmpty else { return }
                    onStartPractice(selected)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 16, weight: .bold))

                        Text(selectedWordsCount > 0 ? "BẮT ĐẦU LUYỆN TẬP (\(selectedWordsCount) TỪ)" : "VUI LÒNG CHỌN TỪ ĐỂ BẮT ĐẦU")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedWordsCount > 0 ? Color.vocabHeroAccent : Color.vocabMuted.opacity(0.18))
                    .foregroundColor(selectedWordsCount > 0 ? .white : Color.vocabMuted)
                    .cornerRadius(16)
                    .shadow(
                        color: selectedWordsCount > 0 ? Color.vocabHeroAccent.opacity(0.25) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .buttonStyle(BentoCardButtonStyle())
                .disabled(selectedWordsCount == 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(Color.vocabCanvas.opacity(0.95))
            .background(.ultraThinMaterial)
        }
    }
}
