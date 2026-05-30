import Foundation

struct AuctionRoom: Identifiable, Hashable, Sendable {
    let id: String
    let itemName: String
    let stockCount: Int
}

@Observable
@MainActor
final class AuctionViewModel {
    let profile: StudentProfile
    var activeRoom: AuctionRoom?
    var pointBalance: Int

    init(
        profile: StudentProfile,
        activeRoom: AuctionRoom? = nil,
        pointBalance: Int = 0
    ) {
        self.profile = profile
        self.activeRoom = activeRoom
        self.pointBalance = pointBalance
    }
}
