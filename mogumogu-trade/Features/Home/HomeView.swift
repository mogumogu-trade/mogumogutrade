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
                        BetView()
                    } label: {
                        Text("ベットへ いく")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(24)
            }
            .background(Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea())
            .navigationTitle("もぐもぐトレード")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var profileCard: some View {
        HStack {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(red: 0.47, green: 0.33, blue: 0.28))
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
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }

    private var tradeEntry: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color(red: 0.47, green: 0.33, blue: 0.28))
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
                    .background(Color(red: 0.18, green: 0.18, blue: 0.18))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HomeView(viewModel: HomeViewModel(
        profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ")
    ))
}
