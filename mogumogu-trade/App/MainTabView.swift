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
                MileagePlaceholderView(profile: profile)
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
    }
}

private struct MileagePlaceholderView: View {
    let profile: StudentProfile

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.96, blue: 0.98)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(red: 0.47, green: 0.33, blue: 0.28))

                Text("完食マイレージ")
                    .font(.system(size: 26, weight: .black, design: .rounded))

                Text("\(profile.studentNumber)番 \(profile.nickname)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .navigationTitle("マイレージ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    MainTabView(profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"))
}
