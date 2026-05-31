import SwiftUI

struct BettingView: View {
    let room: AuctionRoom
    @Binding var pointBalance: Int
    @Binding var betAmountString: String
    @Binding var lastBetAmount: Int
    @Binding var screenState: String

    var body: some View {
        VStack(spacing: 20) {
            Text("欲しいものを\nゲットしよう！")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(AppColors.primary)
                Text("持っているポイント: \(pointBalance) P")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.darkText)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(AppColors.card)
            .cornerRadius(20)

            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .background(Circle().fill(Color.white.opacity(0.2)))
                        .frame(width: 90, height: 90)

                    Text(room.itemName)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("残り\(room.stockCount)人")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(10)
                        .offset(x: 35, y: -40)
                }
            }

            VStack(spacing: 5) {
                Text("ベットする額を入れてね")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack {
                    TextField("0", text: $betAmountString)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 3))
                    Text("P")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 50)

                let currentBet = Int(betAmountString) ?? 0
                if currentBet > pointBalance {
                    Text("持っているポイントより多いよ！")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColors.primaryLight)
                        .padding(.top, 5)
                } else {
                    Text(" ")
                        .font(.system(size: 12))
                        .padding(.top, 5)
                }
            }
            .onChange(of: betAmountString) { _, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    betAmountString = filtered
                }
            }
            .padding(.vertical, 10)

            let currentBetAmount = Int(betAmountString) ?? 0
            let isValidBet = currentBetAmount > 0 && currentBetAmount <= pointBalance

            Button {
                lastBetAmount = currentBetAmount
                betAmountString = ""
                screenState = "wait"
            } label: {
                Text("これでベットする！")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 15)
                    .background(isValidBet ? AppColors.primary : Color.gray)
                    .cornerRadius(15)
                    .shadow(color: isValidBet ? AppColors.primary.opacity(0.35) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!isValidBet)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bet)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
}
