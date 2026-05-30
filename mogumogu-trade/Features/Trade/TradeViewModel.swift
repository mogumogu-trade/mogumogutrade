import Foundation

@Observable
@MainActor
final class TradeViewModel {
    let profile: StudentProfile
    let currentStudent: StudentSummary

    var selectedOffering: TradeCondition = .tomato
    var selectedRequesting: TradeCondition = .greenPepper
    private(set) var offers: [TradeOffer]
    private(set) var match: TradeMatch?
    private(set) var message: String?

    init(
        profile: StudentProfile,
        offers: [TradeOffer]? = nil
    ) {
        self.profile = profile
        self.currentStudent = StudentSummary(profile: profile)
        self.offers = offers ?? Self.sampleOffers
    }

    var openOffers: [TradeOffer] {
        offers.filter { $0.status == .open }
    }

    var canSubmit: Bool {
        selectedOffering != selectedRequesting
    }

    func submitOffer() {
        guard canSubmit else { return }

        let myOffer = TradeOffer(
            id: UUID().uuidString,
            seller: currentStudent,
            offering: selectedOffering,
            requesting: selectedRequesting,
            status: .open
        )

        guard let partnerOffer = openOffers.first(where: { canMatch(myOffer, with: $0) }) else {
            offers.insert(myOffer, at: 0)
            match = nil
            message = "まだ合う人がいないよ"
            return
        }

        let matchedOffer = TradeOffer(
            id: myOffer.id,
            seller: myOffer.seller,
            offering: myOffer.offering,
            requesting: myOffer.requesting,
            status: .matched
        )

        if let partnerIndex = offers.firstIndex(where: { $0.id == partnerOffer.id }) {
            offers[partnerIndex].status = .matched
        }

        offers.insert(matchedOffer, at: 0)
        match = TradeMatch(
            id: "\(matchedOffer.id)-\(partnerOffer.id)",
            myOffer: matchedOffer,
            partnerOffer: partnerOffer,
            matchedAt: Date()
        )
        message = "トレード成立！"
    }

    func clearResult() {
        match = nil
        message = nil
    }

    func resetSampleData() {
        selectedOffering = .tomato
        selectedRequesting = .greenPepper
        offers = Self.sampleOffers
        match = nil
        message = nil
    }

    private func canMatch(_ myOffer: TradeOffer, with partnerOffer: TradeOffer) -> Bool {
        partnerOffer.seller != currentStudent
            && myOffer.offering == partnerOffer.requesting
            && myOffer.requesting == partnerOffer.offering
    }
}

extension TradeViewModel {
    static let sampleOffers: [TradeOffer] = [
        TradeOffer(
            id: "sample-8",
            seller: StudentSummary(attendanceNumber: 8, nickname: "はる"),
            offering: .greenPepper,
            requesting: .tomato,
            status: .open
        ),
        TradeOffer(
            id: "sample-3",
            seller: StudentSummary(attendanceNumber: 3, nickname: "りん"),
            offering: .sticker,
            requesting: .serving,
            status: .open
        ),
        TradeOffer(
            id: "sample-18",
            seller: StudentSummary(attendanceNumber: 18, nickname: "そら"),
            offering: .milk,
            requesting: .card,
            status: .open
        ),
    ]
}
