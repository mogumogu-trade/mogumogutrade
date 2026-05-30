import SwiftUI

/// トレード機能がまだこのブランチに無いため、アレルギーによる
/// 「ボタン非活性 ＋ 理由表示」UX をプレビューだけで確認するためのデモ画面。
///
/// トレード機能（codex/trade-local-flow）マージ後は、この UX を `TradeView` の
/// 出品/成立ボタンに移植する。本ファイルはその時点で不要。
struct AllergyBlockDemoView: View {
    let foodID: String
    let foodTitle: String
    let recipientAllergens: Set<Allergen>

    private var blockReason: String? {
        AllergyChecker.blockReason(foodID: foodID, recipientAllergens: recipientAllergens)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("「\(foodTitle)」を わたすトレード")
                .font(.system(size: 18, weight: .black, design: .rounded))

            Button {
                // 実際のトレード成立処理（デモなので何もしない）
            } label: {
                Label("この条件で出品する", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(blockReason == nil ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(blockReason != nil)

            if let blockReason {
                Text(blockReason)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
    }
}

#Preview("ブロックされる（牛乳 → 牛乳アレルギー）") {
    AllergyBlockDemoView(foodID: "food-milk", foodTitle: "牛乳", recipientAllergens: [.milk])
}

#Preview("ブロックされない（トマト → 牛乳アレルギー）") {
    AllergyBlockDemoView(foodID: "food-tomato", foodTitle: "トマト", recipientAllergens: [.milk])
}
