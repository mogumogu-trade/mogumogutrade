import SwiftUI

struct BetView: View {
    // 親から受け取る表示用のデータ
    let menuItems: [String]
    let stocks: [Int]
    
    // 親のデータを直接書き換えるための @Binding
    @Binding var currentIndex: Int
    @Binding var myPoints: Int
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
                    .foregroundColor(AppColors.darkText)
                Text("持っているポイント: \(myPoints) P")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.darkText)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(20)
            
            HStack(spacing: 15) {
                Button(action: {
                    if currentIndex == 0 { currentIndex = menuItems.count - 1 } else { currentIndex -= 1 }
                    betAmountString = ""
                }) {
                    Image(systemName: "arrowtriangle.left.fill")
                        .font(.system(size: 20)).foregroundColor(.white)
                        .frame(width: 40, height: 40).background(Color.white.opacity(0.3)).cornerRadius(12)
                }
                
                ZStack {
                    Circle().strokeBorder(Color.white, lineWidth: 4).background(Circle().fill(Color.white.opacity(0.2))).frame(width: 90, height: 90)
                    Text(menuItems[currentIndex])
                        .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundColor(.white).multilineTextAlignment(.center)
                    Text("残り\(stocks[currentIndex])人")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(AppColors.bet)
                        .padding(.horizontal, 8).padding(.vertical, 4).background(Color.white).cornerRadius(10)
                        .offset(x: 35, y: -40)
                }
                
                Button(action: {
                    if currentIndex == menuItems.count - 1 { currentIndex = 0 } else { currentIndex += 1 }
                    betAmountString = ""
                }) {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 20)).foregroundColor(.white)
                        .frame(width: 40, height: 40).background(Color.white.opacity(0.3)).cornerRadius(12)
                }
            }
            
            VStack(spacing: 5) {
                Text("ベットする額を入れてね")
                    .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                
                HStack {
                    TextField("0", text: $betAmountString)
                        .keyboardType(.numberPad).multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(AppColors.darkText)
                        .padding(.vertical, 10).background(Color.white).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 3))
                    Text("P").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                }
                .padding(.horizontal, 50)
                
                let currentBet = Int(betAmountString) ?? 0
                if currentBet > myPoints {
                    Text("持っているポイントより多いよ！").font(.system(size: 12, weight: .bold)).foregroundColor(.yellow).padding(.top, 5)
                } else {
                    Text(" ").font(.system(size: 12)).padding(.top, 5)
                }
            }
            .onChange(of: betAmountString) { oldValue, newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                if filtered != newValue { betAmountString = filtered }
            }
            .padding(.vertical, 10)
            
            let currentBetAmount = Int(betAmountString) ?? 0
            let isValidBet = currentBetAmount > 0 && currentBetAmount <= myPoints
            
            Button(action: {
                myPoints -= currentBetAmount
                lastBetAmount = currentBetAmount
                betAmountString = ""
                screenState = "wait"
            }) {
                Text("これでベットする！")
                    .font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.white)
                    .padding(.horizontal, 25).padding(.vertical, 15)
                    .background(isValidBet ? AppColors.darkText : Color.gray).cornerRadius(15)
            }
            .disabled(!isValidBet)
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.bet).cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
}
