import SwiftUI

struct AuctionTabView: View {
    @Bindable var viewModel: AuctionViewModel

    var body: some View {
        Group {
            if let activeRoom = viewModel.activeRoom {
                BetView(room: activeRoom, viewModel: viewModel)
            } else {
                auctionEmptyState
            }
        }
        .navigationTitle("オークション")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.activeRoom?.id) {
            await viewModel.observeMyBidForActiveRoom()
        }
        .task(id: viewModel.activeRoom?.id) {
            await viewModel.observeResultForActiveRoom()
        }
    }

    private var auctionEmptyState: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "crown")
                    .font(.system(size: 52))
                    .foregroundStyle(AppColors.boardBorder)

                Text("いまは開催中じゃないよ")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("先生が始めたら参加できるよ")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "star.circle.fill")
                    Text("持っているポイント \(viewModel.pointBalance) P")
                }
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.darkText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppColors.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
                )
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }
}

#Preview("開催なし") {
    NavigationStack {
        AuctionTabView(viewModel: AuctionViewModel(
            profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"),
            pointBalance: 120
        ))
    }
}

#Preview("開催中") {
    NavigationStack {
        AuctionTabView(viewModel: AuctionViewModel(
            profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"),
            activeRoom: AuctionRoom(id: "preview", itemName: "プリン", stockCount: 1),
            pointBalance: 120
        ))
    }
}
