import Dependencies
import Foundation

/// 教員用: クラスの生徒ごとにアレルギーを登録・更新する ViewModel。
///
/// AGENTS.md「アレルギー情報の登録・更新は教員のみ」に対応する画面のロジック。
@Observable
@MainActor
final class AllergyRegistrationViewModel {
    let classId: String

    /// 単一生徒モードで編集対象とする出席番号。nil ならクラス全員から選ぶ従来モード。
    let focusedStudentNumber: Int?
    /// 単一生徒モードでの表示名（名簿読込前のフォールバック用）。
    private let focusedStudentName: String?

    private(set) var roster: [StudentAllergy] = []
    private(set) var selectedStudentNumber: Int?
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?
    private(set) var savedMessage: String?

    @ObservationIgnored @Dependency(\.allergyClient) private var allergyClient

    init(
        classId: String,
        focusedStudentNumber: Int? = nil,
        focusedStudentName: String? = nil
    ) {
        self.classId = classId
        self.focusedStudentNumber = focusedStudentNumber
        self.focusedStudentName = focusedStudentName
        self.selectedStudentNumber = focusedStudentNumber
    }

    /// 生徒一覧からタップして特定生徒だけを編集するモードか。
    var isSingleStudentMode: Bool { focusedStudentNumber != nil }

    /// 単一生徒モードで画面に出す対象生徒の表示名。名簿読込前は引数のフォールバックを使う。
    var focusedDisplayName: String {
        if let selectedStudent { return selectedStudent.displayName }
        guard let focusedStudentNumber else { return "" }
        let name = focusedStudentName ?? ""
        return name.isEmpty ? "\(focusedStudentNumber)番" : "\(focusedStudentNumber)番 \(name)"
    }

    var selectedStudent: StudentAllergy? {
        guard let selectedStudentNumber else { return nil }
        return roster.first { $0.studentNumber == selectedStudentNumber }
    }

    var canSave: Bool {
        !isSaving && selectedStudent != nil
    }

    var saveHint: String? {
        guard !isSaving, selectedStudent == nil else { return nil }
        return "生徒を選んでください"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            roster = try await allergyClient.loadRoster(classId: classId)
            if let focusedStudentNumber {
                // 単一生徒モード: 名簿に未登録でも編集できるよう仮エントリを補う。
                if !roster.contains(where: { $0.studentNumber == focusedStudentNumber }) {
                    roster.append(
                        StudentAllergy(
                            studentNumber: focusedStudentNumber,
                            nickname: focusedStudentName ?? "",
                            allergens: []
                        )
                    )
                }
                selectedStudentNumber = focusedStudentNumber
            } else if selectedStudentNumber == nil {
                selectedStudentNumber = roster.first?.studentNumber
            }
        } catch {
            errorMessage = "読み込みに失敗しました"
        }
    }

    func select(_ studentNumber: Int) {
        selectedStudentNumber = studentNumber
        savedMessage = nil
    }

    func isOn(_ allergen: Allergen) -> Bool {
        selectedStudent?.allergens.contains(allergen) ?? false
    }

    func toggle(_ allergen: Allergen) {
        guard
            let selectedStudentNumber,
            let index = roster.firstIndex(where: { $0.studentNumber == selectedStudentNumber })
        else { return }

        if roster[index].allergens.contains(allergen) {
            roster[index].allergens.remove(allergen)
        } else {
            roster[index].allergens.insert(allergen)
        }
        savedMessage = nil
    }

    func save() async {
        guard canSave, let student = selectedStudent else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await allergyClient.save(classId: classId, allergy: student)
            savedMessage = "\(student.displayName) のアレルギーを保存しました"
        } catch {
            errorMessage = "保存に失敗しました"
        }
    }
}
