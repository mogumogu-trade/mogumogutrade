import SwiftUI

// MARK: - メインの画面
struct BetView: View {
    // 選択できる給食メニューと残り人数のデータ
    let menuItems = ["揚げ\nパン", "プリン", "ゼリー"]
    let stocks = [2, 1, 3]
    
    // 現在の状態を管理する変数たち
    @State private var currentIndex = 0
    @State private var myPoints = 500
    @State private var betAmountString = ""
    @State private var lastBetAmount = 0 // 負けた時に返すポイントを覚えておく
    
    // 画面を切り替えるためのスイッチ ("bet", "wait", "win", "lose" の4つの状態)
    @State private var screenState = "bet"
    
    // アニメーション用のスイッチ
    @State private var isRotating = false  // 砂時計用
    @State private var isFloating = false  // 王冠フワフワ用
    @State private var isShining = false   // ホログラムのキラキラ用
    @State private var isGlitching = false // グリッチエフェクト用
    @State private var scanlineOffset: CGFloat = -50 // スキャンライン用
    
    // MARK: - デザイン用の色定義
    let appBgColor = Color(red: 0.95, green: 0.96, blue: 0.98)       // アプリ背景（薄い青みグレー）
    let boardBorderColor = Color(red: 0.47, green: 0.33, blue: 0.28) // ボードの枠（茶色）
    let boardInnerColor = Color(red: 0.93, green: 0.93, blue: 0.93)  // ボードの面（グレー）
    let darkTextColor = Color(red: 0.18, green: 0.18, blue: 0.18)    // 共通の文字色（濃いグレー）
    
    let colorBet = Color(red: 1.0, green: 0.58, blue: 0.53)   // ふせん：コーラルピンク
    let colorWait = Color(red: 0.65, green: 0.95, blue: 0.82)  // ふせん：ミントグリーン
    let colorWin = Color(red: 1.0, green: 0.85, blue: 0.40)    // ふせん：イエローオレンジ
    let colorLose = Color(red: 0.75, green: 0.85, blue: 0.95)  // ふせん：ブルーグレー

    var body: some View {
        ZStack {
            // アプリ全体の背景
            appBgColor.ignoresSafeArea()
            
            VStack {
                // メインのボード部分

                ZStack {
                    // 外枠（茶色）
                    RoundedRectangle(cornerRadius: 30)
                        .fill(boardBorderColor)
                    
                    // 内側のボード面（グレー）
                    RoundedRectangle(cornerRadius: 25)
                        .fill(boardInnerColor)
                        .padding(10)
                    
                    // 状態に合わせて「ふせん」が切り替わる
                    if screenState == "bet" {
                        bettingScreen()
                    } else if screenState == "wait" {
                        waitingScreen()
                    } else if screenState == "win" {
                        winScreen()
                    } else if screenState == "lose" {
                        loseScreen()
                    }
                }
                .frame(maxHeight: 620)
                .padding(.horizontal, 20)
                
                // 【デバッグ用】先生の操作テストパネル

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
        VStack(spacing: 20) {
            Text("欲しいものを\nゲットしよう！")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            
            HStack {
                Text("持っているポイント: \(myPoints) P")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(darkTextColor)
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
                        .frame(width: 40, height: 40).background(Color.white.opacity(0.3)).cornerRadius(12)
                }
                
                ZStack {
                    Circle().strokeBorder(Color.white, lineWidth: 4).background(Circle().fill(Color.white.opacity(0.2))).frame(width: 90, height: 90)
                    Text(menuItems[currentIndex])
                        .font(.system(size: 18, weight: .heavy, design: .rounded)).foregroundColor(.white).multilineTextAlignment(.center)
                    Text("残り\(stocks[currentIndex])人")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(colorBet)
                        .padding(.horizontal, 8).padding(.vertical, 4).background(Color.white).cornerRadius(10)
                        .offset(x: 35, y: -40)
                }
                
                Button(action: {
                    if currentIndex == menuItems.count - 1 { currentIndex = 0 } else { currentIndex += 1 }
                    betAmountString = ""
                }) {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 20)).foregroundColor(.white)
                        .frame(width: 40, height: 40).background(Color.white.opacity(0.3)).cornerRadius(12)
                }
            }
            
            VStack(spacing: 5) {
                Text("ベットする額を入れてね")
                    .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                
                HStack {
                    TextField("0", text: $betAmountString)
                        .keyboardType(.numberPad).multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(darkTextColor)
                        .padding(.vertical, 10).background(Color.white).cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 3))
                    Text("P").font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                }
                .padding(.horizontal, 50)
                
                let currentBet = Int(betAmountString) ?? 0
                if currentBet > myPoints {
                    Text("持っているポイントより多いよ！").font(.system(size: 12, weight: .bold)).foregroundColor(.yellow).padding(.top, 5)
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
                lastBetAmount = currentBetAmount
                betAmountString = ""
                screenState = "wait"
            }) {
                Text("これでベットする！")
                    .font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.white)
                    .padding(.horizontal, 25).padding(.vertical, 15)
                    .background(isValidBet ? darkTextColor : Color.gray).cornerRadius(15)
            }
            .disabled(!isValidBet)
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorBet).cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25) // ピンを消したので余白だけ確保
    }
    
    // -----------------------------------
    // 画面2：待機中（ドキドキ）画面
    // -----------------------------------
    @ViewBuilder
    func waitingScreen() -> some View {
        VStack(spacing: 30) {
            Text("ベット完了！")
                .font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(.white)
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(darkTextColor).cornerRadius(20)
                .rotationEffect(.degrees(-3))
            
            Image(systemName: "hourglass")
                .font(.system(size: 80)).foregroundColor(darkTextColor)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    // クルクル回るアニメーション
                    withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                    
                    // 3秒後に自動で結果判定を行う
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if screenState == "wait" {
                            // ダミーの判定（50%の確率で勝敗を決める）
                            let isWin = Bool.random()
                            if isWin {
                                screenState = "win"
                            } else {
                                // 負けた場合はポイントを返す
                                myPoints += lastBetAmount
                                screenState = "lose"
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
            
            VStack(spacing: 5) {
                Text("先生が締め切るまで")
                Text("しずかに待ってね… 🤫")
            }
            .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(darkTextColor)
            .padding(.horizontal, 25).padding(.vertical, 15).background(Color.white).cornerRadius(15)
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorWait).cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
    
    // -----------------------------------
    // 画面3-A：結果発表 WIN
    // -----------------------------------
    @ViewBuilder
    func winScreen() -> some View {
        ZStack {
            // ふせんの背景
            colorWin.cornerRadius(15)
            
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
            .clipShape(RoundedRectangle(cornerRadius: 15))
            
            VStack(spacing: 15) {
                Text("GET!!")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(darkTextColor)
                
                ZStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .padding(.top, 25)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(darkTextColor)
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
                    .foregroundColor(darkTextColor)
                
                VStack(spacing: 5) {
                    Text("消費ポイント")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                    Text("- \(lastBetAmount) P")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                }
                .frame(width: 200)
                .padding(.vertical, 15)
                .background(Color.white)
                .cornerRadius(15)
                .padding(.top, 5)
                
                Button(action: resetGame) {
                    Text("次のゲームへ")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(darkTextColor).cornerRadius(12)
                }
                .padding(.top, 5)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
    
    // -----------------------------------
    // 画面3-B：結果発表 LOSE (グリッチ・エラー版)
    // -----------------------------------
    @ViewBuilder
    func loseScreen() -> some View {
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
                    .foregroundColor(darkTextColor)
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 0.1).repeatForever(autoreverses: true)) {
                    isGlitching.toggle()
                }
            }
            
            // 2. アイコン
            Image(systemName: "heart.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(darkTextColor)
                .rotationEffect(.degrees(-10))
                .padding(.vertical, 10)
            
            // 3. メッセージ
            Text("落札に失敗しました。")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(darkTextColor)
                .tracking(1)
            
            // 4. ポイントカード（上から下へ流れるスキャンライン）
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                
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
                
                VStack(spacing: 5) {
                    Text("返還ポイント")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.gray)
                    Text("減りません")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(darkTextColor)
                }
                .padding(.vertical, 15)
            }
            .frame(width: 200, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(.top, 10)
            
            Button(action: resetGame) {
                Text("ポイントを受け取る")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(darkTextColor).cornerRadius(12)
            }
            .padding(.top, 5)
        }
        .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorLose).cornerRadius(15)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 2, y: 4)
        .padding(25)
    }
    
    // -----------------------------------
    // アニメーションのリセットと最初の画面に戻る関数
    // -----------------------------------
    func resetGame() {
        screenState = "bet"
        isRotating = false
        isFloating = false
        isShining = false
        isGlitching = false
    }
    
    // -----------------------------------
    // テスト用の小さいボタンを作る部品
    // -----------------------------------
    func testButton(title: String, stateName: String) -> some View {
        Button(action: {
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
    BetView()
}
