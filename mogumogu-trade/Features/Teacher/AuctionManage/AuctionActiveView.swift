import SwiftUI

struct AuctionActiveView: View {
    // こちらも親ファイルからデータをもらうために @Binding を使います
    @Binding var menus: [AuctionMenu]
    @Binding var isAuctionActive: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. 開催中のアラート表示
            VStack(spacing: 12) {
                Text("🔥 現在開催中 🔥")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(20)
                
                Text("生徒たちがベットしています！")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.red.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.red.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 2)
            )
            
            // 2. 出品中のメニューリスト
            VStack(alignment: .leading, spacing: 12) {
                Text("出品中のメニュー")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(menus) { menu in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(menu.name)
                                        .font(.system(size: 18, weight: .bold))
                                    Text("残り \(menu.stock) 個")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text("受付中")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.15))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                        }
                    }
                }
            }
            
            Spacer()
            
            // 3. 終了ボタン
            Button(action: { isAuctionActive = false }) {
                HStack {
                    Image(systemName: "square.fill")
                        .font(.system(size: 18))
                    Text("オークションを終了する")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(red: 0.15, green: 0.2, blue: 0.25))
                .cornerRadius(16)
                .shadow(color: Color(red: 0.1, green: 0.1, blue: 0.15), radius: 0, x: 0, y: 5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
}
