# pointLedger（完食マイレージ台帳）— Firestore 設計メモ

完食マイレージのポイント台帳に関する Firestore 構造と、将来導入する Security Rules の意図を記録する。
v1 ではクライアント側で検証しているが、AGENTS.md 方針どおり最終的なら安全性は Security Rules で担保する。

## コレクション

`classes/{classId}/pointLedger/{ledgerId}`

- ドキュメントID（完食ポイント）: `meal-{mealDate}-{eaterNumber}` の決定論ID。
  - これにより「同じ生徒は1日1回」「通信リトライ時の重複付与防止」を1つの仕組みで満たす。

### フィールド

| key | 例 | 説明 |
|---|---|---|
| `studentNumber` | 12 | 対象（完食者）の出席番号。主識別子 |
| `studentNickname` | "もぐ" | 表示補助 |
| `amount` | 1 | 符号つき増減。完食=+1 |
| `type` | "mealCompletion" | mealCompletion / auctionWin / teacherCancel |
| `approverNumber` | 8 | 完食を承認した確認者の出席番号（QR由来） |
| `approverNickname` | "はる" | 表示補助 |
| `mealDate` | "2026-05-31" | 給食日 |
| `createdAt` | serverTimestamp | 付与時刻 |

残高は `studentNumber` で絞った `amount` の合計で算出する（直接上書きしない）。

## フロー（v1）

完食者が自分の端末に QR を表示し、確認者が読み取って加点する。
書き込み主体は**確認者**になるため、自分で完食をでっち上げられない。

確認者端末で次を検証してから書き込む（`QRCheckViewModel.validate`）。

1. `classId` が自分のクラスと一致
2. QRの `studentNumber` が自分と異なる（自己承認禁止）
3. 発行から 5 分以内（有効期限）

## 想定 Security Rules（将来 / Firebase Auth 導入後）

現状は未導入。Auth 導入後、概ね以下を意図する。

```
match /classes/{classId}/pointLedger/{ledgerId} {
  // 自分の参加クラスのみ読める
  allow read: if isMemberOf(classId);

  // 完食ポイントの作成は「確認者本人」かつ「自己承認でない」場合のみ
  allow create: if isMemberOf(classId)
    && request.resource.data.type == 'mealCompletion'
    && request.resource.data.amount == 1
    && request.resource.data.approverNumber == callerAttendanceNumber()
    && request.resource.data.studentNumber != callerAttendanceNumber();

  // 残高の改ざん防止のため、更新・削除は不可（取り消しは teacherCancel エントリの追記で表現）
  allow update, delete: if false;
}
```

- ポイント消費（オークション落札）や教員の取り消しは、別途トランザクション／Cloud Functions で整合性を担保する。
- `auctionWin` / `teacherCancel` の作成条件は、それぞれの機能実装時に追加する。
