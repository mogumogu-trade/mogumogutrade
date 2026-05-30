import Foundation

enum TradeConditionCategory: String, CaseIterable, Identifiable, Sendable {
    case food
    case help
    case item

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food:
            "給食"
        case .help:
            "お手伝い"
        case .item:
            "アイテム"
        }
    }

    var systemImage: String {
        switch self {
        case .food:
            "fork.knife"
        case .help:
            "hand.raised.fill"
        case .item:
            "star.fill"
        }
    }
}

struct TradeCondition: Identifiable, Hashable, Sendable {
    let id: String
    let category: TradeConditionCategory
    let title: String

    static let tomato = TradeCondition(id: "food-tomato", category: .food, title: "トマト")
    static let greenPepper = TradeCondition(id: "food-green-pepper", category: .food, title: "ピーマン")
    static let carrot = TradeCondition(id: "food-carrot", category: .food, title: "にんじん")
    static let milk = TradeCondition(id: "food-milk", category: .food, title: "牛乳")
    static let cleaning = TradeCondition(id: "help-cleaning", category: .help, title: "今日の掃除当番を代わる")
    static let serving = TradeCondition(id: "help-serving", category: .help, title: "配膳を手伝う")
    static let sticker = TradeCondition(id: "item-sticker", category: .item, title: "シール")
    static let card = TradeCondition(id: "item-card", category: .item, title: "カード")

    static let all: [TradeCondition] = [
        .tomato,
        .greenPepper,
        .carrot,
        .milk,
        .cleaning,
        .serving,
        .sticker,
        .card,
    ]

    static func options(for category: TradeConditionCategory) -> [TradeCondition] {
        all.filter { $0.category == category }
    }
}

struct StudentSummary: Identifiable, Hashable, Sendable {
    let attendanceNumber: Int
    let nickname: String

    var id: Int { attendanceNumber }
    var displayName: String { "\(attendanceNumber)番 \(nickname)" }

    init(attendanceNumber: Int, nickname: String) {
        self.attendanceNumber = attendanceNumber
        self.nickname = nickname
    }

    init(profile: StudentProfile) {
        self.attendanceNumber = profile.studentNumber
        self.nickname = profile.nickname
    }
}

enum TradeOfferStatus: String, Sendable {
    case open
    case matched
}

struct TradeOffer: Identifiable, Hashable, Sendable {
    let id: String
    let seller: StudentSummary
    let offering: TradeCondition
    let requesting: TradeCondition
    var status: TradeOfferStatus
}

struct TradeMatch: Identifiable, Hashable, Sendable {
    let id: String
    let myOffer: TradeOffer
    let partnerOffer: TradeOffer
    let matchedAt: Date
}
