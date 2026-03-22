# Architecture

## Target
- iOS app using SwiftUI + Observation Framework (`@Observable`)
- Xcode 26.3+
- Local persistence with SwiftData

## Core domain models
- **Bean**
  - 豆プロファイル（豆名 / 焙煎度 / 購入店名(任意) / 購入日(既定値あり) / 産地(任意) / プロセス(任意) / 焙煎日(任意) / URL(任意) / メモ(任意)）
- **BrewInput**
  - `coffeeDose`, `brewRatio`, `tasteProfile`, `roastLevel`, `grindSize`
- **BrewPlan / PourStep**
  - 6投分の注湯量、開始時刻、待機秒数、推奨湯温、総湯量
- **BrewLog**
  - `date`, `bean`, `input`, `plan`, `ratings`, `memo`, `actualBrewSeconds`

## Layers (Clean Architecture oriented)
```text
App/
  FourSixCoffeeApp.swift
  AppDependencies.swift
LiveActivity/
  BrewSessionLiveActivityAttributes.swift
  BrewSessionLiveActivityPayloadBuilder.swift
  BrewSessionLiveActivityManager.swift
Features/
  ... SwiftUI views + @Observable feature models
Theme/
  AppDesignTokens.swift
Application/
  AppStore.swift
  UseCases/
    BeanUseCase.swift
    BrewLogUseCase.swift
Domain/
  Models/
    BrewModels.swift
  Repositories/
    BeanRepository.swift
    BrewLogRepository.swift
  Services/
    BrewPlanner.swift
Infrastructure/
  Persistence/
    SwiftData/
      Entities/
        BeanEntity.swift
        BrewLogEntity.swift
      Repositories/
        SwiftDataBeanRepository.swift
        SwiftDataBrewLogRepository.swift
      PersistenceStack.swift
Preview/
  SampleData.swift
WidgetExtension/
  BrewSessionLiveActivityWidget.swift
```

## Dependency rules
1. `Features` は `Application` の公開インターフェースを使う。
2. `Application` は `Domain` の protocol（Repository）に依存する。
3. `Infrastructure` が `Domain` protocol を実装する。
4. `Domain` は SwiftUI / SwiftData へ依存しない。
5. UI の色・フォントは `Theme` のデザイントークン経由で参照する。

## Data flow
1. View から Store（`@Observable`）にイベントを渡す。
2. Store が UseCase を呼び、入力検証とユースケース実行を行う。
3. UseCase が Repository protocol 経由で読み書きする。
4. SwiftData Repository が Entity と Domain model を相互変換する。
5. Store が state を更新し、View が再描画される。

### Home planner UI mapping
- 既存 `BrewInput` / `BrewPlan` をそのまま使い、データ構造は変更しない。
- 画面のカードごとの責務:
- 入力カード: `coffeeDose`, `tasteProfile`, `grindSize(=濃度プリセット)`, `roastLevel`
- 算出結果カード: `ratio`, `totalWater`, `recommendedTemperature`, `estimatedTotalSeconds`, 推奨 `grindSize`
- レシピカード: `steps[0...]`
- 豆量の増減操作は View から値を直接組み立てず、`AppStore` の更新メソッド経由で行う。
- プランナー内の増減ボタンは最小 44pt 四方のタップ領域を確保し、押下直後に数値再計算が UI へ反映されることを前提とする。
- 比率は入力UIとして直接編集せず、`coffeeDose / tasteProfile / grindSize / roastLevel` から導出した結果を表示する。
- 濃度プリセットは UI 上は `薄め / 普通 / 濃い` として見せ、内部では `grindSize` に対応づける。

### Brew assistant UI mapping
- 既存 `BrewPlan` / `BrewSessionModel` の状態をそのまま使い、ロジック変更なしで視覚表現を更新する。
- 画面セクションとデータ対応:
  - メインタイマー: `secondsToNextStep(in:)`, `currentStep(in:)`, `elapsedSeconds`
  - 次アクションカード: `currentStep(in:)`, `secondsToNextStep(in:)`, `elapsedSeconds`
  - スケジュール: `steps`, `stepStatus(for:)`
  - 保存レビュー: `tasteFeedback`, `strengthFeedback`, `overallFeedback`, `note`
  - 簡易レビューの 3 項目は保存時に既存 `TasteRatings` へマッピングして後方互換を保つ
- `BrewSessionModel` は View が複数値をその場で組み立てなくて済むよう、`次の累計目標g` と `今回足すg` を含む表示用 helper を提供する。
- 最終投では `次の累計目標g` を総湯量として扱い、追加注湯がない状態を明示する。

### Beans UI mapping
- 一覧カードは `name`, `roastLevel` を主表示にし、`shopName` は未入力なら省略可能とする。
- 追加フローは `name`, `roastLevel` を主入力とし、`shopName`, `purchasedAt`, `origin`, `process`, `roastDate`, `referenceURL`, `notes` はオプションセクションへ移す。
- 詳細遷移は既存 `BeanProfileView` を利用し、一覧側のレイアウトのみ更新する。

### Brew logs UI mapping
- `BrewLog` の既存項目（`bean`, `date`, `input`, `plan`, `memo`, `ratings`, `actualBrewSeconds`）をカード表示へ投影する。
- 履歴カードでは `ratings` の生値よりも、簡易レビュー由来の要約を先に見せる。
- 再利用操作（`store.apply(log:)`）と削除操作（`store.deleteLogs`）は既存ロジックを維持する。
- 空状態表示のみUI変更し、状態判定は `store.brewLogs.isEmpty` を継続利用する。

### Settings UI mapping
- 設定値は既存 `AppStore` の `preferredUnit` と `enableStepHaptics` を直接バインドする。
- 情報カードは固定表示（バージョン、プラン計算）で、既存表示内容を維持する。

## Live Activity flow
1. `BrewSessionModel` がタイマー状態（経過秒、現在ステップ、稼働中フラグ）を保持する。
   - 稼働中は開始基準時刻を保持し、`Date` 差分から経過秒を再計算してバックグラウンド復帰後も追従する。
   - 復帰時の同期で完了秒数に達していた場合は、その場でセッション停止と Live Activity 終了を行う。
2. `BrewSessionLiveActivityPayloadBuilder` が `BrewPlan + タイマー状態` から表示用 state を構築する（純粋関数）。
   - `BrewSessionActivityAttributes.ContentState` は `ActivityKit` に永続化されるため、項目追加時も旧 payload を decode できる後方互換を維持する。
3. `BrewSessionLiveActivityManager` が `ActivityKit` へ start/update/end を委譲する。
4. Widget Extension（`ActivityConfiguration`）がロック画面/ダイナミックアイランドに
   「次まで秒数 / 次の累計g / 今回足すg / 何投目」を表示する。

### Live Activity UI mapping
- Live Activity は `BrewAssistantView` の視覚言語を継承し、深いブラウン基調の背景、ティールの進捗アクセント、オレンジの注湯量アクセントを使う。
- Live Activity の主情報は「次に注ぐまでの残り時間」で、次点として「現在の投数」と「次に注ぐ量」を置く。
- g情報は `次に足す量` よりも `次の累計目標g` を主表示とし、差分gは補助ラベルで併記する。
- 現在情報（`第N投`）と次情報（`次は第N投` / `次の累計g` / `今回+g`）は文言を分け、同一の塊に混在させない。
- ロック画面では高さ 160pt 制約を前提に、大きいカウントダウンを主役にし、その周囲へ `現在の投数`、`次の累計g`、`今回+g` を短く配置する。
- Dynamic Island Expanded は center にまとめて「残り時間」と「次の情報」を左右で配置する。
- Dynamic Island Compact / Minimal は「現在の投数」と「次までの残り時間」を最優先にし、g情報は短い累計表記を優先する。
- Live Activity 用の配色・角丸・タイポグラフィは Widget Extension と App の両 target から参照できる共有トークンに切り出し、重複定義を避ける。

## Persistence policy
- Bean と BrewLog を SwiftData に保存する。
- `BrewLog` は `beanID` を保持し、豆削除時はログを残して参照のみ `nil` 扱いにする。
- `BrewLog` の複合構造（`BrewInput`, `BrewPlan`, `TasteRatings`）は JSON エンコードで保存する。
- Bean の購入日は既定値を持ち、購入店名は空文字を許容する。URL は保存前に `http/https` の絶対URLとして妥当性を検証する。

## Testing policy
- Domain service（`BrewPlanner`）は純粋関数としてテストする。
- UseCase は in-memory repository で分岐をテストする。
- SwiftData repository は in-memory `ModelContainer` で永続化挙動をテストする。
- Live Activity は `ActivityKit` 呼び出し自体を直接テストせず、payload 構築ロジックと
  `BrewSessionModel` からの連携（開始/更新/終了）をユニットテストする。
- 目標は高カバレッジ（90%）だが、実効性を損なう過剰なテストは避ける。
