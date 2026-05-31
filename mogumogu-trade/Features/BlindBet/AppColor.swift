import SwiftUI

// MARK: - アプリ全体で使う共通カラー
struct AppColors {
    static let bg = Color.white          // みかんクリームから白に戻す
    static let card = Color(red: 1.00, green: 0.99, blue: 0.95)        // やわらかい白
    static let primary = Color(red: 1.00, green: 0.47, blue: 0.12)     // みかんオレンジ
    static let primaryLight = Color(red: 1.00, green: 0.73, blue: 0.31)// はちみつ
    static let accent = Color(red: 0.25, green: 0.72, blue: 0.62)      // ミント
    static let alert = Color(red: 0.94, green: 0.22, blue: 0.18)       // あか
    static let boardBorder = Color(red: 0.65, green: 0.32, blue: 0.13) // ビスケット
    static let boardInner = Color(red: 1.00, green: 0.87, blue: 0.55)  // たまご色
    static let darkText = Color(red: 0.28, green: 0.18, blue: 0.11)    // チョコ文字
    
    static let bet = Color(red: 1.00, green: 0.55, blue: 0.20)   // ふせん：オレンジ
    static let wait = Color(red: 1.00, green: 0.78, blue: 0.38)  // ふせん：はちみつ
    static let win = Color(red: 1.00, green: 0.86, blue: 0.28)   // ふせん：きんいろ
    static let lose = Color(red: 1.00, green: 0.68, blue: 0.48)  // ふせん：サーモン
}
