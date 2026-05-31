# auctions（ブラインドオークション）— Firestore 設計メモ

v1 のオークションは、余った人気メニューをクラス内で1つだけ競る簡易ブラインドオークションとして扱う。
在庫は一旦1個固定。入札額や参加状況は締切まで他の生徒に表示しない。

## コレクション

### `classes/{classId}/auctions/{auctionId}`

| key | 例 | 説明 |
|---|---|---|
| `itemName` | "プリン" | 出品メニュー |
| `status` | "open" | open / closed |
| `mealDate` | "2026-05-31" | 給食日 |
| `createdAt` | serverTimestamp | 作成時刻 |
| `updatedAt` | serverTimestamp | 更新時刻 |
| `closedAt` | timestamp | 締切時刻。open の間は未設定 |

### `classes/{classId}/auctions/{auctionId}/bids/{bidId}`

- ドキュメントID: `student-{studentNumber}`
- 同じ生徒は1オークションにつき1入札。締切前は上書き可能。

| key | 例 | 説明 |
|---|---|---|
| `studentNumber` | 12 | 出席番号。主識別子 |
| `studentNickname` | "もぐ" | 表示補助 |
| `amount` | 8 | 入札ポイント |
| `createdAt` | serverTimestamp | 初回入札時刻。同額先着判定に使う |
| `updatedAt` | serverTimestamp | 再入札時刻 |

### `classes/{classId}/auctions/{auctionId}/result/main`

| key | 例 | 説明 |
|---|---|---|
| `roomId` | auctionId | 対象オークション |
| `winner` | map | 落札者。落札者なしの場合は未設定 |
| `closedAt` | timestamp | 締切時刻 |
| `createdAt` | serverTimestamp | 結果作成時刻 |

`winner` は `studentNumber`, `studentNickname`, `bidAmount` を持つ。

### `classes/{classId}/auctionActiveRooms/{mealDate}`

同じクラス・同じ給食日の同時開催を防ぐためのロック用ドキュメント。
開催時は transaction 内でこのドキュメントと現在の room を読み、既存の open room があれば新規作成しない。
締切時は、対象 room がこのドキュメントの `roomId` と一致する場合に `closed` へ更新する。

| key | 例 | 説明 |
|---|---|---|
| `roomId` | auctionId | 現在または直近のオークション |
| `status` | "open" | open / closed |
| `mealDate` | "2026-05-31" | 給食日。ドキュメントIDと同じ |
| `updatedAt` | serverTimestamp | 更新時刻 |
| `closedAt` | timestamp | 締切時刻。closed の場合のみ |

## ポイント

ポイント残高は `pointLedger` の履歴を正としつつ、オークションの同時更新用に
`classes/{classId}/pointBalances/{studentNumber}` をキャッシュ残高として持つ。

- 初回入札時: `pointLedger/auction-fee-{auctionId}-{studentNumber}` に `auctionParticipation` / `-5` を作成し、同じ transaction で `pointBalances` を減算する。
- 再入札時: 参加費は追加消費しない。
- 締切時: 落札者だけ `pointLedger/auction-win-{auctionId}-{studentNumber}` に `auctionWin` / `-bidAmount` を作成し、同じ transaction で `pointBalances` を減算する。
- 二重締切や通信リトライで重複消費しないよう、参加費と落札消費の ledger ID は決定論IDにする。

既存ユーザーなど `pointBalances` が無い場合は、対象生徒の `pointLedger` 合計から初期化してから transaction を行う。

## 締切ルール

1. 先生が締切操作を行う。
2. room を `closed` にし、対象 room が `auctionActiveRooms/{mealDate}` の `roomId` と一致すれば active room も `closed` にする。
3. bids を `amount` 降順、`createdAt` 昇順で並べる。
4. 締切時点の `pointBalances` で `balance >= bidAmount` を満たす最初の1人を winner にする。
5. 最高入札者が残高不足なら次点へ繰り下げる。
6. 払える入札者がいなければ winner なしで結果を作成する。

## 開催ルール

- 同じクラス・同じ給食日で同時に open にできる room は1件だけ。
- 締切後は同じ給食日に次の room を作成できる。
- `auctionActiveRooms/{mealDate}` が open を指していても、実体の room が存在しない、または closed の場合は stale lock とみなして新規作成できる。

## v1 の制限

- 在庫は1個固定。
- 中止機能と参加費返金は未実装。
- Firebase Auth / Security Rules は未導入。現状はクライアント側 transaction で整合性を守る。
