import Dependencies
import Foundation

@Observable
@MainActor
final class TradeViewModel {
    let profile: StudentProfile
    let mealDate: String
    let currentStudent: StudentSummary

    var selectedOffering: TradeCondition = .tomato
    var selectedRequesting: TradeCondition = .greenPepper
    private(set) var offers: [TradeOffer]
    private(set) var match: TradeMatch?
    private(set) var message: String?
    private(set) var errorMessage: String?
    private(set) var isLoading: Bool = false
    private(set) var isSubmitting: Bool = false
    private(set) var acceptingOfferId: String?
    private(set) var allergyRoster: [StudentAllergy] = []
    private var isObserving: Bool = false
    private var didLoadAllergies: Bool = false
    private var dismissedMatchIds: Set<String> = []

    @ObservationIgnored @Dependency(\.tradeClient) private var tradeClient
    @ObservationIgnored @Dependency(\.allergyClient) private var allergyClient
    @ObservationIgnored @Dependency(\.uuid) private var uuid

    init(
        profile: StudentProfile,
        mealDate: String? = nil,
        offers: [TradeOffer]? = nil,
        match: TradeMatch? = nil,
        message: String? = nil
    ) {
        @Dependency(\.date.now) var now
        self.profile = profile
        self.mealDate = mealDate ?? Self.mealDateString(for: now)
        self.currentStudent = StudentSummary(profile: profile)
        self.offers = offers ?? []
        self.match = match
        self.message = message
    }

    var openOffers: [TradeOffer] {
        offers.filter { $0.status == .open }
    }

    var canSubmit: Bool {
        submitBlockReason == nil
    }

    var submitBlockReason: String? {
        if selectedOffering == selectedRequesting {
            return "同じものどうしは選べないよ"
        }
        return blockReason(forReceiving: selectedRequesting, recipient: currentStudent)
    }

    func observeOffers() async {
        guard !isObserving else { return }
        isObserving = true
        isLoading = offers.isEmpty
        defer {
            isObserving = false
            isLoading = false
        }

        _ = await loadAllergiesIfNeeded()

        do {
            for try await latestOffers in tradeClient.observeOffers(profile.classId, mealDate) {
                offers = latestOffers
                syncMatchedOffer(from: latestOffers)
                isLoading = false
                errorMessage = nil
            }
        } catch {
            isLoading = false
            errorMessage = "出品を読みこめませんでした"
        }
    }

    func submitOffer() async {
        guard !isSubmitting else { return }
        guard await loadAllergiesIfNeeded() else { return }
        guard canSubmit else {
            errorMessage = submitBlockReason
            return
        }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let myOffer = TradeOffer(
            id: uuid().uuidString,
            mealDate: mealDate,
            seller: currentStudent,
            offering: selectedOffering,
            requesting: selectedRequesting,
            status: .open
        )

        do {
            switch try await tradeClient.submitOffer(profile.classId, mealDate, myOffer) {
            case let .queued(offer):
                upsert(offer)
                match = nil
                message = "出品したよ"
            case let .matched(newMatch):
                upsert(newMatch.myOffer)
                upsert(newMatch.partnerOffer)
                match = newMatch
                message = "トレード成立！"
            }
        } catch {
            match = nil
            message = nil
            errorMessage = "出品できませんでした"
        }
    }

    func acceptOffer(id: String) async {
        guard
            acceptingOfferId == nil,
            let offer = offers.first(where: {
                $0.id == id
                    && !isOwnOffer($0)
                    && $0.status == .open
            })
        else { return }

        guard await loadAllergiesIfNeeded() else { return }
        if let blockReason = acceptBlockReason(for: offer) {
            errorMessage = blockReason
            return
        }

        acceptingOfferId = id
        errorMessage = nil
        defer { acceptingOfferId = nil }

        do {
            let newMatch = try await tradeClient.acceptOffer(
                profile.classId,
                mealDate,
                offer.id,
                currentStudent,
                uuid().uuidString
            )
            upsert(newMatch.myOffer)
            upsert(newMatch.partnerOffer)
            match = newMatch
            message = "トレード成立！"
        } catch TradeClientError.partnerUnavailable {
            errorMessage = "もう成立したよ"
        } catch {
            errorMessage = "交換できませんでした"
        }
    }

    func clearResult() {
        if let match {
            dismissedMatchIds.insert(match.id)
        }
        match = nil
        message = nil
    }

    func cancelOffer(id: String) async {
        guard let offerIndex = offers.firstIndex(where: {
            $0.id == id
                && isOwnOffer($0)
                && $0.status == .open
        }) else { return }

        do {
            try await tradeClient.cancelOffer(profile.classId, mealDate, id, currentStudent)
            offers.remove(at: offerIndex)
            match = nil
            message = "出品を取り消したよ"
            errorMessage = nil
        } catch {
            errorMessage = "取り消しできませんでした"
        }
    }

    func canAccept(_ offer: TradeOffer) -> Bool {
        !isOwnOffer(offer)
            && offer.status == .open
            && acceptingOfferId == nil
            && acceptBlockReason(for: offer) == nil
    }

    func isOwnOffer(_ offer: TradeOffer) -> Bool {
        offer.seller.attendanceNumber == currentStudent.attendanceNumber
    }

    func acceptBlockReason(for offer: TradeOffer) -> String? {
        if let reason = blockReason(forReceiving: offer.offering, recipient: currentStudent) {
            return reason
        }
        if let reason = blockReason(forReceiving: offer.requesting, recipient: offer.seller) {
            return reason
        }
        return nil
    }

    func resetSampleData() {
        selectedOffering = .tomato
        selectedRequesting = .greenPepper
        offers = Self.sampleOffers
        match = nil
        message = nil
        errorMessage = nil
    }

    private func loadAllergiesIfNeeded() async -> Bool {
        guard !didLoadAllergies else { return true }
        do {
            allergyRoster = try await allergyClient.loadRoster(profile.classId)
            didLoadAllergies = true
            return true
        } catch {
            errorMessage = "アレルギー情報を読みこめませんでした"
            return false
        }
    }

    private func upsert(_ offer: TradeOffer) {
        if let index = offers.firstIndex(where: { $0.id == offer.id }) {
            offers[index] = offer
        } else {
            offers.insert(offer, at: 0)
        }
    }

    private func syncMatchedOffer(from latestOffers: [TradeOffer]) {
        let myMatchedOffers = latestOffers
            .filter {
                $0.seller.attendanceNumber == currentStudent.attendanceNumber
                    && $0.mealDate == mealDate
                    && $0.status == .matched
                    && $0.matchedOfferId != nil
            }
            .sorted {
                ($0.matchedAt ?? .distantPast) > ($1.matchedAt ?? .distantPast)
            }

        guard
            let myOffer = myMatchedOffers.first,
            let partnerOfferId = myOffer.matchedOfferId,
            let partnerOffer = latestOffers.first(where: { $0.id == partnerOfferId })
        else { return }

        let matchedAt = myOffer.matchedAt ?? partnerOffer.matchedAt ?? Date()
        let latestMatch = TradeMatch(
            id: "\(myOffer.id)-\(partnerOffer.id)",
            myOffer: myOffer,
            partnerOffer: partnerOffer,
            matchedAt: matchedAt
        )

        guard match?.id != latestMatch.id, !dismissedMatchIds.contains(latestMatch.id) else {
            return
        }

        match = latestMatch
        message = "トレード成立！"
    }

    private func blockReason(forReceiving condition: TradeCondition, recipient: StudentSummary) -> String? {
        guard condition.category == .food else { return nil }
        return AllergyChecker.blockReason(
            foodID: condition.id,
            recipientAllergens: allergens(for: recipient)
        )
    }

    private func allergens(for student: StudentSummary) -> Set<Allergen> {
        allergyRoster.first(where: {
            $0.studentNumber == student.attendanceNumber
        })?.allergens ?? []
    }

    private static func mealDateString(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}

extension TradeViewModel {
    static let sampleOffers: [TradeOffer] = [
        TradeOffer(
            id: "sample-8",
            mealDate: "2026-05-30",
            seller: StudentSummary(attendanceNumber: 8, nickname: "はる"),
            offering: .greenPepper,
            requesting: .tomato,
            status: .open
        ),
        TradeOffer(
            id: "sample-3",
            mealDate: "2026-05-30",
            seller: StudentSummary(attendanceNumber: 3, nickname: "りん"),
            offering: .sticker,
            requesting: .serving,
            status: .open
        ),
        TradeOffer(
            id: "sample-18",
            mealDate: "2026-05-30",
            seller: StudentSummary(attendanceNumber: 18, nickname: "そら"),
            offering: .milk,
            requesting: .card,
            status: .open
        ),
    ]
}
