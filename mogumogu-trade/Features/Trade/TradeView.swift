import SwiftUI

struct TradeView: View {
    @Bindable var viewModel: TradeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                studentCard
                offerBuilder
                TradeResultCard(
                    message: viewModel.message,
                    match: viewModel.match,
                    onClose: viewModel.clearResult
                )
            }
            .padding(24)
        }
        .background(Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea())
        .navigationTitle("今日のトレード")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var studentCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color(red: 0.47, green: 0.33, blue: 0.28))

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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
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
                .background(viewModel.canSubmit && !viewModel.isSubmitting ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!viewModel.canSubmit || viewModel.isSubmitting)

            if let submitBlockReason = viewModel.submitBlockReason {
                Text(submitBlockReason)
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
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
                .background(Color(red: 1.0, green: 0.58, blue: 0.53).opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

private struct TradeResultCard: View {
    let message: String?
    let match: TradeMatch?
    let onClose: () -> Void

    var body: some View {
        if let message {
            if let match {
                matchResult(match)
            } else {
                simpleResult(message)
            }
        }
    }

    private func matchResult(_ match: TradeMatch) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(Color.green)

            VStack(spacing: 6) {
                Text("成立！")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("\(match.partnerOffer.seller.displayName) と交換できたよ")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                TradeResultItem(title: "わたす", condition: match.myOffer.offering, color: .blue)
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(Color.green)
                TradeResultItem(title: "もらう", condition: match.partnerOffer.offering, color: .pink)
            }

            Button {
                onClose()
            } label: {
                Label("わかった", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.18))
                    .foregroundStyle(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.green.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.28), lineWidth: 1)
        )
    }

    private func simpleResult(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)

            Text(message == "出品を取り消したよ" ? "取り消しできたよ" : "出品リストに入ったよ")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Button("とじる") {
                onClose()
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.yellow.opacity(0.32))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct TradeResultItem: View {
    let title: String
    let condition: TradeCondition
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            Text(condition.title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.horizontal, 8)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct TradeOffersView: View {
    let viewModel: TradeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("みんなの出品")
                    .font(.system(size: 28, weight: .black, design: .rounded))

                TradeResultCard(
                    message: viewModel.message,
                    match: viewModel.match,
                    onClose: viewModel.clearResult
                )

                if viewModel.isLoading {
                    loadingState
                } else if viewModel.openOffers.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 14) {
                        ForEach(viewModel.openOffers) { offer in
                            let isOwnOffer = viewModel.isOwnOffer(offer)
                            let acceptBlockReason = isOwnOffer ? nil : viewModel.acceptBlockReason(for: offer)
                            TradeOfferRow(
                                offer: offer,
                                canCancel: isOwnOffer,
                                canAccept: viewModel.canAccept(offer),
                                acceptBlockReason: acceptBlockReason,
                                isAccepting: viewModel.acceptingOfferId == offer.id,
                                onCancel: {
                                    Task { await viewModel.cancelOffer(id: offer.id) }
                                },
                                onAccept: {
                                    Task { await viewModel.acceptOffer(id: offer.id) }
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
        .background(Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea())
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
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
    let canAccept: Bool
    let acceptBlockReason: String?
    let isAccepting: Bool
    let onCancel: () -> Void
    let onAccept: () -> Void

    init(
        offer: TradeOffer,
        canCancel: Bool = false,
        canAccept: Bool = false,
        acceptBlockReason: String? = nil,
        isAccepting: Bool = false,
        onCancel: @escaping () -> Void = {},
        onAccept: @escaping () -> Void = {}
    ) {
        self.offer = offer
        self.canCancel = canCancel
        self.canAccept = canAccept
        self.acceptBlockReason = acceptBlockReason
        self.isAccepting = isAccepting
        self.onCancel = onCancel
        self.onAccept = onAccept
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
                    .background(offer.status == .open ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .clipShape(Capsule())
            }

            HStack(spacing: 10) {
                ConditionPill(title: "出す", condition: offer.offering, color: .blue)
                Image(systemName: "arrow.left.arrow.right")
                    .fontWeight(.black)
                    .foregroundStyle(.secondary)
                ConditionPill(title: "ほしい", condition: offer.requesting, color: .pink)
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
            } else if let acceptBlockReason {
                Label(acceptBlockReason, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.red.opacity(0.10))
                    .foregroundStyle(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Button {
                    onAccept()
                } label: {
                    HStack {
                        if isAccepting {
                            ProgressView()
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isAccepting ? "交換しているよ…" : "この人と交換する")
                    }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(canAccept && !isAccepting ? Color.green.opacity(0.18) : Color.gray.opacity(0.14))
                    .foregroundStyle(canAccept && !isAccepting ? .green : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canAccept || isAccepting)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
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

#Preview("交換成立") {
    NavigationStack {
        TradeOffersView(viewModel: TradeViewModel(
            profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"),
            offers: TradeViewModel.sampleOffers,
            match: TradeMatch(
                id: "preview-my-offer-preview-partner-offer",
                myOffer: TradeOffer(
                    id: "preview-my-offer",
                    mealDate: "2026-05-31",
                    seller: StudentSummary(attendanceNumber: 12, nickname: "もぐ"),
                    offering: .tomato,
                    requesting: .greenPepper,
                    status: .matched,
                    matchedOfferId: "preview-partner-offer",
                    matchedAt: Date()
                ),
                partnerOffer: TradeOffer(
                    id: "preview-partner-offer",
                    mealDate: "2026-05-31",
                    seller: StudentSummary(attendanceNumber: 8, nickname: "はる"),
                    offering: .greenPepper,
                    requesting: .tomato,
                    status: .matched,
                    matchedOfferId: "preview-my-offer",
                    matchedAt: Date()
                ),
                matchedAt: Date()
            ),
            message: "トレード成立！"
        ))
    }
}
