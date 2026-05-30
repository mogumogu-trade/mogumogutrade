import SwiftUI

struct HomeView: View {
    @State var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileCard
                    Text("今日の トレード")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .padding(.top, 8)
                    tradeEntry

                    NavigationLink {
                        AuctionTabView(viewModel: AuctionViewModel(profile: viewModel.profile))
                    } label: {
                        Label("ベットへ いく", systemImage: "crown.fill")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppColors.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: AppColors.primary.opacity(0.28), radius: 8, x: 0, y: 4)
                    }
                    NavigationLink {
                        QRCheckView()
                    } label: {
                        HStack {
                            Image(systemName: "qrcode.viewfinder").font(.system(size: 18, weight: .bold))
                            Text("かんしょくチェック（QR）へ いく").font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: AppColors.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(24)
            }
            .background(AppColors.bg.ignoresSafeArea())
            .navigationTitle("もぐもぐトレード")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileCard: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.displayName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                Text("クラスコード \(viewModel.profile.classId)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
        )
    }

    private var tradeEntry: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(AppColors.primary)
            Text("出品してみよう")
                .font(.system(size: 18, weight: .black, design: .rounded))
            Text("わたすものと ほしいものを えらぶよ")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            NavigationLink {
                TradeView(viewModel: TradeViewModel(profile: viewModel.profile))
            } label: {
                Text("トレードへ いく")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: AppColors.primary.opacity(0.28), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(AppColors.primaryLight.opacity(0.45), lineWidth: 2)
        )
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(
        profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ")
    ))
}
