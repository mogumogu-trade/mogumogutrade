import Dependencies
import SwiftUI

struct AppRootView: View {
    @State private var profile: StudentProfile?

    init() {
        @Dependency(\.profileStorage) var profileStorage
        _profile = State(initialValue: profileStorage.load())
    }

    var body: some View {
        if let profile {
            HomeView(viewModel: HomeViewModel(profile: profile))
        } else {
            ClassJoinView(viewModel: ClassJoinViewModel(onJoined: { profile = $0 }))
        }
    }
}

#Preview("初回起動") {
    withDependencies {
        $0.profileStorage.load = { nil }
    } operation: {
        AppRootView()
    }
}

#Preview("自動参加") {
    withDependencies {
        $0.profileStorage.load = {
            StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ")
        }
    } operation: {
        AppRootView()
    }
}
