import SwiftUI

struct MainTabView: View {
    private let profile: StudentProfile
    @State private var tradeViewModel: TradeViewModel
    @State private var auctionViewModel: AuctionViewModel

    init(profile: StudentProfile) {
        self.profile = profile
        _tradeViewModel = State(initialValue: TradeViewModel(profile: profile))
        _auctionViewModel = State(initialValue: AuctionViewModel(profile: profile))
    }

    var body: some View {
        TabView {
            NavigationStack {
                TradeView(viewModel: tradeViewModel)
            }
            .tabItem {
                Label("出品", systemImage: "arrow.left.arrow.right.circle.fill")
            }

            NavigationStack {
                TradeOffersView(viewModel: tradeViewModel)
            }
            .tabItem {
                Label("みんな", systemImage: "person.2.fill")
            }

            NavigationStack {
                QRCheckView(profile: profile)
            }
            .tabItem {
                Label("マイレージ", systemImage: "checkmark.seal.fill")
            }

            NavigationStack {
                AuctionTabView(viewModel: auctionViewModel)
            }
            .tabItem {
                Label("オークション", systemImage: "crown.fill")
            }
        }
        .tint(AppColors.primary)
        .task {
            await tradeViewModel.observeOffers()
        }
        .task {
            await auctionViewModel.observeLatestRoom()
        }
        .task {
            await auctionViewModel.observeBalance()
        }
    }
}

#Preview {
    MainTabView(profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"))
}
