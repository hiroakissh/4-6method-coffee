# iOS App Rules

## Architecture
- 画面は SwiftUI を基本とする。
- View の状態は Observation Framework（`@Observable`）で管理する。
- クリーンアーキテクチャを意識し、`Domain -> Application -> Infrastructure` の依存方向を守る。
- View から SwiftData を直接呼ばず、UseCase / Repository 経由でアクセスする。

## Persistence
- Bean と BrewLog は SwiftData に保存する。
- Bean は「店名」「購入日」を必須項目として保持し、URL は任意入力だが保存時に妥当な形式を検証する。
- 抽出ログ（BrewLog）は Bean プロファイルに紐づけて参照できる状態を維持する。
- 永続化エラーは握りつぶさず、呼び出し元へ伝播または UI で扱える形に変換する。
- Domain model と SwiftData Entity の変換責務は Repository 実装に集約する。

## Coding
- 新規機能は最小単位で追加する。
- 命名は「役割が分かる英語名」に統一する。
- 1ファイルに役割を詰め込みすぎない。
- 算出ロジックは副作用なしの関数として Domain 層に置く。

## Testing
- 変更には必ずテストを追加する（少なくとも1つの失敗経路を含める）。
- 効果的なテストを優先し、目安としてカバレッジ 90% 以上を目指す。
- 目標未達の場合は理由と残リスクを PR に明記する。

## Review
- 仕様変更がある場合は `design-docs/` と `rules/` を同時に更新してから PR を作成する。
- PR には「変更内容 / 確認方法 / 懸念点」を明記する。
