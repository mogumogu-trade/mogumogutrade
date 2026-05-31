import SwiftUI

struct AuctionPreparationView: View {
    // 親ファイル(AuctionManageView)からデータをもらうために @Binding を使います
    @Binding var menus: [AuctionActiveModel]
    @Binding var isAuctionActive: Bool
    
    // この画面の中だけで使う入力用の変数
    @State private var newMenuName: String = ""
    @State private var newMenuCount: Int = 1
    
    var body: some View {
        VStack(spacing: 16) {
            
            // 1. ステータス表示
            VStack(spacing: 8) {
                Text("準備中 (未開催)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color(white: 0.9))
                    .cornerRadius(20)
                
                Text("あまったメニューを追加して\nオークションを開始しましょう。")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6]))
            )
            
            // 2. メニュー追加フォーム
            VStack(alignment: .leading, spacing: 12) {
                Text("出品メニューの追加")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray)
                
                TextField("メニュー名 (例: 唐揚げ)", text: $newMenuName)
                    .padding()
                    .background(Color(white: 0.96))
                    .cornerRadius(12)
                    .font(.system(size: 16, weight: .bold))
                
                    Button(action: addMenu) {
                        Text("追加")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(newMenuName.isEmpty ? .gray : .orange)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(newMenuName.isEmpty ? Color(white: 0.9) : Color.orange.opacity(0.15))
                            .cornerRadius(12)
                    }
                    .disabled(newMenuName.isEmpty)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            
            // 3. 追加されたメニューのリスト
            ScrollView {
                VStack(spacing: 12) {
                    if menus.isEmpty {
                        Text("追加されたメニューがここに表示されます")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                    } else {
                        ForEach(menus) { menu in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(menu.name)
                                        .font(.system(size: 16, weight: .bold))
                                }
                                Spacer()
                                Button(action: { deleteMenu(menu: menu) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.gray)
                                        .padding(8)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
                        }
                    }
                }
                .padding(.top, 4)
            }
            
            // 4. オークション開始ボタン
            Button(action: { isAuctionActive = true }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                    Text("この内容でオークションを開始")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                }
                .foregroundColor(menus.isEmpty ? .gray : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(menus.isEmpty ? Color(white: 0.85) : Color.orange)
                .cornerRadius(16)
                .shadow(color: menus.isEmpty ? .clear : Color(red: 0.76, green: 0.25, blue: 0.05), radius: 0, x: 0, y: 5)
            }
            .disabled(menus.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
    private func addMenu() {
        guard !newMenuName.isEmpty else { return }
        menus.append(AuctionActiveModel(name: newMenuName, stock: newMenuCount))
        newMenuName = ""
        newMenuCount = 1
    }
    
    private func deleteMenu(menu: AuctionActiveModel) {
        menus.removeAll { $0.id == menu.id }
    }
}
