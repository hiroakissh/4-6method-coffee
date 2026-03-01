# Development Flow (Minimal)

1. `design-docs/product-vision.md` で要件を更新
2. 影響する設計（`architecture.md`）を更新
3. 仕様変更がある場合は `rules/` も同時更新
4. 実装（最小差分）
5. ローカル確認（ビルド / 主要フロー動作）
6. PR 作成（変更内容・確認手順・懸念点を記載）

## MVP implementation order
1. Planner（6投分の g/時間・湯温算出）
2. Assistant（6投タイマー）
3. Brew Note/History（実測と再利用）

## Definition of Done
- 要件を満たしている
- 影響範囲の説明がある
- ドキュメント更新が反映されている
- 6投タイマーの基本操作（開始/一時停止/再開/リセット）が動作する
