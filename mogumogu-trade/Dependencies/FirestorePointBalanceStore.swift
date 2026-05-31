import FirebaseFirestore
import Foundation

enum FirestorePointBalanceStore {
    static func ensureBalance(
        classId: String,
        studentNumber: Int,
        firestore: Firestore = Firestore.firestore()
    ) async throws {
        let balanceRef = pointBalanceDocument(
            classId: classId,
            studentNumber: studentNumber,
            firestore: firestore
        )
        let snapshot = try await balanceRef.getDocument()
        guard !snapshot.exists else { return }

        let balance = try await ledgerBalance(
            classId: classId,
            studentNumber: studentNumber,
            firestore: firestore
        )

        _ = try await firestore.runTransaction { transaction, errorPointer in
            do {
                let latest = try transaction.getDocument(balanceRef)
                if !latest.exists {
                    transaction.setData(
                        balanceData(studentNumber: studentNumber, balance: balance),
                        forDocument: balanceRef
                    )
                }
            } catch let error as NSError {
                errorPointer?.pointee = error
            }
            return nil
        }
    }

    static func pointBalanceDocument(
        classId: String,
        studentNumber: Int,
        firestore: Firestore
    ) -> DocumentReference {
        firestore
            .collection("classes")
            .document(classId)
            .collection("pointBalances")
            .document("\(studentNumber)")
    }

    static func ledgerCollection(classId: String, firestore: Firestore) -> CollectionReference {
        firestore
            .collection("classes")
            .document(classId)
            .collection("pointLedger")
    }

    static func balance(from snapshot: DocumentSnapshot) -> Int {
        snapshot.data()?["balance"] as? Int ?? 0
    }

    static func setBalance(
        _ balance: Int,
        studentNumber: Int,
        transaction: Transaction,
        ref: DocumentReference
    ) {
        transaction.setData(
            balanceData(studentNumber: studentNumber, balance: balance),
            forDocument: ref,
            merge: true
        )
    }

    static func ledgerBalance(
        classId: String,
        studentNumber: Int,
        firestore: Firestore
    ) async throws -> Int {
        let snapshot = try await ledgerCollection(classId: classId, firestore: firestore)
            .whereField("studentNumber", isEqualTo: studentNumber)
            .getDocuments()

        return snapshot.documents.reduce(0) { sum, document in
            sum + ((document.data()["amount"] as? Int) ?? 0)
        }
    }

    private static func balanceData(studentNumber: Int, balance: Int) -> [String: Any] {
        [
            "studentNumber": studentNumber,
            "balance": balance,
            "updatedAt": FieldValue.serverTimestamp(),
        ]
    }
}
