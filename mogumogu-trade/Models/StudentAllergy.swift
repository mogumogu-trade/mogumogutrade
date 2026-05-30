import Foundation

/// 1人の生徒のアレルギー登録情報。
///
/// AGENTS.md の方針に従い、出席番号を主識別子(主キー)にする。
/// ニックネームは表示補助。
struct StudentAllergy: Identifiable, Hashable, Codable, Sendable {
    let studentNumber: Int
    var nickname: String
    var allergens: Set<Allergen>

    var id: Int { studentNumber }

    var displayName: String { "\(studentNumber)番 \(nickname)" }
}
