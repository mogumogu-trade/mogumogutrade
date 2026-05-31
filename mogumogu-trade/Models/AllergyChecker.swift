import Foundation

/// アレルギーによるトレード可否を判定する純粋ロジック。
///
/// 副作用なし・テスト容易。トレード機能（`TradeViewModel` 等）は、
/// アレルギー判定が必要になったらこの型だけを呼べばよい。
enum AllergyChecker {
    /// `foodID` の食材を、`recipientAllergens` を持つ生徒が受け取ってよいか判定する。
    ///
    /// - Returns: 安全なら `nil`。危険なら子ども向けの理由文
    ///   （例: `"牛乳アレルギーのためトレードできないよ"`）。
    static func blockReason(foodID: String, recipientAllergens: Set<Allergen>) -> String? {
        let foodAllergens = AllergenCatalog.allergens(forFoodID: foodID)
        let hits = foodAllergens.intersection(recipientAllergens)
        guard let allergen = hits.min(by: { $0.rawValue < $1.rawValue }) else {
            return nil
        }
        return "\(allergen.displayName)アレルギーのためトレードできないよ"
    }

    /// 食材を受け取ってよいか（`true` = 安全）。
    static func isSafe(foodID: String, recipientAllergens: Set<Allergen>) -> Bool {
        blockReason(foodID: foodID, recipientAllergens: recipientAllergens) == nil
    }
}
