import Dependencies
import FirebaseFirestore
import Foundation

/// 完食マイレージのポイント台帳を扱う Client。
///
/// AGENTS.md 方針に従い、残高は直接上書きせず履歴（`classes/{classId}/pointLedger`）の
/// 合計として扱う。完食ポイントは「完食者が表示したQRを確認者が読み取って加点する」
/// フローで付与され、書き込み主体は確認者になる。
struct MileageClient: Sendable {
    /// 完食ポイントを付与する（確認者の端末から実行）。
    ///
    /// 決定論ドキュメントID `meal-{mealDate}-{eater}` ＋トランザクションにより、
    /// 「1日1回」と「通信リトライ時の重複付与防止」を同時に満たす。
    var awardMealCompletion: @Sendable (
        _ classId: String,
        _ eater: StudentSummary,
        _ approver: StudentSummary,
        _ mealDate: String,
        _ now: Date
    ) async throws -> MileageAwardResult

    /// 指定生徒の残高（台帳の合計）をリアルタイム購読する。
    var observeBalance: @Sendable (
        _ classId: String,
        _ studentNumber: Int
    ) -> AsyncThrowingStream<Int, Error>
}

enum MileageAwardResult: Sendable, Equatable {
    /// 付与成功。付与後の残高（概算）。
    case awarded(balance: Int)
    /// 今日はすでに完食ポイント付与済み（または重複読み取り）。
    case alreadyAwardedToday
}

enum MileageClientError: LocalizedError, Sendable {
    case selfApproval
    case expired
    case differentClass
    case failed

    var errorDescription: String? {
        switch self {
        case .selfApproval:
            "じぶんのQRは よみとれないよ"
        case .expired:
            "このQRは じかんぎれだよ"
        case .differentClass:
            "ちがうクラスのQRだよ"
        case .failed:
            "つうしんに しっぱいしたよ"
        }
    }
}

extension MileageClient: DependencyKey {
    static let liveValue = MileageClient(
        awardMealCompletion: { classId, eater, approver, mealDate, _ in
            try await FirestoreMileageService.awardMealCompletion(
                classId: classId,
                eater: eater,
                approver: approver,
                mealDate: mealDate
            )
        },
        observeBalance: { classId, studentNumber in
            FirestoreMileageService.observeBalance(classId: classId, studentNumber: studentNumber)
        }
    )

    static let previewValue = MileageClient(
        awardMealCompletion: { _, _, _, _, _ in .awarded(balance: 1) },
        observeBalance: { _, _ in
            AsyncThrowingStream { continuation in
                continuation.yield(0)
                continuation.finish()
            }
        }
    )
}

extension DependencyValues {
    var mileageClient: MileageClient {
        get { self[MileageClient.self] }
        set { self[MileageClient.self] = newValue }
    }
}

private enum FirestoreMileageService {
    static func awardMealCompletion(
        classId: String,
        eater: StudentSummary,
        approver: StudentSummary,
        mealDate: String
    ) async throws -> MileageAwardResult {
        let firestore = Firestore.firestore()
        try await FirestorePointBalanceStore.ensureBalance(
            classId: classId,
            studentNumber: eater.attendanceNumber,
            firestore: firestore
        )

        let ref = ledgerCollection(classId: classId, firestore: firestore)
            .document("meal-\(mealDate)-\(eater.attendanceNumber)")
        let balanceRef = FirestorePointBalanceStore.pointBalanceDocument(
            classId: classId,
            studentNumber: eater.attendanceNumber,
            firestore: firestore
        )

        let result: Any?
        do {
            // トランザクション内で「既存なら何もしない／無ければ +1P 追記」。
            // 戻り値の Bool で「すでに付与済みだったか」を外へ渡す（外側可変変数の捕捉を避ける）。
            result = try await firestore.runTransaction { transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(ref)
                    let balanceSnapshot = try transaction.getDocument(balanceRef)
                    if snapshot.exists {
                        return true
                    }
                    transaction.setData(
                        entryData(eater: eater, approver: approver, mealDate: mealDate),
                        forDocument: ref
                    )
                    FirestorePointBalanceStore.setBalance(
                        FirestorePointBalanceStore.balance(from: balanceSnapshot) + 1,
                        studentNumber: eater.attendanceNumber,
                        transaction: transaction,
                        ref: balanceRef
                    )
                    return false
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
            }
        } catch {
            throw MileageClientError.failed
        }

        if (result as? Bool) == true {
            return .alreadyAwardedToday
        }

        let balance = try await currentBalance(
            classId: classId,
            studentNumber: eater.attendanceNumber,
            firestore: firestore
        )
        return .awarded(balance: balance)
    }

    static func observeBalance(classId: String, studentNumber: Int) -> AsyncThrowingStream<Int, Error> {
        AsyncThrowingStream { continuation in
            let listener = ledgerCollection(classId: classId, firestore: Firestore.firestore())
                .whereField("studentNumber", isEqualTo: studentNumber)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    continuation.yield(total(of: snapshot?.documents ?? []))
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    private static func currentBalance(
        classId: String,
        studentNumber: Int,
        firestore: Firestore
    ) async throws -> Int {
        try await FirestorePointBalanceStore.ensureBalance(
            classId: classId,
            studentNumber: studentNumber,
            firestore: firestore
        )
        let snapshot = try await FirestorePointBalanceStore
            .pointBalanceDocument(
                classId: classId,
                studentNumber: studentNumber,
                firestore: firestore
            )
            .getDocument()
        return FirestorePointBalanceStore.balance(from: snapshot)
    }

    private static func total(of documents: [QueryDocumentSnapshot]) -> Int {
        documents.reduce(0) { sum, document in
            sum + ((document.data()["amount"] as? Int) ?? 0)
        }
    }

    private static func ledgerCollection(classId: String, firestore: Firestore) -> CollectionReference {
        firestore
            .collection("classes")
            .document(classId)
            .collection("pointLedger")
    }

    private static func entryData(
        eater: StudentSummary,
        approver: StudentSummary,
        mealDate: String
    ) -> [String: Any] {
        [
            "studentNumber": eater.attendanceNumber,
            "studentNickname": eater.nickname,
            "amount": 1,
            "type": PointEntryType.mealCompletion.rawValue,
            "approverNumber": approver.attendanceNumber,
            "approverNickname": approver.nickname,
            "mealDate": mealDate,
            "createdAt": FieldValue.serverTimestamp(),
        ]
    }
}
