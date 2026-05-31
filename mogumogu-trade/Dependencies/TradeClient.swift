import Dependencies
import FirebaseFirestore
import Foundation

struct TradeClient: Sendable {
    var observeOffers: @Sendable (_ classId: String, _ mealDate: String) -> AsyncThrowingStream<[TradeOffer], Error>
    var submitOffer: @Sendable (_ classId: String, _ mealDate: String, _ offer: TradeOffer) async throws -> TradeSubmitResult
    var cancelOffer: @Sendable (_ classId: String, _ mealDate: String, _ offerId: String, _ student: StudentSummary) async throws -> Void
}

enum TradeSubmitResult: Sendable {
    case queued(TradeOffer)
    case matched(TradeMatch)
}

enum TradeClientError: LocalizedError, Sendable {
    case conditionNotFound
    case offerNotFound
    case notCancelable
    case partnerUnavailable
    case allergyBlocked

    var errorDescription: String? {
        switch self {
        case .conditionNotFound:
            "出品の条件が見つかりません"
        case .offerNotFound:
            "出品が見つかりません"
        case .notCancelable:
            "この出品は取り消せません"
        case .partnerUnavailable:
            "相手の出品はもう使えません"
        case .allergyBlocked:
            "アレルギーのためトレードできません"
        }
    }
}

extension TradeClient: DependencyKey {
    static let liveValue: TradeClient = {
        @Dependency(\.allergyClient) var allergyClient
        return TradeClient(
            observeOffers: { classId, mealDate in
                FirestoreTradeService.observeOffers(classId: classId, mealDate: mealDate)
            },
            submitOffer: { classId, mealDate, offer in
                let roster = try await allergyClient.loadRoster(classId)
                return try await FirestoreTradeService.submitOffer(classId: classId, mealDate: mealDate, offer: offer, roster: roster)
            },
            cancelOffer: { classId, mealDate, offerId, student in
                try await FirestoreTradeService.cancelOffer(classId: classId, mealDate: mealDate, offerId: offerId, student: student)
            }
        )
    }()

    static let previewValue = TradeClient(
        observeOffers: { _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield([])
                continuation.finish()
            }
        },
        submitOffer: { _, _, offer in .queued(offer) },
        cancelOffer: { _, _, _, _ in }
    )
}

extension DependencyValues {
    var tradeClient: TradeClient {
        get { self[TradeClient.self] }
        set { self[TradeClient.self] = newValue }
    }
}

private enum FirestoreTradeService {
    private static let partnerUnavailableNSError = NSError(
        domain: "mogumogu-trade.TradeClient",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: TradeClientError.partnerUnavailable.localizedDescription]
    )

    static func observeOffers(classId: String, mealDate: String) -> AsyncThrowingStream<[TradeOffer], Error> {
        AsyncThrowingStream { continuation in
            let listener = tradesCollection(classId: classId)
                .whereField("mealDate", isEqualTo: mealDate)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }

                    let offers = snapshot?.documents.compactMap { document in
                        try? tradeDocument(from: document).offer
                    } ?? []
                    continuation.yield(offers)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    static func submitOffer(classId: String, mealDate: String, offer: TradeOffer, roster: [StudentAllergy]) async throws -> TradeSubmitResult {
        let myAllergens = roster.first(where: { $0.studentNumber == offer.seller.attendanceNumber })?.allergens ?? []
        guard AllergyChecker.isSafe(foodID: offer.requesting.id, recipientAllergens: myAllergens) else {
            throw TradeClientError.allergyBlocked
        }

        let openOffers = try await loadOpenOffers(classId: classId, mealDate: mealDate)
        guard let partner = openOffers.first(where: { canMatch(offer, with: $0.offer, roster: roster) }) else {
            return try await queueOffer(classId: classId, offer: offer)
        }

        let matchedAt = Date()
        let matchedOffer = TradeOffer(
            id: offer.id,
            mealDate: mealDate,
            seller: offer.seller,
            offering: offer.offering,
            requesting: offer.requesting,
            status: .matched,
            matchedOfferId: partner.offer.id,
            matchedAt: matchedAt
        )
        let matchedPartnerOffer = TradeOffer(
            id: partner.offer.id,
            mealDate: mealDate,
            seller: partner.offer.seller,
            offering: partner.offer.offering,
            requesting: partner.offer.requesting,
            status: .matched,
            matchedOfferId: offer.id,
            matchedAt: matchedAt
        )

        let firestore = Firestore.firestore()
        let myRef = tradesCollection(classId: classId).document(matchedOffer.id)
        let partnerRef = tradesCollection(classId: classId).document(matchedPartnerOffer.id)

        do {
            _ = try await firestore.runTransaction { transaction, errorPointer in
                do {
                    let partnerSnapshot = try transaction.getDocument(partnerRef)
                    let latestPartnerOffer = try tradeDocument(from: partnerSnapshot).offer
                    guard canMatch(matchedOffer, with: latestPartnerOffer, roster: roster) else {
                        errorPointer?.pointee = partnerUnavailableNSError
                        return nil
                    }

                    transaction.setData(
                        data(
                            for: matchedOffer,
                            status: .matched,
                            matchedOfferId: matchedPartnerOffer.id,
                            matchedAt: matchedAt
                        ),
                        forDocument: myRef
                    )
                    transaction.updateData(
                        [
                            "status": TradeOfferStatus.matched.rawValue,
                            "matchedOfferId": matchedOffer.id,
                            "matchedAt": Timestamp(date: matchedAt),
                            "updatedAt": FieldValue.serverTimestamp(),
                        ],
                        forDocument: partnerRef
                    )
                } catch let error as NSError {
                    errorPointer?.pointee = error
                }
                return nil
            }
        } catch let error as NSError where isPartnerUnavailable(error) {
            return try await queueOffer(classId: classId, offer: offer)
        }

        return .matched(TradeMatch(
            id: "\(matchedOffer.id)-\(matchedPartnerOffer.id)",
            myOffer: matchedOffer,
            partnerOffer: matchedPartnerOffer,
            matchedAt: matchedAt
        ))
    }

    static func cancelOffer(classId: String, mealDate: String, offerId: String, student: StudentSummary) async throws {
        let ref = tradesCollection(classId: classId).document(offerId)
        let snapshot = try await ref.getDocument()
        guard snapshot.exists else { throw TradeClientError.offerNotFound }

        let offer = try tradeDocument(from: snapshot).offer
        guard offer.mealDate == mealDate, offer.seller == student, offer.status == .open else {
            throw TradeClientError.notCancelable
        }

        try await ref.delete()
    }

    private static func queueOffer(classId: String, offer: TradeOffer) async throws -> TradeSubmitResult {
        let queuedOffer = TradeOffer(
            id: offer.id,
            mealDate: offer.mealDate,
            seller: offer.seller,
            offering: offer.offering,
            requesting: offer.requesting,
            status: .open
        )
        try await tradesCollection(classId: classId)
            .document(queuedOffer.id)
            .setData(data(for: queuedOffer, status: .open))
        return .queued(queuedOffer)
    }

    private static func isPartnerUnavailable(_ error: NSError) -> Bool {
        error.domain == partnerUnavailableNSError.domain && error.code == partnerUnavailableNSError.code
    }

    private static func loadOpenOffers(classId: String, mealDate: String) async throws -> [StoredTradeOffer] {
        let snapshot = try await tradesCollection(classId: classId)
            .whereField("mealDate", isEqualTo: mealDate)
            .whereField("status", isEqualTo: TradeOfferStatus.open.rawValue)
            .getDocuments()

        return try snapshot.documents
            .map(tradeDocument(from:))
            .sorted { $0.createdAt < $1.createdAt }
    }

    private static func tradesCollection(classId: String) -> CollectionReference {
        Firestore.firestore()
            .collection("classes")
            .document(classId)
            .collection("trades")
    }

    private static func canMatch(
        _ myOffer: TradeOffer,
        with partnerOffer: TradeOffer,
        roster: [StudentAllergy]
    ) -> Bool {
        guard partnerOffer.seller != myOffer.seller
            && partnerOffer.mealDate == myOffer.mealDate
            && myOffer.offering == partnerOffer.requesting
            && myOffer.requesting == partnerOffer.offering
            && partnerOffer.status == .open else {
            return false
        }

        let partnerAllergens = roster.first(where: { $0.studentNumber == partnerOffer.seller.attendanceNumber })?.allergens ?? []
        return AllergyChecker.isSafe(foodID: partnerOffer.requesting.id, recipientAllergens: partnerAllergens)
    }

    private static func tradeDocument(from document: DocumentSnapshot) throws -> StoredTradeOffer {
        guard let data = document.data() else { throw TradeClientError.offerNotFound }
        return try tradeDocument(id: document.documentID, data: data)
    }

    private static func tradeDocument(from document: QueryDocumentSnapshot) throws -> StoredTradeOffer {
        try tradeDocument(id: document.documentID, data: document.data())
    }

    private static func tradeDocument(id: String, data: [String: Any]) throws -> StoredTradeOffer {
        guard
            let sellerAttendanceNumber = data["sellerAttendanceNumber"] as? Int,
            let sellerNickname = data["sellerNickname"] as? String,
            let mealDate = data["mealDate"] as? String,
            let offeringId = data["offeringId"] as? String,
            let requestingId = data["requestingId"] as? String,
            let statusRawValue = data["status"] as? String,
            let offering = TradeCondition.find(id: offeringId),
            let requesting = TradeCondition.find(id: requestingId),
            let status = TradeOfferStatus(rawValue: statusRawValue)
        else {
            throw TradeClientError.conditionNotFound
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast
        let matchedOfferId = data["matchedOfferId"] as? String
        let matchedAt = (data["matchedAt"] as? Timestamp)?.dateValue()

        return StoredTradeOffer(
            offer: TradeOffer(
                id: id,
                mealDate: mealDate,
                seller: StudentSummary(attendanceNumber: sellerAttendanceNumber, nickname: sellerNickname),
                offering: offering,
                requesting: requesting,
                status: status,
                matchedOfferId: matchedOfferId,
                matchedAt: matchedAt
            ),
            createdAt: createdAt,
            matchedAt: matchedAt
        )
    }

    private static func data(
        for offer: TradeOffer,
        status: TradeOfferStatus,
        matchedOfferId: String? = nil,
        matchedAt: Date? = nil
    ) -> [String: Any] {
        var data: [String: Any] = [
            "mealDate": offer.mealDate,
            "sellerAttendanceNumber": offer.seller.attendanceNumber,
            "sellerNickname": offer.seller.nickname,
            "offeringId": offer.offering.id,
            "offeringCategory": offer.offering.category.rawValue,
            "offeringTitle": offer.offering.title,
            "requestingId": offer.requesting.id,
            "requestingCategory": offer.requesting.category.rawValue,
            "requestingTitle": offer.requesting.title,
            "status": status.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]

        if let matchedOfferId {
            data["matchedOfferId"] = matchedOfferId
        }
        if let matchedAt {
            data["matchedAt"] = Timestamp(date: matchedAt)
        }

        return data
    }
}

private struct StoredTradeOffer: Sendable {
    let offer: TradeOffer
    let createdAt: Date
    let matchedAt: Date?
}
