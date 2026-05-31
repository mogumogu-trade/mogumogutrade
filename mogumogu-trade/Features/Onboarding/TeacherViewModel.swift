import Dependencies
import FirebaseCore
import Foundation

@Observable
@MainActor
final class TeacherViewModel {
    var classCode: String = ""
    var pass: String = ""
    var isSubmitting: Bool = false
    var errorMessage: String?
    var isAuthenticated: Bool = false

    @ObservationIgnored @Dependency(\.classClient) private var classClient
  

    var isClassCodeValid: Bool {
        let digits = classCode.filter(\.isNumber)
        return digits == classCode && (4...6).contains(classCode.count)
    }

    var isPass: Bool {
        let trimmed = pass.trimmingCharacters(in: .whitespaces)
        guard (1...8).contains(trimmed.count) else { return false }
        if trimmed.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) { return false }
        if trimmed.unicodeScalars.contains(where: \.properties.isEmojiPresentation) { return false }
        return true
    }

    var canSubmit: Bool {
        !isSubmitting && isClassCodeValid && isPass
    }

    // 入力中の欄が不正なときだけ理由を返す（未入力のときは出さない）
    var classCodeHint: String? {
        guard !classCode.isEmpty, !isClassCodeValid else { return nil }
        return "4〜6けたの すうじを いれてね"
    }

    var passHint: String? {
        guard !pass.isEmpty, !isPass else { return nil }
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
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil
        
        defer { isSubmitting = false }

        do {
            let exists = try await classClient.verifyClass(classId: classCode)
            guard exists else {
                errorMessage = "そのクラスコードは見つかりません"
                return
            }
            if pass != "123456"{
                errorMessage = "パスワードが違います"
                return
            }
            isAuthenticated = true
            
        } catch {
            errorMessage = "通信に失敗しました。もう一度ためしてね"
        }
    }
}
