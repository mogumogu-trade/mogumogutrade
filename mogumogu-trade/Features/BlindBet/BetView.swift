import SwiftUI

struct BettingView: View {
    let room: AuctionRoom
    let pointBalance: Int
    let isFirstBid: Bool
    let isSubmitting: Bool
    let errorMessage: String?
    @Binding var betAmountString: String
    let onSubmit: (Int) -> Void

    private var currentBetAmount: Int {
        Int(betAmountString) ?? 0
    }

    private var requiredPoints: Int {
        currentBetAmount + (isFirstBid ? AuctionClient.participationFee : 0)
    }

    private var isValidBet: Bool {
        currentBetAmount > 0 && requiredPoints <= pointBalance && !isSubmitting
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("欲しいものを\nゲットしよう！")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(AppColors.darkText)
                Text("持っているポイント: \(pointBalance) P")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.darkText)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(20)

            ZStack {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 4)
                    .background(Circle().fill(Color.white.opacity(0.2)))
                    .frame(width: 96, height: 96)

                Text(room.itemName)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)
                    .padding(10)

                Text("1人だけ")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.bet)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(10)
                    .offset(x: 34, y: -44)
            }

            VStack(spacing: 7) {
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

                Text(isFirstBid ? "参加に5Pつかうよ" : "参加費はもう払ったよ")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 2)

                validationMessage
            }
            .onChange(of: betAmountString) { _, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue {
                    betAmountString = filtered
                }
            }
            .padding(.vertical, 10)

            Button {
                onSubmit(currentBetAmount)
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSubmitting ? "ベット中..." : "これでベットする！")
                }
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(isValidBet ? AppColors.darkText : Color.gray)
                .cornerRadius(15)
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

    @ViewBuilder
    private var validationMessage: some View {
        if let errorMessage {
            Text(errorMessage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.yellow)
                .padding(.top, 5)
        } else if currentBetAmount > 0 && requiredPoints > pointBalance {
            Text(isFirstBid ? "参加費とベット分のポイントが必要だよ" : "持っているポイントより多いよ！")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.yellow)
                .padding(.top, 5)
        } else {
            Text(" ")
                .font(.system(size: 12))
                .padding(.top, 5)
        }
    }
}
