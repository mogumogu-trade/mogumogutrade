import SwiftUI

// MARK: - メインの画面
struct ContentView: View {
    // 選択できる給食メニューと残り人数のデータ
    let menuItems = ["揚げ\nパン", "プリン", "ゼリー"]
    let stocks = [2, 1, 3]
    
    // 現在選ばれているメニューの番号（0からスタート）
    @State private var currentIndex = 0
    @State private var myPoints = 500    // ★追加：自分の持っている完食ポイント
    @State private var betAmountString = "" // ★変更：キーボード入力用の文字
    
    var body: some View {
        // --- ★iPhone向けの設定：一番外側に画面全体の背景を追加 ---
        ZStack {
            Color(red: 0.98, green: 0.95, blue: 0.90) // 薄いクリーム色の背景
                .ignoresSafeArea() // 画面の端（セーフエリア）まで塗りつぶす
            
            // ここから下が、今までのカード部分です
            // ZStackは、奥から手前へパーツを重ねる箱です
            ZStack {
                // 1. 一番奥：チョコ色の大きな枠
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.brown)
                
                // 2. その上：ピンクの背景
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.pink.opacity(0.3))
                    .padding(10) // チョコ枠が見えるように隙間をあける
            
            // 3. 一番手前：クリーム色の四角いボックス（この中に文字やボタンを置く）
            VStack(spacing: 20) {
                
                // --- タイトル ---
                Text("欲しいものを\nゲットしよう！")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.brown)
                
                // --- ★追加：持っているポイントの表示 ---
                HStack {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.orange)
                    Text("持っているポイント: \(myPoints) P")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.brown)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(20)
                
                // --- メニューを選ぶ部分（左ボタン ＋ アイコン ＋ 右ボタン） ---
                HStack(spacing: 15) {
                    
                    // 左矢印ボタン
                    Button(action: {
                        // 左ボタンを押したときの動き
                        if currentIndex == 0 {
                            // 最初のメニューだったら、一番最後に移動する
                            currentIndex = menuItems.count - 1
                        } else {
                            // それ以外は1つ前に戻る
                            currentIndex -= 1
                        }
                        betAmountString = "" // ★変更：アイテムを変えたら入力欄をリセット
                    }) {
                        Image(systemName: "arrowtriangle.left.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.orange) // オレンジ色のボタン
                            .cornerRadius(12)         // 角を丸くする
                    }
                    
                    // 真ん中のメニューアイコン
                    ZStack {
                        // ピンク色の丸い枠
                        Circle()
                            .strokeBorder(Color.pink, lineWidth: 5)
                            .background(Circle().fill(Color.white))
                            .frame(width: 90, height: 90)
                        
                        // メニューの名前
                        Text(menuItems[currentIndex])
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(.pink)
                            .multilineTextAlignment(.center)
                        
                        // 右上の「残り○人」バッジ
                        Text("残り\(stocks[currentIndex])人")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.brown)
                            .cornerRadius(10)
                            .offset(x: 35, y: -40) // 右上にずらす
                    }
                    
                    // 右矢印ボタン
                    Button(action: {
                        // 右ボタンを押したときの動き
                        if currentIndex == menuItems.count - 1 {
                            // 最後のメニューだったら、一番最初に戻る
                            currentIndex = 0
                        } else {
                            // それ以外は1つ次に進む
                            currentIndex += 1
                        }
                        betAmountString = "" // ★変更：アイテムを変えたら入力欄をリセット
                    }) {
                        Image(systemName: "arrowtriangle.right.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }
                
                // --- ★変更：ベット額を入力する部分（キーボード入力） ---
                VStack(spacing: 5) {
                    Text("ベットする額を入れてね")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.brown)
                    
                    HStack {
                        TextField("0", text: $betAmountString)
                            .keyboardType(.numberPad) // 数字だけのキーボードを出す
                            .multilineTextAlignment(.center)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundColor(.pink)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.pink, lineWidth: 3)
                            )
                        
                        Text("P")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.brown)
                    }
                    .padding(.horizontal, 50)
                    
                    // 持っているポイントを超えたときの警告メッセージ
                    let currentBet = Int(betAmountString) ?? 0
                    if currentBet > myPoints {
                        Text("持っているポイントより多いよ！")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    } else {
                        // 高さ合わせのための透明な文字（レイアウトがガタガタしないように）
                        Text(" ")
                            .font(.system(size: 12))
                            .padding(.top, 5)
                    }
                }
                // 入力内容が変わったときのチェック
                .onChange(of: betAmountString) { oldValue, newValue in
                    // 数字以外が入力されたら消す（変な記号の入力防止）
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if filtered != newValue {
                        betAmountString = filtered
                    }
                }
                .padding(.vertical, 10)
                
                // --- メインのアクションボタン ---
                // 入力された文字を数字に変換する（失敗したら0にする）
                let currentBetAmount = Int(betAmountString) ?? 0
                // 0より大きくて、かつ自分のポイント以下のときだけ正しいと判定
                let isValidBet = currentBetAmount > 0 && currentBetAmount <= myPoints
                
                Button(action: {
                    let currentMenuName = menuItems[currentIndex].replacingOccurrences(of: "\n", with: "")
                    print("\(currentMenuName) に \(currentBetAmount) P ベットしました！")
                    
                    // ★追加：持っているポイントから入力した額を引く
                    myPoints -= currentBetAmount
                    
                    // ★追加：ベットが終わったら入力欄を空っぽに戻す
                    betAmountString = ""
                }) {
                    Text("これでベットする！")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 15)
                        .background(isValidBet ? Color.pink : Color.gray) // 正しい額の時だけピンクにする
                        .cornerRadius(15)
                }
                .disabled(!isValidBet) // ★変更：正しくない時は押せないようにする
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // RGBの数字を使って、少し黄色っぽいクリーム色を作る
            .background(Color(red: 1.0, green: 0.98, blue: 0.92))
            .cornerRadius(20)
            .padding(20) // クリーム色ボックスの周りの隙間
            }
            // --- ★iPhone向けの設定：カードのサイズを自動調整 ---
            .padding(.horizontal, 20) // 画面の左右に20ずつ余白を作る
            .frame(maxHeight: 600)
        }
        // ★追加：キーボードを閉じるための設定（画面のどこかを触ったらキーボードを隠す）
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

#Preview {
    ContentView()
}
