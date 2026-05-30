import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct ProfileStorageClient: Sendable {
    var load: @Sendable () -> StudentProfile?
    var save: @Sendable (StudentProfile) -> Void
    var clear: @Sendable () -> Void
}

extension ProfileStorageClient: DependencyKey {
    static let liveValue: ProfileStorageClient = {
        let defaults = UserDefaults.standard
        let classIdKey = "studentProfile.classId"
        let studentNumberKey = "studentProfile.studentNumber"
        let nicknameKey = "studentProfile.nickname"

        return ProfileStorageClient(
            load: {
                guard
                    let classId = defaults.string(forKey: classIdKey),
                    let nickname = defaults.string(forKey: nicknameKey),
                    defaults.object(forKey: studentNumberKey) != nil
                else { return nil }
                let studentNumber = defaults.integer(forKey: studentNumberKey)
                return StudentProfile(classId: classId, studentNumber: studentNumber, nickname: nickname)
            },
            save: { profile in
                defaults.set(profile.classId, forKey: classIdKey)
                defaults.set(profile.studentNumber, forKey: studentNumberKey)
                defaults.set(profile.nickname, forKey: nicknameKey)
            },
            clear: {
                defaults.removeObject(forKey: classIdKey)
                defaults.removeObject(forKey: studentNumberKey)
                defaults.removeObject(forKey: nicknameKey)
            }
        )
    }()

    static let previewValue = ProfileStorageClient(
        load: { StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ") },
        save: { _ in },
        clear: {}
    )
}

extension DependencyValues {
    var profileStorage: ProfileStorageClient {
        get { self[ProfileStorageClient.self] }
        set { self[ProfileStorageClient.self] = newValue }
    }
}
