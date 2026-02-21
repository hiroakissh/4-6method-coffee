# AGENT.md

このリポジトリは **SwiftUI + Observation Framework** を使った iOS アプリを想定しています。

## 前提
- Xcode: **26.3 以降**
- 言語: Swift
- UI: SwiftUI
- 状態管理: Observation Framework（`@Observable` など）

## 進め方（最小）
1. `design-docs/` の設計メモを更新してから実装に入る。
2. 仕様変更時は `rules/` と `design-docs/` を同時に更新する。
3. PR には「変更内容 / 確認方法 / 懸念点」を必ず記載する。
4. SwiftUI 実装時は `skills/swiftui-observation/SKILL.md` を参照する。

## プロダクト方針
- 4-6メソッドの抽出を再現しやすくする。
- 豆量(g)と焙煎度(浅/中/深)、味方向(甘め/普通/薄め)から、6投目までの注湯量(g)と時間目安を算出する。
- 抽出記録を残し、次回調整しやすい体験を重視する。

## ディレクトリ
- `rules/`: 開発ルール
- `commnd/`: Codex で使う運用コマンド・テンプレート
- `skills/`: チーム固有スキル定義の置き場
- `design-docs/`: 構成・設計ドキュメント
