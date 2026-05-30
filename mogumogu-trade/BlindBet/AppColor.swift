import SwiftUI

// MARK: - アプリ全体で使う共通カラー
struct AppColors {
    static let bg = Color(red: 0.95, green: 0.96, blue: 0.98)       // アプリ背景（薄い青みグレー）
    static let boardBorder = Color(red: 0.47, green: 0.33, blue: 0.28) // ボードの枠（茶色）
    static let boardInner = Color(red: 0.93, green: 0.93, blue: 0.93)  // ボードの面（グレー）
    static let darkText = Color(red: 0.18, green: 0.18, blue: 0.18)    // 共通の文字色（濃いグレー）
    
    static let bet = Color(red: 1.0, green: 0.58, blue: 0.53)   // ふせん：コーラルピンク
    static let wait = Color(red: 0.65, green: 0.95, blue: 0.82)  // ふせん：ミントグリーン
    static let win = Color(red: 1.0, green: 0.85, blue: 0.40)    // ふせん：イエローオレンジ
    static let lose = Color(red: 0.75, green: 0.85, blue: 0.95)  // ふせん：ブルーグレー
}
