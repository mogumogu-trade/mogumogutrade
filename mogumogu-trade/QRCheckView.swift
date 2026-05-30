import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCheckView: View {
    @State private var selectedTab = 0
    
    // バックエンドやローカル（UserDefaults）に保存する用の疑似トークンデータ　
    @State private var qrTokenString: String = "KM-sota_01-123456"
    
    var body: some View {
        NavigationView {
            VStack {
                // 上部の切り替えスイッチ（SegmentedPicker）
                Picker("モード", selection: $selectedTab) {
                    Text("QRをみせる(みまもり)").tag(0)
                    Text("QRをよむ(かんしょく)").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // ==================== QRを表示する側の画面 ====================
                    VStack(spacing: 20) {
                        Text("友だちのトレイがピカピカなら\nQRコードをみせてあげよう！")
                            .font(.system(size: 16, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding()
                        
                        // 🌟 外部ライブラリなしで100%確実に生成・表示されるQRコード
                        if let qrImage = generateQRCode(from: qrTokenString) {
                            Image(uiImage: qrImage)
                                .resizable()
                                // ドットがぼやけないようにくっきりさせる処理（CSSの image-rendering: pixelated に相当）
                                .interpolation(.none)
                                .frame(width: 200, height: 200)
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 4)
                        } else {
                            // エラー時のフォールバック
                            VStack {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.red)
                                Text("QRコードの作成に\nしっぱいしました")
                                    .font(.caption)
                            }
                            .frame(width: 200, height: 200)
                        }
                        
                        Text("承認用コード: VALID_10MIN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .onAppear {
                        // 画面が表示されたタイミングで1分ごとに変わるような固有トークンを生成
                        updateQRToken()
                    }
                    
                } else {
                    // ==================== カメラで読み取る側の画面 ====================
                    VStack(spacing: 20) {
                        Text("友だちのスマホのQRコードを\nカメラでうつしてね！")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.gray)
                        
                        // カメラのプレビューエリア（ZStack構造）
                        ZStack {
                            Rectangle()
                                .fill(Color.black.opacity(0.8))
                                .frame(width: 280, height: 280)
                                .cornerRadius(24)
                            
                            // 読み取り枠
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: "4ECDC4"), lineWidth: 4)
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
        }
    }
    
    // MARK: - 🌟 100%確実にQRコード画像を生成するSwift関数
    /// 文字列からQRコードのUIImageを生成する（iOS標準機能のみ）
    func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        // iOS標準の「CIQRCodeGenerator」フィルターを呼び出す
        let filter = CIFilter.qrCodeGenerator()
        
        // 文字列をData型（UTF-8）に変換してフィルターに入力
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // 誤り訂正レベルを「H（最高レベル：30%の汚れでも読める）」に設定（子供の指が写っても読みやすくするため）
        filter.setValue("H", forKey: "inputCorrectionLevel")

        // フィルターから画像を出力
        if let outputImage = filter.outputImage {
            // CIImageをUIImageに変換して返却
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
    
    /// トークンの更新処理（シミュレータのJavaScript版と同じロジック）
    func updateQRToken() {
        let timestamp = Int(Date().timeIntervalSince1970 / 60) // 1分ごとに変わる数値
        // 実際はここにログイン中のユーザーIDなどを埋め込みます
        self.qrTokenString = "KM-sota_01-\(timestamp)"
    }
}

// MARK: - カラーコード(Hex)をSwiftUIで簡単に扱うための拡張
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

// MARK: - プレビュー用
struct QRCheckView_Previews: PreviewProvider {
    static var previews: some View {
        QRCheckView()
    }
}
