# Text Style Tokens

## Goal
- 画面ごとの `Font.TextStyle` 直接指定を減らし、`Theme` 配下の語彙でタイポグラフィを統一する。
- View は「どのサイズにするか」ではなく「どの役割のテキストか」で指定する。
- 数値表示や補助情報も含めて、再利用できる最小限のトークンに寄せる。

## Token set
- `screenTitle`
  - 画面最上部のタイトル、または画面内で最も大きい短文の強調表示。
- `sectionTitle`
  - カード見出し、主要セクション見出し。
- `sectionLabel`
  - 入力グループ名、項目ラベル、軽い見出し。
- `itemTitle`
  - カード内タイトル、選択肢ラベル、短い CTA ラベル。
- `body`
  - 本文、説明文、通常の入力補助文。
- `supporting`
  - 注記、補足、メタデータ。
- `supportingStrong`
  - バッジ、チップ、短い補助情報の強調。
- `metricValue`
  - カード内の主要数値、短い強調値。
- `heroValue`
  - タイマーやヒーロー領域の大きい数値。モノスペース数字を前提とする。

## Usage rules
- `Text` のフォント指定は原則 `AppDesignTokens.Typography` のトークン経由で行う。
- 基本の適用 API は `.appTextStyle(...)` とし、View 側で `font(...)` を直接書かない。
- 色はタイポグラフィトークンに含めず、既存の `AppDesignTokens.Colors` を継続利用する。
- `Image(systemName:)` のサイズ調整はテキストトークンの対象外とし、必要に応じて個別指定を許容する。
- 既存トークンで表現できない新しい役割が必要な場合は、先にこの文書と `rules/ios-app-rules.md` のルールを更新してから追加する。

## Implementation shape
- `Theme` にトークンの定義値を持つ `Token` を置く。
- `Font.TextStyle` ベースで表現できるものは Dynamic Type に追従する。
- `heroValue` のような特殊ケースだけ固定サイズ指定を許容する。
- トークンは `Text` 以外にも `Label` や `TextEditor` へ再利用できるよう `ViewModifier` 経由で適用する。
