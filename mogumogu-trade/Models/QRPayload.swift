import Foundation

/// 完食マイレージの承認用トークン。
///
/// フロー上、**完食者**が自分の端末に表示し、**確認者**が読み取る。
/// 確認者側で `classId`・自己承認・有効期限を検証してから加点する。
struct QRPayload: Codable, Sendable, Equatable {
    /// スキーマバージョン。将来の互換判定に使う。
    let v: Int
    let classId: String
    /// 完食者（このQRを表示している本人）の出席番号。
    let studentNumber: Int
    let nickname: String
    /// 重複検知・毎回更新用のランダム値。
    let nonce: String
    /// 発行時刻。有効期限（5分）判定に使う。
    let issuedAt: Date

    static let currentVersion = 1
}
