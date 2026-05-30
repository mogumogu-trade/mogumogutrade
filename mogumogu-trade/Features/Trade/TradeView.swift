import SwiftUI

struct TradeView: View {
    @State var viewModel: TradeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                studentCard
                offerBuilder
                resultBanner
                openOfferList
            }
            .padding(24)
        }
        .background(Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea())
        .navigationTitle("今日のトレード")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("リセット") {
                    viewModel.resetSampleData()
                }
                .fontWeight(.bold)
            }
        }
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
                viewModel.submitOffer()
            } label: {
                Label("この条件で出品する", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(viewModel.canSubmit ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(!viewModel.canSubmit)

            if !viewModel.canSubmit {
                Text("同じものどうしは選べないよ")
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
                    Text("出品リストに入ったよ")
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
            .background(viewModel.match == nil ? Color.yellow.opacity(0.32) : Color.green.opacity(0.32))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var openOfferList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("みんなの出品")
                .font(.system(size: 22, weight: .black, design: .rounded))

            ForEach(viewModel.openOffers) { offer in
                TradeOfferRow(offer: offer)
            }
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

            Picker(title, selection: $selection) {
                ForEach(TradeConditionCategory.allCases) { category in
                    Section(category.title) {
                        ForEach(TradeCondition.options(for: category)) { condition in
                            Label(condition.title, systemImage: category.systemImage)
                                .tag(condition)
                        }
                    }
                }
            }
            .pickerStyle(.menu)

            HStack {
                Image(systemName: selection.category.systemImage)
                Text(selection.category.title)
                Text(selection.title)
                    .fontWeight(.black)
                Spacer()
            }
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .padding(14)
            .background(Color(red: 1.0, green: 0.58, blue: 0.53).opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private struct TradeOfferRow: View {
    let offer: TradeOffer

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
