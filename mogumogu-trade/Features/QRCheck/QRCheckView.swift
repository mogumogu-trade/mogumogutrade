import Dependencies
import SwiftUI

struct QRCheckView: View {
    @State private var viewModel: QRCheckViewModel
    @State private var confettiAnimate = false

    init(profile: StudentProfile) {
        _viewModel = State(initialValue: QRCheckViewModel(profile: profile))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ZStack {
            Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea()

            VStack(spacing: 16) {
                balanceHeader

                Picker("モード", selection: $viewModel.mode) {
                    Text("QRをみせる").tag(QRCheckViewModel.Mode.show)
                    Text("QRをよむ").tag(QRCheckViewModel.Mode.read)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch viewModel.mode {
                case .show:
                    showSection
                case .read:
                    readSection
                }

                Spacer()
            }
            .padding(.top)

            if viewModel.showCelebration {
                celebrationOverlay
            }
        }
        .navigationTitle("かんしょくチェック")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.observeBalance() }
        .onAppear { viewModel.refreshDisplayQR() }
        .onChange(of: viewModel.mode) { _, newMode in
            viewModel.clearScanResult()
            if newMode == .show { viewModel.refreshDisplayQR() }
        }
    }

    // MARK: - 残高

    private var balanceHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(.orange)
            Text("いまのポイント \(viewModel.balance) P")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.31, green: 0.22, blue: 0.18))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    // MARK: - みせる（完食者）

    private var showSection: some View {
        VStack(spacing: 16) {
            Text("トレイがピカピカになったら\nこのQRを 友だちに よみとってもらおう！")
                .font(.system(size: 14, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Group {
                if let qrImage = viewModel.qrImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 220, height: 220)
                        .padding(20)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 5)
                } else {
                    ProgressView()
                        .frame(width: 260, height: 260)
                }
            }

            Text("\(viewModel.profile.studentNumber)番 \(viewModel.profile.nickname)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Button {
                viewModel.refreshDisplayQR()
            } label: {
                Label("QRをつくりなおす", systemImage: "arrow.clockwise")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
        }
        .padding()
    }

    // MARK: - よむ（確認者）

    private var readSection: some View {
        VStack(spacing: 16) {
            Text("友だちのQRコードを\nカメラで よみとってね！")
                .font(.system(size: 14, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            ZStack {
                QRScannerCameraView { code in
                    Task { await viewModel.onScan(code) }
                }
                .frame(width: 260, height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(radius: 10)

                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(customHex: "4ECDC4"), lineWidth: 4)
                    .frame(width: 200, height: 200)
            }

            if let result = viewModel.scanResult {
                resultBanner(result)
            }
        }
        .padding()
    }

    private func resultBanner(_ result: QRCheckViewModel.ScanResult) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: result.isSuccess ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                Text(result.message)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            Text("タップで つづける")
                .font(.system(size: 11, weight: .bold))
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(result.isSuccess ? Color(red: 0.30, green: 0.72, blue: 0.42) : Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .onTapGesture { viewModel.clearScanResult() }
    }

    // MARK: - 完食演出（完食者側で残高が増えたら）

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            ForEach(0..<30, id: \.self) { index in
                ConfettiPieceView(animate: confettiAnimate, index: index)
            }

            VStack(spacing: 24) {
                Text("完食達成！")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.red)
                    .shadow(color: .white, radius: 2)
                    .scaleEffect(confettiAnimate ? 1.1 : 0.6)

                Text("+1P ゲット！")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("🍙")
                    .font(.system(size: 72))
                    .rotationEffect(.degrees(confettiAnimate ? 360 : 0))

                Text("いまのポイント \(viewModel.balance) P")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.yellow)

                Button {
                    viewModel.dismissCelebration()
                } label: {
                    Text("つぎへすすむ ➔")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 40)
                        .background(Color(customHex: "4ECDC4"))
                        .clipShape(Capsule())
                        .shadow(color: Color(customHex: "4ECDC4").opacity(0.4), radius: 10, y: 5)
                }
            }
        }
        .transition(.opacity)
        .onAppear {
            confettiAnimate = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                confettiAnimate = true
            }
        }
        .onDisappear { confettiAnimate = false }
    }
}

extension Color {
    init(customHex: String) {
        let hex = customHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

#Preview("正常（残高あり）") {
    NavigationStack {
        withDependencies {
            $0.mileageClient.observeBalance = { _, _ in
                AsyncThrowingStream { $0.yield(3); $0.finish() }
            }
        } operation: {
            QRCheckView(profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"))
        }
    }
}

#Preview("残高0") {
    NavigationStack {
        QRCheckView(profile: StudentProfile(classId: "123456", studentNumber: 12, nickname: "もぐ"))
    }
}
