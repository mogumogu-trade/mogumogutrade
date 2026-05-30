import Foundation

@Observable
@MainActor
final class HomeViewModel {
    let profile: StudentProfile

    init(profile: StudentProfile) {
        self.profile = profile
    }

    var displayName: String {
        "\(profile.studentNumber)番 \(profile.nickname)"
    }
}
