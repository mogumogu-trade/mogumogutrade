import Dependencies
import Foundation

/// 教員用: クラスの生徒ごとにアレルギーを登録・更新する ViewModel。
///
/// AGENTS.md「アレルギー情報の登録・更新は教員のみ」に対応する画面のロジック。
@Observable
@MainActor
final class AllergyRegistrationViewModel {
    let classId: String

    private(set) var roster: [StudentAllergy] = []
    private(set) var selectedStudentNumber: Int?
    private(set) var isLoading = false
    private(set) var isSaving = false
    var errorMessage: String?
    private(set) var savedMessage: String?

    @ObservationIgnored @Dependency(\.allergyClient) private var allergyClient

    init(classId: String) {
        self.classId = classId
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
        return "生徒をえらんでね"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            roster = try await allergyClient.loadRoster(classId: classId)
            if selectedStudentNumber == nil {
                selectedStudentNumber = roster.first?.studentNumber
            }
        } catch {
            errorMessage = "よみこみに しっぱいしました"
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
            savedMessage = "\(student.displayName) のアレルギーを ほぞんしたよ"
        } catch {
            errorMessage = "ほぞんに しっぱいしました"
        }
    }
}
