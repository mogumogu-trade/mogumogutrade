import SwiftUI

// MARK: - メインの画面
struct ContentView: View {
    // 選択できる給食メニューと残り人数のデータ
    let menuItems = ["揚げ\nパン", "プリン", "ゼリー"]
    let stocks = [2, 1, 3]
    
    // 現在の状態を管理する変数たち
    @State private var currentIndex = 0
    @State private var myPoints = 500
    @State private var betAmountString = ""
    
    // 画面を切り替えるためのスイッチ ("bet", "wait", "win", "lose" の4つの状態)
    @State private var screenState = "bet"
    
    // アニメーション用のスイッチ
    @State private var isRotating = false  // 砂時計用
    @State private var isFloating = false  // 王冠フワフワ用
    @State private var isShining = false   // ホログラムのキラキラ用
    @State private var isGlitching = false // グリッチエフェクト用
    @State private var scanlineOffset: CGFloat = -50 // スキャンライン用
    
    var body: some View {
        ZStack {
            // アプリ全体の背景（薄いクリーム色）
            Color(red: 0.98, green: 0.95, blue: 0.90).ignoresSafeArea()
            
            VStack {
                // ==========================================
                // メインのカード部分（状態に合わせて中身が切り替わる）
                // ==========================================
                ZStack {
                    if screenState == "bet" {
                        // -----------------------------
                        // 【画面1】ベット入力画面
                        // -----------------------------
                        bettingScreen()
                        
                    } else if screenState == "wait" {
                        // -----------------------------
                        // 【画面2】待機中（ドキドキ）画面
                        // -----------------------------
                        waitingScreen()
                        
                    } else if screenState == "win" {
                        // -----------------------------
                        // 【画面3-A】結果発表：WIN（キャラメル・ホログラム）
                        // -----------------------------
                        winScreen()
                        
                    } else if screenState == "lose" {
                        // -----------------------------
                        // 【画面3-B】結果発表：LOSE（グリッチ・エラー版）
                        // -----------------------------
                        loseScreen()
                    }
                }
                .frame(maxHeight: 600)
                .padding(.horizontal, 20)
                
                // ==========================================
                // 【デバッグ用】先生の操作テストパネル
                // ==========================================
                VStack(spacing: 10) {
                    Text("【先生の操作テスト】")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 15) {
                        testButton(title: "入力", stateName: "bet")
                        testButton(title: "待機", stateName: "wait")
                        testButton(title: "WIN", stateName: "win")
                        testButton(title: "LOSE", stateName: "lose")
                    }
                }
                .padding(.top, 20)
            }
        }
        // タップ時にキーボードを閉じる
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - 各画面のパーツ
    
    // -----------------------------------
    // 画面1：ベット入力画面
    // -----------------------------------
    @ViewBuilder
    func bettingScreen() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30).fill(Color.brown)
            RoundedRectangle(cornerRadius: 25).fill(Color.pink.opacity(0.3)).padding(10)
            
            VStack(spacing: 20) {
                Text("欲しいものを\nゲットしよう！")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.brown)
                
                HStack {
                    Image(systemName: "star.circle.fill").foregroundColor(.orange)
                    Text("持っているポイント: \(myPoints) P")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.brown)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(20)
                
                HStack(spacing: 15) {
                    Button(action: {
                        if currentIndex == 0 { currentIndex = menuItems.count - 1 } else { currentIndex -= 1 }
                        betAmountString = ""
                    }) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .font(.system(size: 20)).foregroundColor(.white)
                            .frame(width: 40, height: 40).background(Color.orange).cornerRadius(12)
                    }
                    
                    ZStack {
                        Circle().strokeBorder(Color.pink, lineWidth: 5).background(Circle().fill(Color.white)).frame(width: 90, height: 90)
                        Text(menuItems[currentIndex])
                            .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundColor(.pink).multilineTextAlignment(.center)
                        Text("残り\(stocks[currentIndex])人")
                            .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 4).background(Color.brown).cornerRadius(10)
                            .offset(x: 35, y: -40)
                    }
                    
                    Button(action: {
                        if currentIndex == menuItems.count - 1 { currentIndex = 0 } else { currentIndex += 1 }
                        betAmountString = ""
                    }) {
                        Image(systemName: "arrowtriangle.right.fill")
                            .font(.system(size: 20)).foregroundColor(.white)
                            .frame(width: 40, height: 40).background(Color.orange).cornerRadius(12)
                    }
                }
                
                VStack(spacing: 5) {
                    Text("ベットする額を入れてね")
                        .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.brown)
                    
                    HStack {
                        TextField("0", text: $betAmountString)
                            .keyboardType(.numberPad).multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.pink)
                            .padding(.vertical, 10).background(Color.white).cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.pink, lineWidth: 3))
                        Text("P").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.brown)
                    }
                    .padding(.horizontal, 50)
                    
                    let currentBet = Int(betAmountString) ?? 0
                    if currentBet > myPoints {
                        Text("持っているポイントより多いよ！").font(.system(size: 12, weight: .bold)).foregroundColor(.red).padding(.top, 5)
                    } else {
                        Text(" ").font(.system(size: 12)).padding(.top, 5)
                    }
                }
                .onChange(of: betAmountString) { oldValue, newValue in
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if filtered != newValue { betAmountString = filtered }
                }
                .padding(.vertical, 10)
                
                let currentBetAmount = Int(betAmountString) ?? 0
                let isValidBet = currentBetAmount > 0 && currentBetAmount <= myPoints
                
                Button(action: {
                    myPoints -= currentBetAmount
                    betAmountString = ""
                    // ベットが終わったら待機画面へ！
                    screenState = "wait"
                }) {
                    Text("これでベットする！")
                        .font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(.white)
                        .padding(.horizontal, 25).padding(.vertical, 15)
                        .background(isValidBet ? Color.pink : Color.gray).cornerRadius(15)
                }
                .disabled(!isValidBet)
            }
            .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 1.0, green: 0.98, blue: 0.92)).cornerRadius(20).padding(20)
        }
    }
    
    // -----------------------------------
    // 画面2：待機中（ドキドキ）画面
    // -----------------------------------
    @ViewBuilder
    func waitingScreen() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30).fill(Color.brown)
            RoundedRectangle(cornerRadius: 25).fill(Color.pink.opacity(0.3)).padding(10)
            
            VStack(spacing: 30) {
                Text("ベット完了！")
                    .font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10).background(Color.pink).cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white, lineWidth: 4))
                    .shadow(color: Color.pink.opacity(0.5), radius: 0, x: 0, y: 5)
                    .rotationEffect(.degrees(-3))
                
                Image(systemName: "hourglass")
                    .font(.system(size: 80)).foregroundColor(Color(red: 0.20, green: 0.83, blue: 0.60))
                    .shadow(color: Color(red: 0.02, green: 0.59, blue: 0.41), radius: 0, x: 0, y: 8)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                    .onAppear {
                        withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                            isRotating = true
                        }
                    }
                    .padding(.vertical, 20)
                
                VStack(spacing: 5) {
                    Text("先生が締め切るまで")
                    Text("しずかに待ってね… 🤫")
                }
                .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(Color(red: 0.47, green: 0.20, blue: 0.06))
                .padding(.horizontal, 25).padding(.vertical, 15).background(Color.white).cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.orange, style: StrokeStyle(lineWidth: 3, dash: [6, 4])))
            }
            .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 1.0, green: 0.98, blue: 0.92)).cornerRadius(20).padding(20)
        }
    }
    
    // -----------------------------------
    // 画面3-A：結果発表 WIN (キャラメル・ホログラム)
    // -----------------------------------
    @ViewBuilder
    func winScreen() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 1.0, green: 0.98, blue: 0.92))
            
            // ホログラムのキラキラ・アニメーション層
            GeometryReader { geometry in
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.8), .clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: geometry.size.width * 2)
                .offset(x: isShining ? geometry.size.width : -geometry.size.width)
                .onAppear {
                    withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                        isShining = true
                    }
                }
            }
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.orange, lineWidth: 3)
            
            VStack(spacing: 15) {
                Text("🌟 タッチの差でゲット！")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15).padding(.vertical, 6)
                    .background(
                        LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(20)
                    .padding(.top, 10)
                
                Text("GET!!")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing)
                    )
                
                ZStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 70))
                        .foregroundColor(Color.orange)
                        .shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 10)
                        .padding(.top, 25)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.pink)
                        .offset(y: isFloating ? -45 : -35)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                isFloating = true
                            }
                        }
                }
                .padding(.vertical, 10)
                
                Text("デザートを獲得したよ！")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brown)
                
                VStack(spacing: 5) {
                    Text("消費ポイント")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.orange)
                    Text("- 150 P")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Color.pink)
                }
                .frame(width: 200)
                .padding(.vertical, 15)
                .background(Color.white)
                .cornerRadius(15)
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(red: 0.98, green: 0.88, blue: 0.28), lineWidth: 2))
                .shadow(color: Color.orange.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.top, 10)
            }
            .padding(20)
        }
        .padding(20)
    }
    
    // -----------------------------------
    // 画面3-B：結果発表 LOSE (グリッチ・エラー版)
    // -----------------------------------
    @ViewBuilder
    func loseScreen() -> some View {
        ZStack {
            // 背景（少し冷たいグレーブルー）
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.97, green: 0.98, blue: 0.99))
            
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(red: 0.80, green: 0.84, blue: 0.88), lineWidth: 3)
            
            VStack(spacing: 20) {
                
                // 1. タイトル：赤と青の影をずらしてグリッチを表現
                ZStack {
                    Text("ERROR")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(Color.pink)
                        .offset(x: isGlitching ? -3 : 2, y: isGlitching ? 1 : -1)
                    
                    Text("ERROR")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(Color.blue)
                        .offset(x: isGlitching ? 3 : -2, y: isGlitching ? -1 : 1)
                    
                    Text("ERROR")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.39, green: 0.45, blue: 0.55))
                }
                .onAppear {
                    // チカチカと激しく動かす
                    withAnimation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true)) {
                        isGlitching.toggle()
                    }
                }
                
                // 2. アイコン：ハートが割れたデザインで失敗を表現
                Image(systemName: "heart.slash.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                    .rotationEffect(.degrees(-10))
                    .padding(.vertical, 10)
                
                // 3. メッセージ：システム風の等幅フォント
                Text("落札に失敗しました。")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.39, green: 0.45, blue: 0.55))
                    .tracking(1) // 文字の間隔を少し開ける
                
                // 4. ポイントカード（上から下へ流れるスキャンライン）
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                    
                    // スキャンラインのアニメーション
                    Rectangle()
                        .fill(Color.black.opacity(0.05))
                        .frame(height: 5)
                        .offset(y: scanlineOffset)
                        .onAppear {
                            scanlineOffset = -50
                            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                scanlineOffset = 100
                            }
                        }
                    
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(red: 0.80, green: 0.84, blue: 0.88), lineWidth: 2)
                    
                    VStack(spacing: 5) {
                        Text("返還ポイント")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.58, green: 0.64, blue: 0.72))
                        Text("減りません")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(Color(red: 0.39, green: 0.45, blue: 0.55))
                    }
                    .padding(.vertical, 15)
                }
                .frame(width: 200, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 15)) // はみ出たスキャンラインを隠す
                .padding(.top, 10)
            }
            .padding(20)
        }
        .padding(20)
    }
    
    // -----------------------------------
    // テスト用の小さいボタンを作る部品
    // -----------------------------------
    func testButton(title: String, stateName: String) -> some View {
        Button(action: {
            // 状態をリセットして画面を切り替える
            screenState = stateName
            isRotating = false
            isFloating = false
            isShining = false
            isGlitching = false
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(screenState == stateName ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(screenState == stateName ? .white : .black)
                .cornerRadius(8)
        }
    }
}

// MARK: - プレビュー
#Preview {
    ContentView()
}
