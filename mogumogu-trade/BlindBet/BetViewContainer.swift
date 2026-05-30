import SwiftUI

struct BetView: View {
    private let menuItems = ["揚げ\nパン", "プリン", "ゼリー"]
    private let stocks = [2, 1, 3]

    @State private var currentIndex = 0
    @State private var myPoints = 500
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
                        myPoints: $myPoints,
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
                        menuItems: menuItems,
                        stocks: stocks,
                        currentIndex: $currentIndex,
                        myPoints: $myPoints,
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
        BetView()
    }
}
