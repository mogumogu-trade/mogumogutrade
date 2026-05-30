import SwiftUI
import FirebaseCore

struct StudentsInformationView: View {
    
    @State private var viewModel =  StudentsInformationViewModel()
    
    
    var body: some View {
        NavigationStack {
            
            List {
                ForEach(viewModel.students) { student in
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        Text(student.name)
                            .font(.headline)
                        
                        Text("学籍番号: \(student.studentNumber)")
                        Text("ポイント: \(student.point)")
                        
                        Text("アレルギー: \(student.allergies.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .navigationTitle("生徒一覧")
        }
    }
}

#Preview {
    StudentsInformationView()
}
