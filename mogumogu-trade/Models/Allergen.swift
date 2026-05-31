import Foundation

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
