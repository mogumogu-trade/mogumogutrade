import Foundation

/// 食物アレルギーの原因物質。
///
/// v1 では消費者庁が表示を義務づける「特定原材料」8品目を扱う。
/// 将来「特定原材料に準ずるもの」(20品目) を追加できるよう、列挙ベースで持つ。
enum Allergen: String, CaseIterable, Identifiable, Codable, Sendable {
    case egg
    case milk
    case wheat
    case shrimp
    case crab
    case soba
    case peanut
    case walnut

    var id: String { rawValue }

    /// 子ども・教員向けの表示名。
    var displayName: String {
        switch self {
        case .egg: "たまご"
        case .milk: "牛乳"
        case .wheat: "小麦"
        case .shrimp: "えび"
        case .crab: "かに"
        case .soba: "そば"
        case .peanut: "らっかせい"
        case .walnut: "くるみ"
        }
    }
}
