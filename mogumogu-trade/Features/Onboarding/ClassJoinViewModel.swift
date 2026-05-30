import Dependencies
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
        guard !trimmed.isEmpty else { return false }
        guard (1...8).contains(nickname.count) else { return false }
        if nickname.contains(where: { $0.isNewline }) { return false }
        if nickname.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) { return false }
        if nickname.unicodeScalars.contains(where: \.properties.isEmojiPresentation) { return false }
        if nickname.unicodeScalars.contains(where: { $0.properties.isEmoji && !($0.value >= 0x30 && $0.value <= 0x39) }) {
            return false
        }
        let lower = nickname.lowercased()
        if lower.contains("http://") || lower.contains("https://") || lower.contains("www.") { return false }
        if lower.contains("@") && lower.contains(".") { return false }
        return true
    }

    var canSubmit: Bool {
        !isSubmitting && isClassCodeValid && isStudentNumberValid && isNicknameValid
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
