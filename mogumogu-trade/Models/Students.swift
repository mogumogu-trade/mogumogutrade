import Foundation
import FirebaseFirestore

struct Student: Codable,Identifiable {
    let id: UUID
    let name: String
    let studentNumber: Int
    let point: Int
    let allergies: [String]
    let createdAt: Timestamp
}
// Student型のモックデータ配列
enum StudentMock {
    static let mockStudents: [Student] = [
        Student(
            id: UUID(),
            name: "田中 太郎",
            studentNumber: 101,
            point: 85,
            allergies: ["卵", "乳製品"],
            createdAt: Timestamp(date: Date())
        ),
        Student(
            id: UUID(),
            name: "佐藤 花子",
            studentNumber: 102,
            point: 92,
            allergies: [],
            createdAt: Timestamp(date: Date().addingTimeInterval(-86400))
        ),
        Student(
            id: UUID(),
            name: "鈴木 次郎",
            studentNumber: 103,
            point: 76,
            allergies: ["そば"],
            createdAt: Timestamp(date: Date().addingTimeInterval(-172800))
        )
    ]
}

