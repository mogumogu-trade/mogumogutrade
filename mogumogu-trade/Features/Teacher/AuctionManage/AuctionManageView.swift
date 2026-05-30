import SwiftUI

struct AuctionManageView: View {
    var body: some View {
        VStack(spacing: 20) {
            // オークション開催カード
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(TeacherColors.accentOrange)
                    Text("オークション開催")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(TeacherColors.chocoLight)
                }
                
                // ステータスボックス
                VStack(spacing: 8) {
                    Text("現在は未開催")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(TeacherColors.textLight)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                    
                    Text("給食であまったメニューを\n出品しましょう。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(TeacherColors.textLight)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity)
                .padding(15)
                .background(TeacherColors.cream)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6]))
                )
                
                // 開催ボタン
                Button(action: {
                    print("オークション設定画面へ遷移")
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("新しいオークションを開催")
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(TeacherColors.accentOrange)
                    .cornerRadius(15)
                    .shadow(color: Color(red: 0.7, green: 0.3, blue: 0.0), radius: 0, x: 0, y: 5)
                }
                
                // 本日の履歴
                Text("本日の履歴")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(TeacherColors.textLight)
                    .padding(.top, 10)
                
//                VStack(spacing: 0) {
//                    ForEach(dummyHistory) { history in
//                        HStack {
//                            Text(history.menu)
//                                .font(.system(size: 14, weight: .bold))
//                                .foregroundColor(TeacherColors.choco)
//                            Spacer()
//                            Text("\(history.winners) 落札")
//                                .font(.system(size: 13, weight: .bold))
//                                .foregroundColor(TeacherColors.accentPink)
//                        }
//                        .padding(.vertical, 12)
//                        
//                        if history.id != dummyHistory.last?.id {
//                            Divider().background(Color.gray.opacity(0.3))
//                        }
//                    }
//                }
//                .padding(.horizontal, 15)
//                .background(Color(red: 0.97, green: 0.98, blue: 0.98))
//                .cornerRadius(12)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 2))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - プレビュー
#Preview {
    // 先生用のダッシュボード全体（タブ付き）の中でプレビューを確認できるようにします
    TeacherDashboardView()
}
