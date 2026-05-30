import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

struct QRCheckView: View {
    @State private var selectedTab = 1 // 最初は「よむ」タブ
    @State private var qrTokenString: String = "KM-sota-TEST"
    
    // --- 演出用の状態 ---
    @State private var laserOffset: CGFloat = -95
    @State private var isShowingCelebration = false
    @State private var pointsForAnimation: Int = 350
    
    // クラッカー・紙吹雪のアニメーション用状態
    @State private var confettiAnimate = false

    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    Picker("モード", selection: $selectedTab) {
                        Text("QRをみせる").tag(0)
                        Text("QRをよむ").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    if selectedTab == 0 {
                        // ==================== 【みせる側】 ====================
                        VStack(spacing: 20) {
                            Text("友だちのトレイがピカピカなら\nQRコードをみせてあげよう！")
                                .font(.system(size: 14, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                                .padding()
                            
                            if let qrImage = generateQRCode(from: qrTokenString) {
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
                                    if !isShowingCelebration {
                                        print("ガチでQR読めた！中身: \(scannedCode)")
                                        onScanSuccess()
                                    }
                                }
                                .frame(width: 280, height: 280)
                                .cornerRadius(24)
                                .shadow(radius: 10)
                                
                                // スキャン枠（ミントグリーン）
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(customHex: "4ECDC4"), lineWidth: 4)
                                    .frame(width: 200, height: 200)
                                
                                // お祝い画面が出ていないときだけレーザー線を出す
                                if !isShowingCelebration {
                                    Rectangle()
                                        .fill(LinearGradient(colors: [.clear, Color(customHex: "4ECDC4"), .clear], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 190, height: 4)
                                        .offset(y: laserOffset)
                                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: true), value: laserOffset)
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
                DispatchQueue.main.async {
                    laserOffset = 95
                }
            }

            // ==================== 🌟 画面全体クラッカー＆大文字お祝いエフェクト ====================
            if isShowingCelebration {
                // 画面全体を暗いシアター風にする背景
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // 背景：画面全体に飛び散る紙吹雪エフェクト
                ForEach(0..<30, id: \.self) { index in
                    ConfettiPieceView(animate: confettiAnimate, index: index)
                }

                // 前面の文字・キャラクター・ボタン
                VStack(spacing: 30) {
                    Spacer()
                    
                    // 完食達成！を【赤い大文字】で表示
                    Text("完食達成！")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                        .shadow(color: .white, radius: 2)
                        .scaleEffect(confettiAnimate ? 1.1 : 0.5)
                    
                    // その下に【白字の中文字】で50pt！
                    Text("50pt ゲット！")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    // かわいいドット風応援キャラクター（真ん中）
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(confettiAnimate ? 1.2 : 0.8)
                        
                        Text("🍙")
                            .font(.system(size: 80))
                            .rotationEffect(.degrees(confettiAnimate ? 360 : 0))
                    }
                    
                    // 現在のポイント合計
                    Text("いまのポイント: \(pointsForAnimation) pt")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                    
                    Spacer()

                    // マイページにもどるボタン
                    Button(action: {
                        laserOffset = -95
                        confettiAnimate = false
                        withAnimation(.easeOut(duration: 0.2)) {
                            isShowingCelebration = false
                        }
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
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                        confettiAnimate = true
                    }
                }
            }
        }
    }

    func onScanSuccess() {
        guard !isShowingCelebration else { return }
        isShowingCelebration = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                pointsForAnimation += 50
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(string.utf8), forKey: "inputMessage")
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

// ==================== 画面全体に飛び散る紙吹雪パーツ ====================
struct ConfettiPieceView: View {
    var animate: Bool
    var index: Int
    
    let colors: [Color] = [.yellow, .pink, .blue, .green, .orange, .purple, .cyan]
    
    var body: some View {
        let randomX = CGFloat(sin(Double(index) * 45.0) * 160.0)
        let randomY = CGFloat(cos(Double(index) * 30.0) * 300.0) - (animate ? 50 : 0)
        let randomRotation = Double(index * 25)
        
        return Group {
            if index % 2 == 0 {
                Rectangle()
                    .fill(colors[index % colors.count])
                    .frame(width: CGFloat.random(in: 10...18), height: CGFloat.random(in: 10...18))
            } else {
                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: CGFloat.random(in: 8...15), height: CGFloat.random(in: 8...15))
            }
        }
        .offset(x: animate ? randomX : 0, y: animate ? randomY : 150)
        .rotationEffect(.degrees(animate ? randomRotation + 360 : randomRotation))
        .opacity(animate ? 0.9 : 0.0)
        .animation(.easeOut(duration: Double.random(in: 0.8...1.5)).delay(Double.random(in: 0.0...0.1)), value: animate)
    }
}

// ==================== 本物のカメラを起動するプログラム ====================
struct QRScannerCameraView: UIViewRepresentable {
    var onQrCodeFound: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 280, height: 280))
        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch { return view }

        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else { return view }

        let metadataOutput = AVCaptureMetadataOutput()

        if (session.canAddOutput(metadataOutput)) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else { return view }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = CGRect(x: 0, y: 0, width: 280, height: 280)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublineLayer(previewLayer)

        DispatchQueue.global(qos: .background).async {
            session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerCameraView

        init(parent: QRScannerCameraView) {
            self.parent = parent
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                DispatchQueue.main.async {
                    self.parent.onQrCodeFound(stringValue)
                }
            }
        }
    }
}

extension CALayer {
    func addSublineLayer(_ layer: CALayer) {
        self.addSublayer(layer)
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
