import Foundation
import FirebaseFirestore

struct Bid: Codable, Identifiable {

    @DocumentID var id: String?

    var amount: Int
    var studentNickname: String
    var studentNumber: Int
    let createdAt: Timestamp
    var updatedAt: Timestamp
}
