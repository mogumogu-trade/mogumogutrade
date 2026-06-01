import Dependencies
import FirebaseFirestore
import Foundation

struct AuctionClient: Sendable {
    static let participationFee = 5

    var observeLatestRoom: @Sendable (
        _ classId: String,
        _ mealDate: String
    ) -> AsyncThrowingStream<AuctionRoom?, Error>

    var observeMyBid: @Sendable (
        _ classId: String,
        _ roomId: String,
        _ studentNumber: Int
    ) -> AsyncThrowingStream<AuctionBid?, Error>

    var observeBids: @Sendable (
        _ classId: String,
        _ roomId: String
    ) -> AsyncThrowingStream<[AuctionBid], Error>

    var observeResult: @Sendable (
        _ classId: String,
        _ roomId: String
    ) -> AsyncThrowingStream<AuctionResult?, Error>

    var submitBid: @Sendable (
        _ classId: String,
        _ roomId: String,
        _ student: StudentSummary,
        _ amount: Int
    ) async throws -> AuctionBid

    var createRoom: @Sendable (
        _ classId: String,
        _ itemName: String,
        _ mealDate: String
    ) async throws -> AuctionRoom

    var closeRoom: @Sendable (
        _ classId: String,
        _ roomId: String
    ) async throws -> AuctionResult
}

enum AuctionClientError: LocalizedError, Sendable {
    case roomNotFound
    case roomClosed
    case activeRoomAlreadyExists
    case invalidBid
    case insufficientPoints
    case failed

    var errorDescription: String? {
        switch self {
        case .roomNotFound:
            "オークションが見つかりません"
        case .roomClosed:
            "このオークションはしめきり済みです"
        case .activeRoomAlreadyExists:
            "開催中のオークションがあります"
        case .invalidBid:
            "ベット額を見直してね"
        case .insufficientPoints:
            "ポイントが足りないよ"
        case .failed:
            "つうしんにしっぱいしました"
        }
    }
}

extension AuctionClient: DependencyKey {
    static let liveValue = AuctionClient(
        observeLatestRoom: { classId, mealDate in
            FirestoreAuctionService.observeLatestRoom(classId: classId, mealDate: mealDate)
        },
        observeMyBid: { classId, roomId, studentNumber in
            FirestoreAuctionService.observeMyBid(
                classId: classId,
                roomId: roomId,
                studentNumber: studentNumber
            )
        },
        observeBids: { classId, roomId in
            FirestoreAuctionService.observeBids(classId: classId, roomId: roomId)
        },
        observeResult: { classId, roomId in
            FirestoreAuctionService.observeResult(classId: classId, roomId: roomId)
        },
        submitBid: { classId, roomId, student, amount in
            try await FirestoreAuctionService.submitBid(
                classId: classId,
                roomId: roomId,
                student: student,
                amount: amount
            )
        },
        createRoom: { classId, itemName, mealDate in
            try await FirestoreAuctionService.createRoom(
                classId: classId,
                itemName: itemName,
                mealDate: mealDate
            )
        },
        closeRoom: { classId, roomId in
            try await FirestoreAuctionService.closeRoom(classId: classId, roomId: roomId)
        }
    )

    static let previewValue = AuctionClient(
        observeLatestRoom: { _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield(nil)
                continuation.finish()
            }
        },
        observeMyBid: { _, _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield(nil)
                continuation.finish()
            }
        },
        observeBids: { _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield([
                    AuctionBid(
                        id: "student-12",
                        student: StudentSummary(attendanceNumber: 12, nickname: "もぐ"),
                        amount: 8,
                        createdAt: Date(),
                        updatedAt: Date()
                    ),
                    AuctionBid(
                        id: "student-8",
                        student: StudentSummary(attendanceNumber: 8, nickname: "はる"),
                        amount: 6,
                        createdAt: Date().addingTimeInterval(30),
                        updatedAt: Date().addingTimeInterval(30)
                    ),
                ])
                continuation.finish()
            }
        },
        observeResult: { _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield(nil)
                continuation.finish()
            }
        },
        submitBid: { _, roomId, student, amount in
            AuctionBid(
                id: "student-\(student.attendanceNumber)",
                student: student,
                amount: amount,
                createdAt: Date(),
                updatedAt: Date()
            )
        },
        createRoom: { _, itemName, mealDate in
            await MainActor.run {
                AuctionRoom(
                    id: "preview-room",
                    itemName: itemName,
                    status: .open,
                    mealDate: mealDate,
                    createdAt: Date()
                )
            }
        },
        closeRoom: { _, roomId in
            AuctionResult(id: "main", roomId: roomId, winner: nil, closedAt: Date())
        }
    )
}

extension DependencyValues {
    var auctionClient: AuctionClient {
        get { self[AuctionClient.self] }
        set { self[AuctionClient.self] = newValue }
    }
}

private enum FirestoreAuctionService {
    private static let domain = "mogumogu-trade.AuctionClient"

    static func observeLatestRoom(
        classId: String,
        mealDate: String
    ) -> AsyncThrowingStream<AuctionRoom?, Error> {
        AsyncThrowingStream { continuation in
            let listener = auctionCollection(classId: classId)
                .whereField("mealDate", isEqualTo: mealDate)
                .order(by: "createdAt", descending: true)
                .limit(to: 1)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    let room = snapshot?.documents.first.flatMap {
                        try? roomDocument(id: $0.documentID, data: $0.data())
                    }
                    continuation.yield(room)
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    static func observeMyBid(
        classId: String,
        roomId: String,
        studentNumber: Int
    ) -> AsyncThrowingStream<AuctionBid?, Error> {
        AsyncThrowingStream { continuation in
            let listener = bidsCollection(classId: classId, roomId: roomId)
                .document(bidId(studentNumber: studentNumber))
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                        continuation.yield(nil)
                        return
                    }
                    continuation.yield(try? bidDocument(id: snapshot.documentID, data: data))
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    static func observeBids(
        classId: String,
        roomId: String
    ) -> AsyncThrowingStream<[AuctionBid], Error> {
        AsyncThrowingStream { continuation in
            let listener = bidsCollection(classId: classId, roomId: roomId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }

                    do {
                        let bids = try snapshot?.documents
                            .map { try bidDocument(id: $0.documentID, data: $0.data()) }
                            .sorted(by: bidPriority) ?? []
                        continuation.yield(bids)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    static func observeResult(classId: String, roomId: String) -> AsyncThrowingStream<AuctionResult?, Error> {
        AsyncThrowingStream { continuation in
            let listener = resultDocument(classId: classId, roomId: roomId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else {
                        continuation.yield(nil)
                        return
                    }
                    continuation.yield(try? result(from: snapshot))
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    static func submitBid(
        classId: String,
        roomId: String,
        student: StudentSummary,
        amount: Int
    ) async throws -> AuctionBid {
        guard amount > 0 else { throw AuctionClientError.invalidBid }

        let firestore = Firestore.firestore()
        try await FirestorePointBalanceStore.ensureBalance(
            classId: classId,
            studentNumber: student.attendanceNumber,
            firestore: firestore
        )

        let roomRef = auctionCollection(classId: classId).document(roomId)
        let bidRef = bidsCollection(classId: classId, roomId: roomId)
            .document(bidId(studentNumber: student.attendanceNumber))
        let feeLedgerRef = FirestorePointBalanceStore
            .ledgerCollection(classId: classId, firestore: firestore)
            .document("auction-fee-\(roomId)-\(student.attendanceNumber)")
        let balanceRef = FirestorePointBalanceStore.pointBalanceDocument(
            classId: classId,
            studentNumber: student.attendanceNumber,
            firestore: firestore
        )

        do {
            _ = try await firestore.runTransaction { transaction, errorPointer in
                do {
                    let roomSnapshot = try transaction.getDocument(roomRef)
                    let room = try room(from: roomSnapshot)
                    guard room.status == .open else {
                        errorPointer?.pointee = nsError(.roomClosed)
                        return nil
                    }

                    let bidSnapshot = try transaction.getDocument(bidRef)
                    let balanceSnapshot = try transaction.getDocument(balanceRef)
                    let feeLedgerSnapshot = try transaction.getDocument(feeLedgerRef)
                    let isFirstBid = !bidSnapshot.exists && !feeLedgerSnapshot.exists
                    let balance = FirestorePointBalanceStore.balance(from: balanceSnapshot)
                    let requiredPoints = isFirstBid ? amount + AuctionClient.participationFee : amount

                    guard balance >= requiredPoints else {
                        errorPointer?.pointee = nsError(.insufficientPoints)
                        return nil
                    }

                    if isFirstBid {
                        transaction.setData(
                            participationLedgerData(
                                roomId: roomId,
                                room: room,
                                student: student
                            ),
                            forDocument: feeLedgerRef
                        )
                        FirestorePointBalanceStore.setBalance(
                            balance - AuctionClient.participationFee,
                            studentNumber: student.attendanceNumber,
                            transaction: transaction,
                            ref: balanceRef
                        )
                    }

                    if bidSnapshot.exists {
                        transaction.updateData(
                            [
                                "studentNickname": student.nickname,
                                "amount": amount,
                                "updatedAt": FieldValue.serverTimestamp(),
                            ],
                            forDocument: bidRef
                        )
                    } else {
                        transaction.setData(
                            bidData(student: student, amount: amount),
                            forDocument: bidRef
                        )
                    }
                } catch let error as NSError {
                    errorPointer?.pointee = error
                }
                return nil
            }
        } catch {
            throw clientError(from: error)
        }

        let snapshot = try await bidRef.getDocument()
        guard let data = snapshot.data() else { throw AuctionClientError.failed }
        return try bidDocument(id: snapshot.documentID, data: data)
    }

    static func createRoom(classId: String, itemName: String, mealDate: String) async throws -> AuctionRoom {
        let firestore = Firestore.firestore()
        let ref = auctionCollection(classId: classId).document()
        let activeRef = activeRoomDocument(classId: classId, mealDate: mealDate)
        let createdRoom = AuctionRoom(
            id: ref.documentID,
            itemName: itemName,
            status: .open,
            mealDate: mealDate,
            createdAt: Date()
        )

        do {
            _ = try await firestore.runTransaction { transaction, errorPointer in
                do {
                    let activeSnapshot = try transaction.getDocument(activeRef)
                    if
                        let activeRoomId = activeSnapshot.data()?["roomId"] as? String,
                        activeSnapshot.data()?["status"] as? String == AuctionRoomStatus.open.rawValue
                    {
                        let activeRoomSnapshot = try transaction.getDocument(
                            auctionCollection(classId: classId).document(activeRoomId)
                        )
                        if
                            let activeRoom = try? room(from: activeRoomSnapshot),
                            activeRoom.status == .open
                        {
                            errorPointer?.pointee = nsError(.activeRoomAlreadyExists)
                            return nil
                        }
                    }

                    transaction.setData(
                        roomData(itemName: itemName, status: .open, mealDate: mealDate),
                        forDocument: ref
                    )
                    transaction.setData(
                        activeRoomData(roomId: ref.documentID, mealDate: mealDate, status: .open),
                        forDocument: activeRef,
                        merge: true
                    )
                } catch let error as NSError {
                    errorPointer?.pointee = error
                }
                return nil
            }
        } catch {
            throw clientError(from: error)
        }

        return createdRoom
    }

    static func closeRoom(classId: String, roomId: String) async throws -> AuctionResult {
        if let existing = try await loadResult(classId: classId, roomId: roomId) {
            return existing
        }

        let firestore = Firestore.firestore()
        let closedAt = Date()
        let roomRef = auctionCollection(classId: classId).document(roomId)

        do {
            _ = try await firestore.runTransaction { transaction, errorPointer in
                do {
                    let roomSnapshot = try transaction.getDocument(roomRef)
                    let auctionRoom = try room(from: roomSnapshot)
                    let activeRef = activeRoomDocument(
                        classId: classId,
                        mealDate: auctionRoom.mealDate
                    )
                    let activeSnapshot = try transaction.getDocument(activeRef)
                    if auctionRoom.status == .open {
                        transaction.updateData(
                            [
                                "status": AuctionRoomStatus.closed.rawValue,
                                "closedAt": Timestamp(date: closedAt),
                                "updatedAt": FieldValue.serverTimestamp(),
                            ],
                            forDocument: roomRef
                        )
                    }
                    if activeSnapshot.data()?["roomId"] as? String == roomId {
                        transaction.setData(
                            activeRoomData(
                                roomId: roomId,
                                mealDate: auctionRoom.mealDate,
                                status: .closed,
                                closedAt: closedAt
                            ),
                            forDocument: activeRef,
                            merge: true
                        )
                    }
                } catch let error as NSError {
                    errorPointer?.pointee = error
                }
                return nil
            }
        } catch {
            throw clientError(from: error)
        }

        let closedRoom = try await room(from: roomRef.getDocument())
        let bids = try await loadBids(classId: classId, roomId: roomId)
        for bid in bids {
            try await FirestorePointBalanceStore.ensureBalance(
                classId: classId,
                studentNumber: bid.student.attendanceNumber,
                firestore: firestore
            )
        }

        let resultRef = resultDocument(classId: classId, roomId: roomId)
        let ledgerCollection = FirestorePointBalanceStore.ledgerCollection(
            classId: classId,
            firestore: firestore
        )

        do {
            _ = try await firestore.runTransaction { transaction, errorPointer in
                do {
                    let resultSnapshot = try transaction.getDocument(resultRef)
                    if resultSnapshot.exists {
                        return true
                    }

                    var selectedBid: AuctionBid?
                    var selectedBalance = 0

                    for bid in bids {
                        let balanceRef = FirestorePointBalanceStore.pointBalanceDocument(
                            classId: classId,
                            studentNumber: bid.student.attendanceNumber,
                            firestore: firestore
                        )
                        let balanceSnapshot = try transaction.getDocument(balanceRef)
                        let balance = FirestorePointBalanceStore.balance(from: balanceSnapshot)
                        if selectedBid == nil, balance >= bid.amount {
                            selectedBid = bid
                            selectedBalance = balance
                        }
                    }

                    var winLedgerSnapshot: DocumentSnapshot?
                    var winnerBalanceRef: DocumentReference?
                    if let selectedBid {
                        let winLedgerRef = ledgerCollection.document(
                            "auction-win-\(roomId)-\(selectedBid.student.attendanceNumber)"
                        )
                        winLedgerSnapshot = try transaction.getDocument(winLedgerRef)
                        winnerBalanceRef = FirestorePointBalanceStore.pointBalanceDocument(
                            classId: classId,
                            studentNumber: selectedBid.student.attendanceNumber,
                            firestore: firestore
                        )
                    }

                    transaction.setData(
                        resultData(roomId: roomId, winner: selectedBid, closedAt: closedAt),
                        forDocument: resultRef
                    )

                    if
                        let selectedBid,
                        let winnerBalanceRef,
                        winLedgerSnapshot?.exists != true
                    {
                        let winLedgerRef = ledgerCollection.document(
                            "auction-win-\(roomId)-\(selectedBid.student.attendanceNumber)"
                        )
                        transaction.setData(
                            winLedgerData(room: closedRoom, bid: selectedBid),
                            forDocument: winLedgerRef
                        )
                        FirestorePointBalanceStore.setBalance(
                            selectedBalance - selectedBid.amount,
                            studentNumber: selectedBid.student.attendanceNumber,
                            transaction: transaction,
                            ref: winnerBalanceRef
                        )
                    }
                } catch let error as NSError {
                    errorPointer?.pointee = error
                }
                return nil
            }
        } catch {
            throw clientError(from: error)
        }

        guard let result = try await loadResult(classId: classId, roomId: roomId) else {
            throw AuctionClientError.failed
        }
        return result
    }

    private static func loadResult(classId: String, roomId: String) async throws -> AuctionResult? {
        try await result(from: resultDocument(classId: classId, roomId: roomId).getDocument())
    }

    private static func loadBids(classId: String, roomId: String) async throws -> [AuctionBid] {
        let snapshot = try await bidsCollection(classId: classId, roomId: roomId).getDocuments()
        return try snapshot.documents
            .map { try bidDocument(id: $0.documentID, data: $0.data()) }
            .sorted(by: bidPriority)
    }

    private static func bidPriority(_ lhs: AuctionBid, _ rhs: AuctionBid) -> Bool {
        if lhs.amount == rhs.amount {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.amount > rhs.amount
    }

    private static func auctionCollection(classId: String) -> CollectionReference {
        Firestore.firestore()
            .collection("classes")
            .document(classId)
            .collection("auctions")
    }

    private static func activeRoomDocument(classId: String, mealDate: String) -> DocumentReference {
        Firestore.firestore()
            .collection("classes")
            .document(classId)
            .collection("auctionActiveRooms")
            .document(mealDate)
    }

    private static func bidsCollection(classId: String, roomId: String) -> CollectionReference {
        auctionCollection(classId: classId)
            .document(roomId)
            .collection("bids")
    }

    private static func resultDocument(classId: String, roomId: String) -> DocumentReference {
        auctionCollection(classId: classId)
            .document(roomId)
            .collection("result")
            .document("main")
    }

    private static func bidId(studentNumber: Int) -> String {
        "student-\(studentNumber)"
    }

    private static func room(from snapshot: DocumentSnapshot) throws -> AuctionRoom {
        guard snapshot.exists, let data = snapshot.data() else {
            throw AuctionClientError.roomNotFound
        }
        return try roomDocument(id: snapshot.documentID, data: data)
    }

    private static func roomDocument(id: String, data: [String: Any]) throws -> AuctionRoom {
        guard
            let itemName = data["itemName"] as? String,
            let statusRawValue = data["status"] as? String,
            let status = AuctionRoomStatus(rawValue: statusRawValue),
            let mealDate = data["mealDate"] as? String
        else {
            throw AuctionClientError.failed
        }

        return AuctionRoom(
            id: id,
            itemName: itemName,
            status: status,
            mealDate: mealDate,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantPast,
            closedAt: (data["closedAt"] as? Timestamp)?.dateValue()
        )
    }

    private static func bidDocument(id: String, data: [String: Any]) throws -> AuctionBid {
        guard
            let studentNumber = data["studentNumber"] as? Int,
            let studentNickname = data["studentNickname"] as? String,
            let amount = data["amount"] as? Int
        else {
            throw AuctionClientError.failed
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .distantFuture
        return AuctionBid(
            id: id,
            student: StudentSummary(attendanceNumber: studentNumber, nickname: studentNickname),
            amount: amount,
            createdAt: createdAt,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt
        )
    }

    private static func result(from snapshot: DocumentSnapshot) throws -> AuctionResult? {
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        guard
            let roomId = data["roomId"] as? String,
            let closedAt = (data["closedAt"] as? Timestamp)?.dateValue()
        else {
            throw AuctionClientError.failed
        }

        var winner: AuctionWinner?
        if let winnerData = data["winner"] as? [String: Any] {
            guard
                let studentNumber = winnerData["studentNumber"] as? Int,
                let studentNickname = winnerData["studentNickname"] as? String,
                let bidAmount = winnerData["bidAmount"] as? Int
            else {
                throw AuctionClientError.failed
            }
            winner = AuctionWinner(
                student: StudentSummary(attendanceNumber: studentNumber, nickname: studentNickname),
                bidAmount: bidAmount
            )
        }

        return AuctionResult(
            id: snapshot.documentID,
            roomId: roomId,
            winner: winner,
            closedAt: closedAt
        )
    }

    private static func bidData(student: StudentSummary, amount: Int) -> [String: Any] {
        [
            "studentNumber": student.attendanceNumber,
            "studentNickname": student.nickname,
            "amount": amount,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
    }

    private static func roomData(
        itemName: String,
        status: AuctionRoomStatus,
        mealDate: String
    ) -> [String: Any] {
        [
            "itemName": itemName,
            "status": status.rawValue,
            "mealDate": mealDate,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
    }

    private static func activeRoomData(
        roomId: String,
        mealDate: String,
        status: AuctionRoomStatus,
        closedAt: Date? = nil
    ) -> [String: Any] {
        var data: [String: Any] = [
            "roomId": roomId,
            "status": status.rawValue,
            "mealDate": mealDate,
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let closedAt {
            data["closedAt"] = Timestamp(date: closedAt)
        }
        return data
    }

    private static func participationLedgerData(
        roomId: String,
        room: AuctionRoom,
        student: StudentSummary
    ) -> [String: Any] {
        [
            "studentNumber": student.attendanceNumber,
            "studentNickname": student.nickname,
            "amount": -AuctionClient.participationFee,
            "type": PointEntryType.auctionParticipation.rawValue,
            "mealDate": room.mealDate,
            "auctionId": roomId,
            "auctionItemName": room.itemName,
            "createdAt": FieldValue.serverTimestamp(),
        ]
    }

    private static func winLedgerData(room: AuctionRoom, bid: AuctionBid) -> [String: Any] {
        [
            "studentNumber": bid.student.attendanceNumber,
            "studentNickname": bid.student.nickname,
            "amount": -bid.amount,
            "type": PointEntryType.auctionWin.rawValue,
            "mealDate": room.mealDate,
            "auctionId": room.id,
            "auctionItemName": room.itemName,
            "createdAt": FieldValue.serverTimestamp(),
        ]
    }

    private static func resultData(
        roomId: String,
        winner: AuctionBid?,
        closedAt: Date
    ) -> [String: Any] {
        var data: [String: Any] = [
            "roomId": roomId,
            "closedAt": Timestamp(date: closedAt),
            "createdAt": FieldValue.serverTimestamp(),
        ]

        if let winner {
            data["winner"] = [
                "studentNumber": winner.student.attendanceNumber,
                "studentNickname": winner.student.nickname,
                "bidAmount": winner.amount,
            ]
        }

        return data
    }

    private static func nsError(_ error: AuctionClientError) -> NSError {
        NSError(
            domain: domain,
            code: code(for: error),
            userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
        )
    }

    private static func clientError(from error: Error) -> Error {
        guard let nsError = error as NSError?, nsError.domain == domain else {
            return error
        }
        switch nsError.code {
        case code(for: .roomNotFound):
            return AuctionClientError.roomNotFound
        case code(for: .roomClosed):
            return AuctionClientError.roomClosed
        case code(for: .activeRoomAlreadyExists):
            return AuctionClientError.activeRoomAlreadyExists
        case code(for: .invalidBid):
            return AuctionClientError.invalidBid
        case code(for: .insufficientPoints):
            return AuctionClientError.insufficientPoints
        default:
            return AuctionClientError.failed
        }
    }

    private static func code(for error: AuctionClientError) -> Int {
        switch error {
        case .roomNotFound:
            1
        case .roomClosed:
            2
        case .activeRoomAlreadyExists:
            3
        case .invalidBid:
            4
        case .insufficientPoints:
            5
        case .failed:
            6
        }
    }
}
