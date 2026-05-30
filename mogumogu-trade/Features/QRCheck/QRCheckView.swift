import SwiftUI

struct QRCheckView: View {
    // 動きやデータは全部この ViewModel に任せる
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
                    
                    if viewModel.selectedTab == 0 {
                        // ==================== 【みせる側】 ====================
                        VStack(spacing: 20) {
                            Text("友だちのトレイがピカピカなら\nQRコードをみせてあげよう！")
                                .font(.system(size: 14, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding()
                            
                            if let qrImage = viewModel.generateQRCode(from: viewModel.qrTokenString) {
                                Image(uiImage: qrImage)
                                    .resizable()
                                    .interpolation(.none)
                                    .frame(width: 200, height: 200)
                                    .padding(20)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(radius: 5)
                            }
                        }
                        .padding(.top, 40)
                        
                    } else {
                        // ==================== 【よむ側：カメラ起動】 ====================
                        VStack(spacing: 20) {
                            Text("友だちのスマホのQRコードを\nカメラでうつしてね！")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.gray)
                            
                            ZStack {
                                // 📸 本物のカメラ映像
                                QRScannerCameraView { scannedCode in
                                    viewModel.onScanSuccess(scannedCode: scannedCode)
                                }
                                .frame(width: 280, height: 280)
                                .cornerRadius(24)
                                .shadow(radius: 10)
                                
                                // スキャン枠（ミントグリーン）
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(customHex: "4ECDC4"), lineWidth: 4)
                                    .frame(width: 200, height: 200)
                                
                                // お祝い画面が出ていないときだけレーザー線を出す
                                if !viewModel.isShowingCelebration {
                                    Rectangle()
                                        .fill(LinearGradient(colors: [.clear, Color(customHex: "4ECDC4"), .clear], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 190, height: 4)
                                        .offset(y: viewModel.laserOffset)
                                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.laserOffset)
                                }
                                
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
                        .foregroundColor(.red)
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
                        .foregroundColor(.yellow)
                    
                    Spacer()

                    Button(action: {
                        viewModel.resetCelebration()
                    }) {
                        Text("つぎへすすむ ➔")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 40)
                            .background(Color(customHex: "4ECDC4"))
                            .cornerRadius(50)
                            .shadow(color: Color(customHex: "4ECDC4").opacity(0.4), radius: 10, x: 0, y: 5)
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
