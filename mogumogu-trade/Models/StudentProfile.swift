import Foundation

struct StudentProfile: Equatable, Codable, Sendable {
    let classId: String
    let studentNumber: Int
    let nickname: String
}
