import Dependencies
import DependenciesMacros
import FirebaseFirestore
import Foundation

/// クラス内の生徒ごとのアレルギー登録情報を扱う Client。
@DependencyClient
struct AllergyClient: Sendable {
    /// クラスの生徒名簿（アレルギー登録付き）を読み込む。
    var loadRoster: @Sendable (_ classId: String) async throws -> [StudentAllergy]
    /// 1人分のアレルギー登録を保存する。
    var save: @Sendable (_ classId: String, _ allergy: StudentAllergy) async throws -> Void
}

extension AllergyClient: DependencyKey {
    static let liveValue = AllergyClient(
        loadRoster: { classId in
            try await FirestoreAllergyService.loadRoster(classId: classId)
        },
        save: { classId, allergy in
            try await FirestoreAllergyService.save(classId: classId, allergy: allergy)
        }
    )

    static let previewValue = AllergyClient(
        loadRoster: { _ in seedRoster },
        save: { _, _ in }
    )

    /// 動作確認・プレビュー用の仮名簿。
    static let seedRoster: [StudentAllergy] = [
        StudentAllergy(studentNumber: 1, nickname: "もぐ", allergens: [.milk]),
        StudentAllergy(studentNumber: 2, nickname: "はる", allergens: []),
        StudentAllergy(studentNumber: 3, nickname: "りん", allergens: [.egg, .wheat]),
        StudentAllergy(studentNumber: 8, nickname: "そら", allergens: []),
    ]
}

extension DependencyValues {
    var allergyClient: AllergyClient {
        get { self[AllergyClient.self] }
        set { self[AllergyClient.self] = newValue }
    }
}

private enum FirestoreAllergyService {
    static func loadRoster(classId: String) async throws -> [StudentAllergy] {
        let snapshot = try await studentsCollection(classId: classId)
            .order(by: "studentNumber")
            .getDocuments()

        let roster = snapshot.documents.compactMap(studentAllergy(from:))
        return roster.isEmpty ? AllergyClient.seedRoster : roster
    }

    static func save(classId: String, allergy: StudentAllergy) async throws {
        let document = try await studentDocument(classId: classId, studentNumber: allergy.studentNumber)
        let allergies = allergy.allergens
            .map(\.rawValue)
            .sorted()

        try await document.setData(
            [
                "studentNumber": allergy.studentNumber,
                "name": allergy.nickname,
                "nickname": allergy.nickname,
                "allergies": allergies,
                "updatedAt": FieldValue.serverTimestamp(),
            ],
            merge: true
        )
    }

    private static func studentsCollection(classId: String) -> CollectionReference {
        Firestore.firestore()
            .collection("classes")
            .document(classId)
            .collection("students")
    }

    private static func studentDocument(classId: String, studentNumber: Int) async throws -> DocumentReference {
        let snapshot = try await studentsCollection(classId: classId)
            .whereField("studentNumber", isEqualTo: studentNumber)
            .limit(to: 1)
            .getDocuments()

        if let document = snapshot.documents.first {
            return document.reference
        }
        return studentsCollection(classId: classId).document(String(studentNumber))
    }

    private static func studentAllergy(from document: QueryDocumentSnapshot) -> StudentAllergy? {
        let data = document.data()
        guard let studentNumber = data["studentNumber"] as? Int else { return nil }

        let nickname = data["nickname"] as? String
            ?? data["name"] as? String
            ?? ""

        let allergens = allergens(from: data["allergies"])

        return StudentAllergy(
            studentNumber: studentNumber,
            nickname: nickname,
            allergens: allergens
        )
    }

    private static func allergens(from value: Any?) -> Set<Allergen> {
        guard let values = value as? [String] else { return [] }
        return Set(values.compactMap(Allergen.init(rawValue:)))
    }
}
