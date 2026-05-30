import SwiftUI
import FirebaseCore

struct StudentManageView: View {
    
    @Environment(\.dismiss) var dismiss // 画面を閉じるための機能
    let student: Student
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // アイコン
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(TeacherColors.accentMint)
                    .padding(.top, 40)
                
                // 出席番号と名前
                Text("\(student.studentNumber)番  \(student.name)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(TeacherColors.textMain)
                
                // ポイント表示の大きなカード
                VStack(spacing: 10) {
                    Text("現在の完食ポイント")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(TeacherColors.textLight)
                    
                    Text("\(student.point) P")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(TeacherColors.accentOrange)
                }
                .frame(maxWidth: .infinity)
                .padding(30)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                // 先生がポイントを直接操作できるボタン
                HStack(spacing: 15) {
                    Button(action: {
                        print("ポイントを減らしました")
                    }) {
                        Text("- 50 P")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                    
                    Button(action: {
                        print("ポイントを追加しました")
                    }) {
                        Text("+ 50 P")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(TeacherColors.bgGray.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(TeacherColors.textLight)
                    }
                }
            }
        }
    }
}
#Preview{
    StudentManageView(student: Student(id: UUID(), name: "", studentNumber: 2, point: 5, allergies: [], createdAt: Timestamp(date: Date())))
}
