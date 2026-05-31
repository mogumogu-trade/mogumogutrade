import SwiftUI

struct TradeView: View {
    @Bindable var viewModel: TradeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                studentCard
                offerBuilder
                resultBanner
            }
            .padding(24)
        }
        .background(AppColors.bg.ignoresSafeArea())
        .navigationTitle("今日のトレード")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var studentCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("出品する人")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(viewModel.currentStudent.displayName)
                    .font(.system(size: 24, weight: .black, design: .rounded))
            }

            Spacer()
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
        )
    }

    private var offerBuilder: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("出品を作る")
                .font(.system(size: 22, weight: .black, design: .rounded))

            ConditionPickerCard(
                title: "わたすもの",
                selection: $viewModel.selectedOffering
            )

            ConditionPickerCard(
                title: "ほしいもの",
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
                .background(viewModel.canSubmit && !viewModel.isSubmitting ? AppColors.primary : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: viewModel.canSubmit && !viewModel.isSubmitting ? AppColors.primary.opacity(0.28) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)

            if !viewModel.canSubmit {
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
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
        )
    }

    @ViewBuilder
    private var resultBanner: some View {
        if let message = viewModel.message {
            VStack(spacing: 12) {
                Text(message)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                if let match = viewModel.match {
                    VStack(spacing: 6) {
                        Text("\(match.partnerOffer.seller.displayName) と成立")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        Text("\(match.myOffer.offering.title) と \(match.partnerOffer.offering.title) を交換")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                } else {
                    Text(message == "出品を取り消したよ" ? "取り消しできたよ" : "出品リストに入ったよ")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Button("とじる") {
                    viewModel.clearResult()
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(viewModel.match == nil ? AppColors.primaryLight.opacity(0.34) : AppColors.accent.opacity(0.24))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }
}

private struct ConditionPickerCard: View {
    let title: String
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
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.primaryLight.opacity(0.25))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.primary.opacity(0.18), lineWidth: 1)
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

            Text("出品タブで 先に作ってみよう")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
        )
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("出品を読みこみ中")
                .font(.system(size: 18, weight: .black, design: .rounded))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
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
                Spacer()
                Text(offer.status == .open ? "受付中" : "成立")
                    .font(.system(size: 11, weight: .black))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(offer.status == .open ? AppColors.accent.opacity(0.2) : Color.gray.opacity(0.2))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                ConditionPill(title: "出す", condition: offer.offering, color: AppColors.primary)
                Image(systemName: "arrow.left.arrow.right")
                    .fontWeight(.black)
                    .foregroundStyle(.secondary)
                ConditionPill(title: "ほしい", condition: offer.requesting, color: AppColors.primaryLight)
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
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
        )
    }
}

private struct ConditionPill: View {
    let title: String
    let condition: TradeCondition
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            Text(condition.title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 64)
        .padding(.horizontal, 8)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    NavigationStack {
        TradeView(viewModel: TradeViewModel(
            profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ")
        ))
    }
}
