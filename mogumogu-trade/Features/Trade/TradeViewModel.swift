import Dependencies
import Foundation

/// 出品の結果バナー／演出の出し分けに使う種別。
enum TradeResultKind: Sendable {
    case matched   // トレード成立
    case queued    // まだ合う人がいない（出品リストに入った）
    case cancelled // 出品を取り消した
}

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
    private(set) var resultKind: TradeResultKind?
    private(set) var message: String?
    private(set) var errorMessage: String?
    private(set) var isLoading: Bool = false
    private(set) var isSubmitting: Bool = false
    private(set) var myAllergens: Set<Allergen> = []
    private var isObserving: Bool = false
    private var dismissedMatchIds: Set<String> = []

    @ObservationIgnored @Dependency(\.tradeClient) private var tradeClient
    @ObservationIgnored @Dependency(\.uuid) private var uuid
    @ObservationIgnored @Dependency(\.allergyClient) private var allergyClient

    init(
        profile: StudentProfile,
        mealDate: String? = nil,
        offers: [TradeOffer]? = nil
    ) {
        @Dependency(\.date.now) var now
        self.profile = profile
        self.mealDate = mealDate ?? MealDate.string(for: now)
        self.currentStudent = StudentSummary(profile: profile)
        self.offers = offers ?? []
    }

    var openOffers: [TradeOffer] {
        offers.filter { $0.status == .open }
    }

    var allergyBlockReason: String? {
        AllergyChecker.blockReason(foodID: selectedRequesting.id, recipientAllergens: myAllergens)
    }

    var canSubmit: Bool {
        selectedOffering != selectedRequesting && allergyBlockReason == nil
    }

    func observeOffers() async {
        guard !isObserving else { return }
        isObserving = true
        isLoading = offers.isEmpty
        
        if let roster = try? await allergyClient.loadRoster(profile.classId),
           let me = roster.first(where: { $0.studentNumber == currentStudent.attendanceNumber }) {
            myAllergens = me.allergens
        }

        defer {
            isObserving = false
            isLoading = false
        }

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
        guard canSubmit, !isSubmitting else { return }
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
                resultKind = .queued
                message = "まだ合う人がいないよ"
            case let .matched(newMatch):
                upsert(newMatch.myOffer)
                upsert(newMatch.partnerOffer)
                match = newMatch
                resultKind = .matched
                message = "トレード成立！"
            }
        } catch {
            match = nil
            resultKind = nil
            message = nil
            errorMessage = "出品できませんでした"
        }
    }

    func clearResult() {
        if let match {
            dismissedMatchIds.insert(match.id)
        }
        match = nil
        resultKind = nil
        message = nil
    }

    func cancelOffer(id: String) async {
        guard let offerIndex = offers.firstIndex(where: {
            $0.id == id
                && $0.seller == currentStudent
                && $0.status == .open
        }) else { return }

        do {
            try await tradeClient.cancelOffer(profile.classId, mealDate, id, currentStudent)
            offers.remove(at: offerIndex)
            match = nil
            resultKind = .cancelled
            message = "出品を取り消したよ"
            errorMessage = nil
        } catch {
            errorMessage = "取り消しできませんでした"
        }
    }

    func resetSampleData() {
        selectedOffering = .tomato
        selectedRequesting = .greenPepper
        offers = Self.sampleOffers
        match = nil
        resultKind = nil
        message = nil
        errorMessage = nil
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
                $0.seller == currentStudent
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
        resultKind = .matched
        message = "トレード成立！"
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

#if DEBUG
extension TradeViewModel {
    /// プレビュー用：成立済みの状態を直接シードする（`private(set)` は同一ファイル内なので設定可）。
    static func previewMatched() -> TradeViewModel {
        let vm = TradeViewModel(profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"))
        let mine = TradeOffer(
            id: "me",
            mealDate: vm.mealDate,
            seller: vm.currentStudent,
            offering: .tomato,
            requesting: .greenPepper,
            status: .matched,
            matchedOfferId: "partner",
            matchedAt: Date()
        )
        let partner = TradeOffer(
            id: "partner",
            mealDate: vm.mealDate,
            seller: StudentSummary(attendanceNumber: 8, nickname: "はる"),
            offering: .greenPepper,
            requesting: .tomato,
            status: .matched,
            matchedOfferId: "me",
            matchedAt: Date()
        )
        vm.offers = [mine, partner]
        vm.match = TradeMatch(id: "me-partner", myOffer: mine, partnerOffer: partner, matchedAt: Date())
        vm.resultKind = .matched
        vm.message = "トレード成立！"
        return vm
    }

    /// プレビュー用：出品はしたがまだ成立していない状態。
    static func previewQueued() -> TradeViewModel {
        let vm = TradeViewModel(profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"))
        vm.resultKind = .queued
        vm.message = "まだ合う人がいないよ"
        return vm
    }
}
#endif
