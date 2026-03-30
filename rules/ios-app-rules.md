# iOS App Rules

## Architecture
- 画面は SwiftUI を基本とする。
- View の状態は Observation Framework（`@Observable`）で管理する。
- クリーンアーキテクチャを意識し、`Domain -> Application -> Infrastructure` の依存方向を守る。
- View から SwiftData を直接呼ばず、UseCase / Repository 経由でアクセスする。
- 4-6はアプリ全体の前提にせず、1つのプリセットとして扱う。
- 新しい抽出方式を追加する際は、if文で画面や Domain service を増やす前に、既存の `BrewRecipe` スキーマで表現できるかを確認する。
- Domain model には Observation / TCA / SwiftData 固有型を持ち込まない。
- 既存の抽出ガイド、ログ、Live Activity はリニューアル対象として扱い、別機能として作り直さない。

## Recipe schema
- レシピは `注湯 / 流量 / 温度 / 攪拌 / フェーズ` を基本要素として表現する。
- 投数を固定値で前提化しない。6投固定の配列長や enum 命名を新規追加しない。
- 大会レシピや独自レシピはコード分岐ではなくプリセットデータとして追加する。
- Recipe 永続化では `schemaVersion` を必ず持たせ、payload互換性を壊す変更は移行方針を先に文書化する。
- 4-6由来の `味を前半で制御する` といった概念は preset metadata や generator layer に閉じ込め、コアスキーマへ直書きしない。
- `Quick Brew` が返す結果も同じ `BrewRecipe` スキーマに正規化し、専用の別モデルを増やさない。

## Product modes
- UI の入口は `Quick Brew` と `Research` に分ける。
- `Quick Brew` は少数入力でおすすめレシピを返す最短導線にする。
- `Research` は phase / pour / flow / temperature / agitation を直接扱う設計導線にする。
- `Quick Brew` から Research へ降りられるようにし、逆に Research の複雑さを Quick Brew に持ち込まない。

## Persistence
- Bean / Recipe / BrewLog は SwiftData に保存する。
- Bean は最小入力で登録できることを優先し、「豆名」「焙煎度」を主入力とする。店名は空文字を許容し、購入日は既定値を持たせる。
- URL は任意入力だが保存時に `http/https` の絶対URL形式を検証する。
- 抽出ログ（BrewLog）は Bean と Recipe の両方に紐づけて参照できる状態を維持する。
- 永続化エラーは握りつぶさず、呼び出し元へ伝播または UI で扱える形に変換する。
- Domain model と SwiftData Entity の変換責務は Repository 実装に集約する。
- Recipe の内部構造は MVP では JSON payload 保存を優先し、Entity を細かく分けすぎない。

## Coding
- 新規機能は最小単位で追加する。
- 命名は「役割が分かる英語名」に統一する。
- 1ファイルに役割を詰め込みすぎない。
- 算出ロジックとレシピ解決ロジックは副作用なしの関数として Domain 層に置く。
- 画面の色・フォントは `Theme` のデザイントークンを優先し、View内に色コードを直接書かない。
- テキストスタイルは役割ベースのトークンを使い、`Text` に対して `font(...)` を直接書かない。
- タイポグラフィの新規バリエーションが必要な場合は、先に `design-docs/text-style-tokens.md` とこのルールを更新してから追加する。
- 抽出ガイドの UI は `次までの残り時間` を最優先にし、g情報は `次の累計目標g` を主表示、`今回足すg` を補助表示として扱う。
- 現在のフェーズと次アクションを混在させず、表示責務を分ける。
- Live Activity 実装では、表示用データ整形を純粋関数（Builder）として分離し、`ActivityKit` 依存コードは Manager に閉じ込める。
- Live Activity は既存表示を維持しながら可変レシピへ拡張する。開始・更新・終了の責務分離は崩さない。
- Recipe Editor と Guide UI は、可変投数・可変フェーズ・温度変更ありのケースを前提に設計する。
- `Quick Brew` の入力項目は増やしすぎない。詳細な flow や agitation の編集は Research へ逃がす。

## Testing
- 変更には必ずテストを追加する。
- `Quick Brew` では入力数を絞った推薦ロジックの回帰テストを追加する。
- `RecipeResolver`、preset generator、JSON encode/decode 互換性を優先してテストする。
- 効果的なテストを優先し、目安としてカバレッジ 90% 以上を目指す。
- 目標未達の場合は理由と残リスクを PR に明記する。
- Live Activity の検証では、Widgetの見た目スナップショットよりも state 生成ロジックと開始/更新/終了フローのユニットテストを優先する。
- 抽出ガイドのテストでは、4投 / 5投 / 6投 / 浸漬ハイブリッドの代表ケースを含める。

## Review
- 仕様変更がある場合は `design-docs/` と `rules/` を同時に更新してから PR を作成する。
- PR には「変更内容 / 確認方法 / 懸念点」を明記する。
