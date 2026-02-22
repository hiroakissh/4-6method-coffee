# commnd

> NOTE: フォルダ名は依頼どおり `commnd` としています。

Codex 運用で使う「定型コマンド／メモ」を置く場所です。

## 例

### 1) 変更確認
```bash
git status --short --branch
git diff --name-only
```

### 2) 調査
```bash
rg "キーワード" .
```

### 3) PR 用メモ作成
- 変更内容（What）
- 背景（Why）
- 確認方法（How to test）
- 懸念点（Risk）

必要ならこの配下に `pr-template.md` などを追加してください。
