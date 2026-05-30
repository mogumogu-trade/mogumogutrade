import Foundation

/// ポイント台帳エントリの種別。
///
/// AGENTS.md 方針に従い、残高は直接上書きせず、この台帳（履歴）の合計として扱う。
enum PointEntryType: String, Codable, Sendable {
    /// 完食マイレージの付与。
    case mealCompletion
    /// オークション落札による消費（将来）。
    case auctionWin
    /// 教員によるポイント取り消し（将来）。
    case teacherCancel
}

/// ポイント台帳の1エントリ。残高はこの `amount` の合計で算出する。
struct PointLedgerEntry: Identifiable, Hashable, Sendable {
    let id: String
    /// 対象生徒（完食者・落札者など）の出席番号。主識別子。
    let studentNumber: Int
    /// 符号つきの増減（完食 = +1 など）。
    let amount: Int
    let type: PointEntryType
    /// 完食を承認した確認者の出席番号（QR由来）。完食以外は nil。
    let approverNumber: Int?
    /// 給食日（"yyyy-MM-dd"）。
    let mealDate: String
    let createdAt: Date
}
