import SwiftUI

struct TeacherDashboardView: View {

    var body: some View {
        TabView {

            AuctionManageView()
                .tabItem {
                    Image(systemName: "bell.badge.fill")
                    Text("開催")
                }

            StudentsInformationView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("生徒")
                }

          //  HistoryView()
                .tabItem {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("履歴")
                }

        }
    }
}

#Preview {
    TeacherDashboardView()
}
