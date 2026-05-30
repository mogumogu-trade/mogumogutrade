import SwiftUI

struct BetView: View {
    let room: AuctionRoom
    @Binding var pointBalance: Int

    @State private var betAmountString = ""
    @State private var lastBetAmount = 0
    @State private var screenState = "bet"

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .fill(AppColors.boardBorder)

                RoundedRectangle(cornerRadius: 25)
                    .fill(AppColors.boardInner)
                    .padding(10)

                switch screenState {
                case "wait":
                    WaitingView(
                        lastBetAmount: $lastBetAmount,
                        screenState: $screenState
                    )
                case "win":
                    WinView(
                        lastBetAmount: lastBetAmount,
                        screenState: $screenState
                    )
                case "lose":
                    LoseView(screenState: $screenState)
                default:
                    BettingView(
                        room: room,
                        pointBalance: $pointBalance,
                        betAmountString: $betAmountString,
                        lastBetAmount: $lastBetAmount,
                        screenState: $screenState
                    )
                }
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
}

#Preview {
    NavigationStack {
        BetView(
            room: AuctionRoom(id: "preview", itemName: "プリン", stockCount: 1),
            pointBalance: .constant(120)
        )
    }
}
