import Foundation

/// 給食日（"yyyy-MM-dd"）の文字列を扱う共通ユーティリティ。
///
/// トレード・ポイント台帳など「その日」を主キーにする箇所で共有する。
/// 時刻は注入された `Date`（`@Dependency(\.date.now)`）を渡して使うこと。
enum MealDate {
    /// 指定日時のローカル暦における "yyyy-MM-dd" 文字列。
    static func string(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }
}
