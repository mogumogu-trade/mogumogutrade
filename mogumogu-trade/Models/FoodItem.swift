import Foundation

/// 給食などの食材1品と、それに含まれるアレルゲン。
///
/// `id` はトレード機能の `TradeCondition.id`（給食カテゴリ）と同じ文字列にしてある。
/// トレード機能がマージされたら、`AllergenCatalog.allergens(forFoodID:)` を介して
/// `TradeCondition` → アレルゲン を 1 行で橋渡しできる。
struct FoodItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let allergens: Set<Allergen>
}

/// 食材 → アレルゲンの対応表。
///
/// id は `TradeCondition`（codex/trade-local-flow）の給食条件 id と一致させている。
/// `food-bread` などトレードにまだ無い id は将来の献立用プレースホルダ。
enum AllergenCatalog {
    static let foods: [FoodItem] = [
        // 現在トレードに存在する給食条件
        FoodItem(id: "food-tomato", title: "トマト", allergens: []),
        FoodItem(id: "food-green-pepper", title: "ピーマン", allergens: []),
        FoodItem(id: "food-carrot", title: "にんじん", allergens: []),
        FoodItem(id: "food-milk", title: "牛乳", allergens: [.milk]),
        // 将来の献立向けプレースホルダ（アレルゲンを持つ例）
        FoodItem(id: "food-bread", title: "パン", allergens: [.wheat]),
        FoodItem(id: "food-omelet", title: "たまごやき", allergens: [.egg]),
        FoodItem(id: "food-soba", title: "そば", allergens: [.soba]),
    ]

    private static let byID: [String: FoodItem] = Dictionary(
        uniqueKeysWithValues: foods.map { ($0.id, $0) }
    )

    /// 食材 id に含まれるアレルゲン。未知の id は空集合（給食以外/不明はブロック対象外）。
    static func allergens(forFoodID id: String) -> Set<Allergen> {
        byID[id]?.allergens ?? []
    }

    /// 食材 id の表示名（不明なら nil）。
    static func title(forFoodID id: String) -> String? {
        byID[id]?.title
    }
}
