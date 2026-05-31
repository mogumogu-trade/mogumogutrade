import SwiftUI

struct LoseView: View {
    // この画面専用のアニメーションスイッチ
    @State private var isGlitching = false
    @State private var scanlineOffset: CGFloat = -50
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Text("ERROR")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(Color.pink)
                    .offset(x: isGlitching ? -3 : 2, y: isGlitching ? 1 : -1)
                
                Text("ERROR")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(Color.blue)
                    .offset(x: isGlitching ? 3 : -2, y: isGlitching ? -1 : 1)
                
                Text("ERROR")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(AppColors.darkText)
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true)) {
                    isGlitching.toggle()
                }
            }
            
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.darkText)
                .rotationEffect(.degrees(-10))
                .padding(.vertical, 10)
            
            Text("落札に失敗しました。")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.darkText)
                .tracking(1)
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .frame(height: 5)
                    .offset(y: scanlineOffset)
                    .onAppear {
                        scanlineOffset = -50
                        withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            scanlineOffset = 100
                        }
                    }
                
                VStack(spacing: 5) {
                    Text("返還ポイント")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                    Text("減りません")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.darkText)
                }
                .padding(.vertical, 15)
            }
            .frame(width: 200, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.top, 10)
            
            Text("参加費の5Pは使ったよ")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(AppColors.darkText)
                .cornerRadius(12)
                .padding(.top, 5)
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.lose).cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
}
