# iOS App Rules (Minimal)

## Architecture
- 画面は SwiftUI を基本とする。
- View の状態は Observation Framework で管理する。
- 単一責務を守り、1ファイルに役割を詰め込みすぎない。

## Coding
- 新規機能は最小単位で追加する。
- 命名は「役割が分かる英語名」に統一する。
- ViewModel 相当の型は `@Observable` を優先して検討する。

## Review
- 仕様変更がある場合は `design-docs/` を更新してから PR を作成する。
- PR には実行した確認手順を明記する。
