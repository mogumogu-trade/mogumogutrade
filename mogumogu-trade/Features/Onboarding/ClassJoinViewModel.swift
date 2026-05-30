import Dependencies
import FirebaseCore
import Foundation

@Observable
@MainActor
final class ClassJoinViewModel {
    var classCode: String = ""
    var studentNumberText: String = ""
    var nickname: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?

    @ObservationIgnored @Dependency(\.classClient) private var classClient
    @ObservationIgnored @Dependency(\.profileStorage) private var profileStorage
    @ObservationIgnored @Dependency(\.studentClient) private var studentClient

    let onJoined: (StudentProfile) -> Void

    init(onJoined: @escaping (StudentProfile) -> Void) {
        self.onJoined = onJoined
    }

    var isClassCodeValid: Bool {
        let digits = classCode.filter(\.isNumber)
        return digits == classCode && (4...6).contains(classCode.count)
    }

    var isStudentNumberValid: Bool {
        guard let n = Int(studentNumberText) else { return false }
        return (1...50).contains(n)
    }

    var isNicknameValid: Bool {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard (1...8).contains(trimmed.count) else { return false }
        if trimmed.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) { return false }
        if trimmed.unicodeScalars.contains(where: \.properties.isEmojiPresentation) { return false }
        return true
    }

    var canSubmit: Bool {
        !isSubmitting && isClassCodeValid && isStudentNumberValid && isNicknameValid
    }

    // 入力中の欄が不正なときだけ理由を返す（未入力のときは出さない）
    var classCodeHint: String? {
        guard !classCode.isEmpty, !isClassCodeValid else { return nil }
        return "4〜6けたの すうじを いれてね"
    }

    var studentNumberHint: String? {
        guard !studentNumberText.isEmpty, !isStudentNumberValid else { return nil }
        return "1〜50の ばんごうを いれてね"
    }

    var nicknameHint: String? {
        guard !nickname.isEmpty, !isNicknameValid else { return nil }
        return "1〜8もじ。えもじや きごうは つかえないよ"
    }

    func sanitizeClassCode(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(6))
    }

    func sanitizeStudentNumber(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(2))
    }

    func sanitizeNickname(_ raw: String) -> String {
        String(raw.replacingOccurrences(of: "\n", with: "").prefix(8))
    }

    func submit() async {
        guard canSubmit, let studentNumber = Int(studentNumberText) else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let exists = try await classClient.verifyClass(classId: classCode)
            guard exists else {
                errorMessage = "そのクラスコードは見つかりません"
                return
            }
            
            let student = Student(id: UUID(), name: nickname, studentNumber: studentNumber, point: 0, allergies: [], createdAt: Timestamp(date: Date()))
            try await studentClient.createStudent(classCode, student)
            
            let profile = StudentProfile(
                classId: classCode,
                studentNumber: studentNumber,
                nickname: nickname.trimmingCharacters(in: .whitespaces)
            )
            profileStorage.save(profile)
            onJoined(profile)
        } catch {
            errorMessage = "通信に失敗しました。もう一度ためしてね"
        }
    }
}
