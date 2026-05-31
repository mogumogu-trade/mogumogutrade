import SwiftUI

struct TradeView: View {
    @Bindable var viewModel: TradeViewModel
    @State private var confettiAnimate = false

    // give（わたす）はミント、want（ほしい）はコーラルで色分け（みんなタブと共通）
    private let giveAccent = AppColors.wait
    private let wantAccent = AppColors.bet

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    studentCard
                    offerBuilder
                    resultBanner
                }
                .padding(24)
            }
            .background(AppColors.bg.ignoresSafeArea())

            if viewModel.match != nil {
                celebrationOverlay
            }
        }
        .navigationTitle("今日のトレード")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var studentCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(AppColors.boardBorder)

            VStack(alignment: .leading, spacing: 4) {
                Text("出品する人")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(viewModel.currentStudent.displayName)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.darkText)
            }

            Spacer()
        }
        .tradeCard()
    }

    private var offerBuilder: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("出品を作る")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.darkText)

            ConditionPickerCard(
                title: "わたすもの",
                accent: giveAccent,
                selection: $viewModel.selectedOffering
            )

            ConditionPickerCard(
                title: "ほしいもの",
                accent: wantAccent,
                selection: $viewModel.selectedRequesting
            )

            Button {
                Task { await viewModel.submitOffer() }
            } label: {
                HStack {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                    }
                    Text(viewModel.isSubmitting ? "出品しているよ…" : "この条件で出品する")
                }
                .font(.system(size: 18, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSubmitNow ? AppColors.darkText : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppColors.darkText.opacity(canSubmitNow ? 0.25 : 0), radius: 8, y: 4)
            }
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)

            if let allergyBlockReason = viewModel.allergyBlockReason {
                Text(allergyBlockReason)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)
            } else if !viewModel.canSubmit {
                Text("同じものどうしは選べないよ")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
        .tradeCard()
    }

    private var canSubmitNow: Bool {
        viewModel.canSubmit && !viewModel.isSubmitting
    }

    // 成立は全画面の celebrationOverlay が担当するので、ここは未成立（queued / cancelled）のみ表示。
    @ViewBuilder
    private var resultBanner: some View {
        if let message = viewModel.message, viewModel.match == nil {
            VStack(spacing: 10) {
                Text(message)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.darkText)
                    .multilineTextAlignment(.center)

                Text(viewModel.resultKind == .cancelled ? "取り消しできたよ" : "出品リストに入ったよ")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.darkText.opacity(0.7))

                Button("とじる") {
                    viewModel.clearResult()
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .buttonStyle(.bordered)
                .tint(AppColors.darkText)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(bannerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var bannerBackground: Color {
        switch viewModel.resultKind {
        case .cancelled:
            Color.gray.opacity(0.22)
        default:
            AppColors.wait.opacity(0.55)
        }
    }

    // MARK: - 成立お祝い演出（QR の完食演出と同じ作り）

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            ForEach(0..<30, id: \.self) { index in
                ConfettiPieceView(animate: confettiAnimate, index: index)
            }

            VStack(spacing: 20) {
                Text("トレード成立！")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.win)
                    .shadow(color: .white.opacity(0.6), radius: 2)
                    .scaleEffect(confettiAnimate ? 1.1 : 0.6)

                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(confettiAnimate ? 360 : 0))

                if let match = viewModel.match {
                    VStack(spacing: 8) {
                        Text("\(match.partnerOffer.seller.displayName) と成立")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(match.myOffer.offering.title) と \(match.partnerOffer.offering.title) を交換")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.yellow)
                            .multilineTextAlignment(.center)
                    }
                }

                Button {
                    viewModel.clearResult()
                } label: {
                    Text("とじる ➔")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(AppColors.darkText)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 40)
                        .background(AppColors.win)
                        .clipShape(Capsule())
                        .shadow(color: AppColors.win.opacity(0.5), radius: 10, y: 5)
                }
            }
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
        .onAppear {
            confettiAnimate = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                confettiAnimate = true
            }
        }
        .onDisappear { confettiAnimate = false }
    }
}

private struct ConditionPickerCard: View {
    let title: String
    let accent: Color
    @Binding var selection: TradeCondition

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)

            Menu {
                ForEach(TradeConditionCategory.allCases) { category in
                    Section(category.title) {
                        ForEach(TradeCondition.options(for: category)) { condition in
                            Button {
                                selection = condition
                            } label: {
                                Label(condition.title, systemImage: category.systemImage)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selection.category.systemImage)
                    Text(selection.category.title)
                    Text(selection.title)
                        .fontWeight(.black)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AppColors.darkText.opacity(0.5))
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.darkText)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accent.opacity(0.30))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accent.opacity(0.6), lineWidth: 1.5)
                )
            }
        }
    }
}

struct TradeOffersView: View {
    let viewModel: TradeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("みんなの出品")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.darkText)

                if viewModel.isLoading {
                    loadingState
                } else if viewModel.openOffers.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 14) {
                        ForEach(viewModel.openOffers) { offer in
                            TradeOfferRow(
                                offer: offer,
                                canCancel: offer.seller == viewModel.currentStudent,
                                onCancel: {
                                    Task { await viewModel.cancelOffer(id: offer.id) }
                                }
                            )
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .background(AppColors.bg.ignoresSafeArea())
        .navigationTitle("みんなの出品")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)

            Text("まだ出品がないよ")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.darkText)

            Text("「出品」タブで さきに つくってみよう")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .tradeCard()
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("出品を読みこみ中")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.darkText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .tradeCard()
    }
}

private struct TradeOfferRow: View {
    let offer: TradeOffer
    let canCancel: Bool
    let onCancel: () -> Void

    init(
        offer: TradeOffer,
        canCancel: Bool = false,
        onCancel: @escaping () -> Void = {}
    ) {
        self.offer = offer
        self.canCancel = canCancel
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(offer.seller.displayName, systemImage: "person.fill")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.darkText)
                Spacer()
                Text(offer.status == .open ? "受付中" : "成立")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AppColors.darkText.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(offer.status == .open ? AppColors.wait.opacity(0.55) : AppColors.win.opacity(0.7))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                ConditionPill(title: "出す", condition: offer.offering, accent: AppColors.wait)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(AppColors.darkText.opacity(0.6))
                ConditionPill(title: "ほしい", condition: offer.requesting, accent: AppColors.bet)
            }

            if canCancel {
                Button {
                    onCancel()
                } label: {
                    Label("出品を取り消す", systemImage: "trash")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.12))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .tradeCard()
    }
}

private struct ConditionPill: View {
    let title: String
    let condition: TradeCondition
    let accent: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppColors.darkText.opacity(0.6))
            Text(condition.title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.darkText)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 8)
        .background(accent.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 共通カードスタイル（白背景＋角丸＋薄枠＋やわらかい影）

private struct TradeCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

private extension View {
    func tradeCard() -> some View {
        modifier(TradeCardStyle())
    }
}

#Preview("出品") {
    NavigationStack {
        TradeView(viewModel: TradeViewModel(
            profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ")
        ))
    }
}

#Preview("成立演出") {
    NavigationStack {
        TradeView(viewModel: .previewMatched())
    }
}

#Preview("出品ずみ") {
    NavigationStack {
        TradeView(viewModel: .previewQueued())
    }
}

#Preview("みんなの出品") {
    NavigationStack {
        TradeOffersView(viewModel: TradeViewModel(
            profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"),
            offers: TradeViewModel.sampleOffers
        ))
    }
}
