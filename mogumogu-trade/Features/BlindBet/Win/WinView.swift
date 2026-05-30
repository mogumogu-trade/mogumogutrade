import SwiftUI

struct WinView: View {
    let lastBetAmount: Int // 表示するだけなので Binding ではなく let でOK
    @Binding var screenState: String
    
    // この画面専用のアニメーションスイッチ
    @State private var isFloating = false
    @State private var isShining = false
    
    var body: some View {
        ZStack {
            AppColors.win.cornerRadius(15)
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            VStack(spacing: 15) {
                
                Text("GET!!")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
                
                ZStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .padding(.top, 25)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.darkText)
                        .offset(y: isFloating ? -45 : -35)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                isFloating = true
                            }
                        }
                }
                .padding(.vertical, 10)
                
                Text("デザートを獲得したよ！")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.darkText)
                
                VStack(spacing: 5) {
                    Text("消費ポイント")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                    Text("- \(lastBetAmount) P")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                }
                .frame(width: 200)
                .padding(.vertical, 15)
                .background(Color.white)
                .cornerRadius(15)
                .padding(.top, 5)
                
                Button(action: { screenState = "bet" }) {
                    Text("次のゲームへ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(AppColors.darkText).cornerRadius(12)
                }
                .padding(.top, 5)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
}
