# Development Flow

1. `design-docs/product-vision.md` で要件を更新
2. 影響する設計（`design-docs/architecture.md`）を更新
3. 仕様変更がある場合は `rules/ios-app-rules.md` を同時更新
4. 実装（最小差分、レイヤ境界を維持）
5. テスト追加（Domain / UseCase / Persistence を優先）
6. ローカル確認（ビルド / テスト / 主要フロー動作）
7. PR 作成（変更内容・確認手順・懸念点を記載）

## Recommended implementation order
1. Domain model と Repository protocol を固定
2. UseCase と AppStore の依存注入を整備
3. SwiftData Entity / Repository 実装
4. UI から UseCase 経由で保存・取得を接続
5. テストとカバレッジ確認

## Test strategy
- 挙動リスクの高い箇所（計算ロジック、永続化マッピング、削除/再利用フロー）を優先してテストする。
- カバレッジは 90% を目標にするが、意味の薄い網羅テストは追加しない。
- 目標に届かない場合は、どの未カバー経路を意図的に除外したかを PR に明記する。

## Definition of Done
- 要件を満たしている
- `design-docs/` と `rules/` の更新が反映されている
- 影響範囲の説明がある
- 有効なテストが追加され、結果が共有されている
