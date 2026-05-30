import SwiftUI

// MARK: - データモデル
// ※ この構造体はプロジェクト全体で使えるようになります
struct AuctionMenu: Identifiable {
    let id = UUID()
    var name: String
    var stock: Int
}

struct TeacherView: View {
    // データは親画面であるここで一括管理します
    @State private var menus: [AuctionMenu] = []
    @State private var isAuctionActive: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ヘッダー部分
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 26))
                    .foregroundColor(isAuctionActive ? .red : .orange)
                
                Text("オークション管理")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.45, green: 0.2, blue: 0.05))
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // 開催状況によって別のファイルのViewを呼び出して切り替える
            // $マークをつけて「このデータを共有するよ」と伝えます
            if isAuctionActive {
                AuctionActiveView(menus: $menus, isAuctionActive: $isAuctionActive)
            } else {
                AuctionPreparationView(menus: $menus, isAuctionActive: $isAuctionActive)
            }
        }
        .background(Color(white: 0.96).ignoresSafeArea())
    }
}

#Preview {
    TeacherView()
}
