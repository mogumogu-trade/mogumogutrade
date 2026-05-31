import Dependencies
import Foundation

@Observable
@MainActor
final class AuctionViewModel {
    enum ScreenState: Equatable {
        case bidding
        case waiting
        case win(AuctionWinner)
        case lose
        case noWinner
        case resultPending
    }

    let profile: StudentProfile
    let mealDate: String
    var activeRoom: AuctionRoom?
    var pointBalance: Int
    private(set) var myBid: AuctionBid?
    private(set) var result: AuctionResult?
    private(set) var errorMessage: String?
    private(set) var isSubmittingBid = false
    private(set) var isLoadingRoom = false

    @ObservationIgnored @Dependency(\.auctionClient) private var auctionClient
    @ObservationIgnored @Dependency(\.mileageClient) private var mileageClient

    init(
        profile: StudentProfile,
        mealDate: String? = nil,
        activeRoom: AuctionRoom? = nil,
        pointBalance: Int = 0,
        myBid: AuctionBid? = nil,
        result: AuctionResult? = nil
    ) {
        @Dependency(\.date.now) var now
        self.profile = profile
        self.mealDate = mealDate ?? MealDate.string(for: now)
        self.activeRoom = activeRoom
        self.pointBalance = pointBalance
        self.myBid = myBid
        self.result = result
    }

    var currentStudent: StudentSummary {
        StudentSummary(profile: profile)
    }

    var screenState: ScreenState {
        guard let room = activeRoom else { return .bidding }

        if room.status == .closed {
            guard let result else { return .resultPending }
            guard let winner = result.winner else { return .noWinner }
            return winner.student == currentStudent ? .win(winner) : .lose
        }

        return myBid == nil ? .bidding : .waiting
    }

    var isFirstBid: Bool {
        myBid == nil
    }

    func observeLatestRoom() async {
        isLoadingRoom = activeRoom == nil
        do {
            for try await room in auctionClient.observeLatestRoom(profile.classId, mealDate) {
                if activeRoom?.id != room?.id {
                    myBid = nil
                    result = nil
                }
                activeRoom = room
                isLoadingRoom = false
                errorMessage = nil
            }
        } catch {
            isLoadingRoom = false
            errorMessage = "オークションを読みこめませんでした"
        }
    }

    func observeBalance() async {
        do {
            for try await latest in mileageClient.observeBalance(profile.classId, profile.studentNumber) {
                pointBalance = latest
            }
        } catch {
            errorMessage = "ポイントを読みこめませんでした"
        }
    }

    func observeMyBidForActiveRoom() async {
        guard let room = activeRoom else { return }
        do {
            for try await bid in auctionClient.observeMyBid(
                profile.classId,
                room.id,
                profile.studentNumber
            ) {
                myBid = bid
                errorMessage = nil
            }
        } catch {
            errorMessage = "ベットを読みこめませんでした"
        }
    }

    func observeResultForActiveRoom() async {
        guard let room = activeRoom else { return }
        do {
            for try await latestResult in auctionClient.observeResult(profile.classId, room.id) {
                result = latestResult
                errorMessage = nil
            }
        } catch {
            errorMessage = "結果を読みこめませんでした"
        }
    }

    func submitBid(amount: Int) async {
        guard !isSubmittingBid else { return }
        guard let room = activeRoom, room.status == .open else {
            errorMessage = "いまはベットできません"
            return
        }

        let requiredPoints = amount + (isFirstBid ? AuctionClient.participationFee : 0)
        guard amount > 0, pointBalance >= requiredPoints else {
            errorMessage = isFirstBid
                ? "参加費とベット分のポイントが必要だよ"
                : "ポイントが足りないよ"
            return
        }

        isSubmittingBid = true
        errorMessage = nil
        defer { isSubmittingBid = false }

        do {
            myBid = try await auctionClient.submitBid(
                profile.classId,
                room.id,
                currentStudent,
                amount
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
