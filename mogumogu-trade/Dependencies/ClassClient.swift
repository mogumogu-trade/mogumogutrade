import Dependencies
import DependenciesMacros
import FirebaseFirestore
import Foundation

@DependencyClient
struct ClassClient: Sendable {
    var verifyClass: @Sendable (_ classId: String) async throws -> Bool
}

extension ClassClient: DependencyKey {
    static let liveValue = ClassClient(
        verifyClass: { classId in
            let snapshot = try await Firestore.firestore()
                .collection("classes")
                .document(classId)
                .getDocument()
            return snapshot.exists
        }
    )

    static let previewValue = ClassClient(
        verifyClass: { _ in true }
    )
}

extension DependencyValues {
    var classClient: ClassClient {
        get { self[ClassClient.self] }
        set { self[ClassClient.self] = newValue }
    }
}
