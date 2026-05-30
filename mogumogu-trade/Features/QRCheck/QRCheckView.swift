import SwiftUI

struct QRCheckView: View {
    @StateObject private var viewModel = QRCheckViewModel()

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    Picker("モード", selection: $viewModel.selectedTab) {
                        Text("QRをみせる").tag(0)
                        Text("QRをよむ").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .tint(AppColors.primary)
                    
                    if viewModel.selectedTab == 0 {
                        // ==================== 【みせる側】 ====================
                        VStack(spacing: 20) {
                            Text("友だちのトレイがピカピカなら\nQRコードをみせてあげよう！")
                                .font(.system(size: 14, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppColors.darkText.opacity(0.68))
                                .padding()
                            
                            if let qrImage = viewModel.generateQRCode(from: viewModel.qrTokenString) {
                                Image(uiImage: qrImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .frame(width: 200, height: 200)
                                    .padding(20)
                                    .background(AppColors.card)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.primaryLight.opacity(0.55), lineWidth: 2)
                                    )
                                    .shadow(color: AppColors.primary.opacity(0.14), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.top, 40)
                        
                    } else {
                        // ==================== 【よむ側：カメラ起動】 ====================
                        VStack(spacing: 20) {
                            Text("友だちのスマホのQRコードを\nカメラでうつしてね！")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.darkText.opacity(0.68))
                            
                            ZStack {
                                // 📸 本物のカメラ映像
                                QRScannerCameraView { scannedCode in
                                    viewModel.onScanSuccess(scannedCode: scannedCode)
                                }
                                .frame(width: 280, height: 280)
                                .cornerRadius(24)
                                .shadow(radius: 10)
                                
                                // スキャン枠
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.primaryLight, lineWidth: 4)
                                    .frame(width: 200, height: 200)
                                
                                Text("ここにQRをあわせてね")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                                    .offset(y: 120)
                            }
                        }
                        .padding(.top, 40)
                    }
                    Spacer()
                }
                .navigationTitle("かんしょくチェック")
                .navigationBarTitleDisplayMode(.inline)
                .background(AppColors.bg.ignoresSafeArea())
            }
            .onAppear {
                viewModel.startLaserAnimation()
            }

            // ==================== 🌟 お祝いエフェクト ====================
            if viewModel.isShowingCelebration {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ForEach(0..<30, id: \.self) { index in
                    ConfettiPieceView(animate: viewModel.confettiAnimate, index: index)
                }

                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("完食達成！")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.primaryLight)
                        .shadow(color: .white, radius: 2)
                        .scaleEffect(viewModel.confettiAnimate ? 1.1 : 0.5)
                    
                    Text("50pt ゲット！")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(viewModel.confettiAnimate ? 1.2 : 0.8)
                        
                        Text("🍙")
                            .font(.system(size: 80))
                            .rotationEffect(.degrees(viewModel.confettiAnimate ? 360 : 0))
                    }
                    
                    Text("いまのポイント: \(viewModel.pointsForAnimation) pt")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryLight)
                    
                    Spacer()

                    Button(action: {
                        viewModel.resetCelebration()
                    }) {
                        Text("つぎへすすむ ➔")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 40)
                            .background(AppColors.primary)
                            .cornerRadius(50)
                            .shadow(color: AppColors.primary.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.bottom, 50)
                }
                .zIndex(1)
                .onAppear {
                    viewModel.startConfettiAnimation()
                }
            }
        }
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
