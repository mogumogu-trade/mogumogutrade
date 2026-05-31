import SwiftUI

struct BetView: View {
    let room: AuctionRoom
    @Bindable var viewModel: AuctionViewModel

    @State private var betAmountString = ""

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(AppColors.boardBorder)

                RoundedRectangle(cornerRadius: 25)
                    .fill(AppColors.boardInner)
                    .padding(10)

                content
            }
            .frame(maxHeight: 620)
            .padding(.horizontal, 20)
        }
        .navigationTitle("ブラインドオークション")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screenState {
        case .bidding:
            BettingView(
                room: room,
                pointBalance: viewModel.pointBalance,
                isFirstBid: viewModel.isFirstBid,
                isSubmitting: viewModel.isSubmittingBid,
                errorMessage: viewModel.errorMessage,
                betAmountString: $betAmountString,
                onSubmit: { amount in
                    Task { await viewModel.submitBid(amount: amount) }
                }
            )
        case .waiting:
            WaitingView(lastBetAmount: viewModel.myBid?.amount ?? 0)
        case let .win(winner):
            WinView(lastBetAmount: winner.bidAmount)
        case .lose:
            LoseView()
        case .noWinner:
            AuctionNoWinnerView()
        case .resultPending:
            AuctionResultPendingView()
        }
    }
}

private struct AuctionNoWinnerView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 72))
                .foregroundColor(AppColors.darkText)

            Text("今回は落札なし")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            Text("ベット分はへらないよ")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.darkText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(15)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.wait)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
}

private struct AuctionResultPendingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "hourglass")
                .font(.system(size: 72))
                .foregroundColor(AppColors.darkText)

            Text("結果を見ているよ")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(AppColors.darkText)

            ProgressView()
                .tint(AppColors.darkText)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.wait)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
}

#Preview {
    NavigationStack {
        BetView(
            room: AuctionRoom(id: "preview", itemName: "プリン", stockCount: 1),
            viewModel: AuctionViewModel(
                profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"),
                activeRoom: AuctionRoom(id: "preview", itemName: "プリン", stockCount: 1),
                pointBalance: 120
            )
        )
    }
}
