import Dependencies
import Foundation
import UIKit

@Observable
@MainActor
final class QRCheckViewModel {
    enum Mode: Int, CaseIterable {
        /// 完食者として自分のQRを表示する。
        case show = 0
        /// 確認者として相手のQRを読み取り、加点する。
        case read = 1
    }

    /// 読み取り結果。子ども向けの表示に使う。
    enum ScanResult: Equatable {
        case gavePoint(to: StudentSummary)
        case alreadyAwardedToday
        case selfApproval
        case expired
        case invalid
        case failed

        var message: String {
            switch self {
            case let .gavePoint(student):
                "\(student.displayName) に 1P あげたよ！"
            case .alreadyAwardedToday:
                "この子は きょう もう もらってるよ"
            case .selfApproval:
                "じぶんのQRは よみとれないよ"
            case .expired:
                "このQRは じかんぎれだよ"
            case .invalid:
                "QRが よみとれなかったよ"
            case .failed:
                "つうしんに しっぱいしたよ"
            }
        }

        var isSuccess: Bool {
            if case .gavePoint = self { return true }
            return false
        }
    }

    let profile: StudentProfile
    var mode: Mode = .show
    private(set) var qrImage: UIImage?
    private(set) var scanResult: ScanResult?
    private(set) var isProcessing = false
    private(set) var balance: Int = 0
    private(set) var showCelebration = false

    private var hasLoadedInitialBalance = false
    private var celebratedBalance = 0
    private var isHandlingScan = false

    @ObservationIgnored @Dependency(\.qrCodeClient) private var qrCodeClient
    @ObservationIgnored @Dependency(\.mileageClient) private var mileageClient
    @ObservationIgnored @Dependency(\.date.now) private var now
    @ObservationIgnored @Dependency(\.uuid) private var uuid

    private var currentStudent: StudentSummary { StudentSummary(profile: profile) }

    init(profile: StudentProfile) {
        self.profile = profile
    }

    /// 表示用のQRを毎回新しい nonce・発行時刻で作り直す。
    func refreshDisplayQR() {
        let payload = QRPayload(
            v: QRPayload.currentVersion,
            classId: profile.classId,
            studentNumber: profile.studentNumber,
            nickname: profile.nickname,
            nonce: uuid().uuidString,
            issuedAt: now
        )
        qrImage = qrCodeClient.generate(payload)
    }

    /// 自分の残高を購読する。最初の同期では演出せず、以降の増加で完食演出を出す。
    func observeBalance() async {
        do {
            for try await latest in mileageClient.observeBalance(profile.classId, profile.studentNumber) {
                if !hasLoadedInitialBalance {
                    hasLoadedInitialBalance = true
                    celebratedBalance = latest
                    balance = latest
                    continue
                }
                if latest > celebratedBalance {
                    celebratedBalance = latest
                    showCelebration = true
                }
                balance = latest
            }
        } catch {
            // 残高購読の失敗は致命的ではない（再表示で回復する）。
        }
    }

    /// 確認者として相手のQRを読み取ったときの処理。
    ///
    /// 結果表示中（`scanResult != nil`）はカメラの連続フレームで二重発火しないよう止め、
    /// バナーをタップ（`clearScanResult`）してから次を読み取る。
    func onScan(_ code: String) async {
        guard mode == .read, !isHandlingScan, scanResult == nil else { return }
        isHandlingScan = true
        isProcessing = true
        defer {
            isProcessing = false
            isHandlingScan = false
        }

        guard let payload = qrCodeClient.parse(code) else {
            scanResult = .invalid
            return
        }

        switch Self.validate(payload: payload, approver: profile, now: now) {
        case .differentClass:
            scanResult = .invalid
        case .selfApproval:
            scanResult = .selfApproval
        case .expired:
            scanResult = .expired
        case .valid:
            await award(for: payload)
        }
    }

    func clearScanResult() {
        scanResult = nil
    }

    func dismissCelebration() {
        showCelebration = false
    }

    private func award(for payload: QRPayload) async {
        let eater = StudentSummary(attendanceNumber: payload.studentNumber, nickname: payload.nickname)
        do {
            let result = try await mileageClient.awardMealCompletion(
                profile.classId,
                eater,
                currentStudent,
                MealDate.string(for: now),
                now
            )
            switch result {
            case .awarded:
                scanResult = .gavePoint(to: eater)
            case .alreadyAwardedToday:
                scanResult = .alreadyAwardedToday
            }
        } catch {
            scanResult = .failed
        }
    }

    // MARK: - 検証ロジック（副作用なし・テスト可能）

    enum Validation: Equatable {
        case valid
        case differentClass
        case selfApproval
        case expired
    }

    /// 完食ポイントの有効期限（秒）。
    static let expirySeconds: TimeInterval = 300

    /// 確認者が読み取ったQRを加点してよいか判定する。
    ///
    /// - `differentClass`: 別クラスのQR
    /// - `selfApproval`: 自分のQR（自己承認禁止）
    /// - `expired`: 発行から5分超過（または未来すぎる）
    static func validate(payload: QRPayload, approver: StudentProfile, now: Date) -> Validation {
        guard payload.classId == approver.classId else { return .differentClass }
        guard payload.studentNumber != approver.studentNumber else { return .selfApproval }
        let elapsed = now.timeIntervalSince(payload.issuedAt)
        guard elapsed >= -expirySeconds, elapsed <= expirySeconds else { return .expired }
        return .valid
    }
}
