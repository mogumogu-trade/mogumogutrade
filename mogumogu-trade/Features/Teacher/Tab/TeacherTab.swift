import SwiftUI

struct TeacherDashboardView: View {
    let classId: String

    var body: some View {
        TabView {

            TeacherView()
                .tabItem {
                    Image(systemName: "bell.badge.fill")
                    Text("開催")
                }

            StudentsInformationView(viewModel: StudentsInformationViewModel(classId: classId))
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("生徒")
                }


        }
    }
}

#Preview {
    TeacherDashboardView(classId: "123456")
}
