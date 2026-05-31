import Dependencies
import FirebaseFirestore

struct StudentClient: Sendable {

    var verifyClass: @Sendable (_ classId: String) async throws -> Bool

    var createStudent: @Sendable (
        _ classId: String,
        _ student: Student
    ) async throws -> Void
    
    var getStudents: @Sendable(
        _ classId: String
    ) async throws -> [Student]
}
extension StudentClient: DependencyKey {

    static let liveValue = StudentClient(

        verifyClass: { classId in

            let snapshot = try await Firestore.firestore()
                .collection("classes")
                .document(classId)
                .getDocument()

            return snapshot.exists
        },

        createStudent: { classId, student in
            do{
                try Firestore.firestore()
                    .collection("classes")
                    .document(classId)
                    .collection("students")
                    .document(student.id.uuidString)
                    .setData(from: student)
            }
            catch{
                print(error)
            }
        }, getStudents: { classId in
            let snapshot = try await Firestore.firestore()
                .collection("classes")
                .document(classId)
                .collection("students")
                .getDocuments()
            return snapshot.documents.compactMap { doc in
                try? doc.data(as: Student.self)
            }
        }
    )
}
extension DependencyValues {

    var studentClient: StudentClient {
        get { self[StudentClient.self] }
        set { self[StudentClient.self] = newValue }
    }
}
