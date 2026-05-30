import SwiftUI

//// MARK: - 履歴画面
//struct HistoryView: View {
//    var body: some View {
//        VStack {
//            VStack(alignment: .leading, spacing: 15) {
//                HStack(spacing: 8) {
//                    Image(systemName: "gavel")
//                        .foregroundColor(TeacherColors.chocoLight)
//                    Text("本日の開催履歴")
//                        .font(.system(size: 18, weight: .heavy, design: .rounded))
//                        .foregroundColor(TeacherColors.chocoLight)
//                }
//                
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
//            }
//            .padding(20)
//            .background(Color.white)
//            .cornerRadius(20)
//            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 2))
//            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
//        }
//    }
//}
//
//// MARK: - 設定画面
//struct SettingsView: View {
//    var body: some View {
//        VStack {
//            VStack(alignment: .leading, spacing: 15) {
//                HStack(spacing: 8) {
//                    Image(systemName: "gearshape.fill")
//                        .foregroundColor(TeacherColors.textLight)
//                    Text("クラス設定")
//                        .font(.system(size: 18, weight: .heavy, design: .rounded))
//                        .foregroundColor(TeacherColors.chocoLight)
//                }
//                
//                Text("メニューの編集や、\n先生アカウントの設定がここに入ります。")
//                    .font(.system(size: 14, weight: .medium, design: .rounded))
//                    .foregroundColor(TeacherColors.textLight)
//                    .multilineTextAlignment(.center)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 40)
//            }
//            .padding(20)
//            .background(Color.white)
//            .cornerRadius(20)
//            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray.opacity(0.2), lineWidth: 2))
//            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
//        }
//    }
//}
