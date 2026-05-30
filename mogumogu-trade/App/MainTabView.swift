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
        .tint(AppColors.primary)
    }
}

private struct MileagePlaceholderView: View {
    let profile: StudentProfile
    
    @State private var myFixedPoints: Int = 10

    var body: some View {
        ZStack {
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 30) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(AppColors.primary)

                    Text("完食マイレージ")
                        .font(.system(size: 26, weight: .black, design: .rounded))

                    Text("\(profile.studentNumber)番 \(profile.nickname)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("いまのポイント")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 2) {
                            Text("\(myFixedPoints)") // 💡 10ptを表示
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundStyle(AppColors.primary)
                            Text("pt")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 8)
                        }
                    }
                    Spacer()
                    
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.primaryLight)
                }
                .padding(24)
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
                )
                .shadow(color: AppColors.primary.opacity(0.12), radius: 10, x: 0, y: 5)

                NavigationLink {
                    let qrViewModel = QRCheckViewModel()
                    QRCheckView()
                        .onAppear {
                            qrViewModel.onPointAdded = {
                                print("QRスキャン成功の合図をキャッチしました！")
                            }
                        }
                } label: {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .bold))
                        Text("QRコードをよむ / みせる")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
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
