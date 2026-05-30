import SwiftUI

struct WaitingView: View {
    @Binding var myPoints: Int
    @Binding var lastBetAmount: Int
    @Binding var screenState: String
    
    // この画面専用のアニメーションスイッチ
    @State private var isRotating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("ベット完了！")
                .font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(AppColors.darkText).cornerRadius(20)
                .rotationEffect(.degrees(-3))
            
            Image(systemName: "hourglass")
                .font(.system(size: 80)).foregroundColor(AppColors.darkText)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                    
                    // 3秒後に自動で結果判定を行う
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if screenState == "wait" {
                            let isWin = Bool.random()
                            if isWin {
                                screenState = "win"
                            } else {
                                myPoints += lastBetAmount
                                screenState = "lose"
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
            
            VStack(spacing: 5) {
                Text("先生が締め切るまで")
                Text("しずかに待ってね… 🤫")
            }
            .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(AppColors.darkText)
            .padding(.horizontal, 25).padding(.vertical, 15).background(Color.white).cornerRadius(15)
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.wait).cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
}
