import Foundation

enum AuctionRoomStatus: String, Codable, Sendable {
    case open
    case closed
}

struct AuctionRoom: Identifiable, Hashable, Sendable {
    let id: String
    let itemName: String
    let stockCount: Int
    let status: AuctionRoomStatus
    let mealDate: String
    let createdAt: Date
    let closedAt: Date?

    init(
        id: String,
        itemName: String,
        stockCount: Int = 1,
        status: AuctionRoomStatus = .open,
        mealDate: String = "",
        createdAt: Date = .distantPast,
        closedAt: Date? = nil
    ) {
        self.id = id
        self.itemName = itemName
        self.stockCount = 1
        self.status = status
        self.mealDate = mealDate
        self.createdAt = createdAt
        self.closedAt = closedAt
    }
}

struct AuctionBid: Identifiable, Hashable, Sendable {
    let id: String
    let student: StudentSummary
    let amount: Int
    let createdAt: Date
    let updatedAt: Date
}

struct AuctionWinner: Hashable, Sendable {
    let student: StudentSummary
    let bidAmount: Int
}

struct AuctionResult: Identifiable, Hashable, Sendable {
    let id: String
    let roomId: String
    let winner: AuctionWinner?
    let closedAt: Date
}
