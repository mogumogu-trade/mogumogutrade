import SwiftUI

struct ContentView: View {
    
    let menuItems = ["揚げ\nパン", "プリン", "ゼリー"]
    let stocks = [2, 1, 3]

    @State private var currentIndex = 0
    @State private var myPoints = 500
    @State private var betAmountString = ""
    @State private var lastBetAmount = 0

    @State private var screenState = "bet"

    var body: some View {
        ZStack {
            switch screenState {

            case "bet":
                BettingView(
                    menuItems: menuItems,
                    stocks: stocks,
                    currentIndex: $currentIndex,
                    myPoints: $myPoints,
                    betAmountString: $betAmountString,
                    lastBetAmount: $lastBetAmount,
                    screenState: $screenState
                )

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
                        LoseView(
                            screenState: $screenState
                        )

            default:
                Text("エラー")
            }
        }
    }
}
