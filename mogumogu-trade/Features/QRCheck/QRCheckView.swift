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
            AppColors.bg.ignoresSafeArea()

            VStack(spacing: 16) {
                balanceHeader

                Picker("モード", selection: $viewModel.mode) {
                    Text("QRをみせる").tag(QRCheckViewModel.Mode.show)
                    Text("QRをよむ").tag(QRCheckViewModel.Mode.read)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .tint(AppColors.primary)

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

    private var balanceHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(.orange)
            Text("いまのポイント \(viewModel.balance) P")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.darkText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(AppColors.card)
        .clipShape(Capsule())
        .shadow(color: AppColors.primary.opacity(0.10), radius: 4, y: 2)
    }

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
                        .background(AppColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColors.primaryLight.opacity(0.55), lineWidth: 2)
                        )
                        .shadow(color: AppColors.primary.opacity(0.14), radius: 8, x: 0, y: 4)
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
            .tint(AppColors.primary)
        }
        .padding()
    }

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
                    .stroke(AppColors.primaryLight, lineWidth: 4)
                    .frame(width: 200, height: 200)

                Text("ここにQRをあわせてね")
                    .foregroundStyle(.white)
                    .font(.system(size: 12, weight: .bold))
                    .offset(y: 120)
            }

            if viewModel.isProcessing {
                ProgressView("よみこみ中")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
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
        .background(result.isSuccess ? AppColors.primary : Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .onTapGesture { viewModel.clearScanResult() }
    }

    private var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            ForEach(0..<30, id: \.self) { index in
                ConfettiPieceView(animate: confettiAnimate, index: index)
            }

            VStack(spacing: 24) {
                Text("完食達成！")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryLight)
                    .shadow(color: .white, radius: 2)
                    .scaleEffect(confettiAnimate ? 1.1 : 0.6)

                Text("+1P ゲット！")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text("おにぎり")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(confettiAnimate ? 360 : 0))

                Text("いまのポイント \(viewModel.balance) P")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryLight)

                Button {
                    viewModel.dismissCelebration()
                } label: {
                    Text("つぎへすすむ")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 40)
                        .background(AppColors.primary)
                        .clipShape(Capsule())
                        .shadow(color: AppColors.primary.opacity(0.4), radius: 10, y: 5)
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
