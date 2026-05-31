import SwiftUI
import FirebaseCore

struct StudentsInformationView: View {
    
    @State var viewModel:  StudentsInformationViewModel
    
    
    var body: some View {
        NavigationStack {
            
            List {
                ForEach(viewModel.students) { student in
                    NavigationLink {
                        AllergyRegistrationView(
                            viewModel: AllergyRegistrationViewModel(
                                classId: viewModel.classId,
                                focusedStudentNumber: student.studentNumber,
                                focusedStudentName: student.name
                            )
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {

                            Text(student.name)
                                .font(.headline)

                            Text("学籍番号: \(student.studentNumber)")
                            Text("ポイント: \(viewModel.point(for: student))")

                            Text("アレルギー: \(student.allergies.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            }
            .navigationTitle("生徒一覧")
            .onAppear(){
                Task{
                   await viewModel.getStudents()
                }
            }
        }
    }
}

#Preview {
    StudentsInformationView(viewModel: StudentsInformationViewModel(classId: "123456"))
}
