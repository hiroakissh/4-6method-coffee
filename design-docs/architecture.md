# Architecture

## Target
- iOS app using SwiftUI + Observation Framework (`@Observable`)
- Xcode 26.3+
- Local persistence with SwiftData
- 4-6専用ロジックから、複数抽出方式を扱えるレシピ基盤へ移行する

## Architectural direction
- **Recipe schema first**
  - 先にレシピの正規表現を決め、その後に UI と永続化を合わせる
- **Renew instead of replace**
  - 既存の抽出ガイド、ログ、Live Activity を捨てずに、可変レシピへ拡張する
- **Preset as data**
  - 4-6や大会レシピはコード分岐ではなくデータとして表現する
- **Resolved session timeline**
  - 編集用の `Recipe` と、抽出ガイド用の `SessionPlan` を分ける
- **Framework-agnostic domain**
  - Domain model は Observation / TCA / SwiftData に依存させない

## Core domain models
- **Bean**
  - 既存の豆プロファイルを継続利用する
- **BrewEntryMode**
  - `quick / research`。どの入口から抽出を開始したかを表す
- **BrewRecipe**
  - レシピ全体。器具、比率、出典、フェーズ群を持つ
- **RecipeMetadata**
  - レシピ名、作成者、出典、タグ、プリセット種別
- **QuickBrewRequest**
  - 豆、焙煎度、味方向、杯数などの少数入力
- **BrewPhase**
  - `bloom / extraction / immersion / bypass / finish` などのフェーズ
- **PourAction**
  - 開始時刻、注湯量、累計目標量、流量、注湯位置
- **TemperatureProfile**
  - 一定温度または時系列変化
- **AgitationAction**
  - swirl / stir / tap / none
- **BrewSessionPlan**
  - 抽出ガイド用に展開済みのタイムライン。UI と Live Activity はこれを見る
- **BrewLog**
  - `bean`, `recipe`, `sessionResult`, `ratings`, `memo`, `actualBrewSeconds`

## Suggested Swift model split
```text
Domain/
  Models/
    Bean.swift
    BrewRecipe.swift
    BrewPhase.swift
    PourAction.swift
    TemperatureProfile.swift
    AgitationAction.swift
    BrewSessionPlan.swift
    BrewLog.swift
  Services/
    RecipePresetFactory.swift
    RecipeResolver.swift
    QuickBrewGenerator.swift
    RecipeSuggestionEngine.swift    // later
  Repositories/
    BeanRepository.swift
    RecipeRepository.swift
    BrewLogRepository.swift
Application/
  UseCases/
    BeanUseCase.swift
    RecipeUseCase.swift
    QuickBrewUseCase.swift
    BrewGuideUseCase.swift
    BrewLogUseCase.swift
Features/
  QuickBrew/
  Research/
  RecipeLibrary/
  RecipeEditor/
  BrewGuide/
  BrewLogs/
```

## Canonical recipe schema
```swift
struct BrewRecipe {
    var id: UUID
    var metadata: RecipeMetadata
    var defaults: RecipeDefaults
    var phases: [BrewPhase]
}

struct BrewPhase {
    var id: String
    var type: PhaseType
    var pours: [PourAction]
    var temperature: TemperatureProfile
    var agitation: [AgitationAction]
}

struct PourAction {
    var id: String
    var startSecond: Int
    var amountGrams: Int
    var targetCumulativeGrams: Int
    var flowRate: FlowRate
    var position: PourPosition
}
```

## Recipe representation rules
1. 4-6のような「味 / 濃度」概念は preset metadata や generator input として保持し、コアスキーマには埋め込まない。
2. 抽出ガイドは `BrewSessionPlan` の時系列イベントだけを見て動作し、投数固定の知識を持たない。
3. 温度変化や攪拌は phase-level か action-level に持たせ、UI では同一タイムライン上に表示できるようにする。
4. ハイブリッド抽出は `PhaseType` と `ExtractionMode` で表現し、特定器具の if 文を View に持ち込まない。
5. `Quick Brew` も最終的には同じ `BrewRecipe` を返し、別のレシピ型を増やさない。
6. `Quick Brew / Research` は Recipe の属性ではなく、セッション開始時の context または BrewLog 側で保持する。

## JSON persistence strategy
- Recipe は MVP では **JSON payload + schemaVersion** で保存する
- SwiftData の `RecipeEntity` は以下の責務に絞る
  - `id`
  - `name`
  - `device`
  - `schemaVersion`
  - `isPreset`
  - `sourceSummary`
  - `payloadJSON`
- フェーズや注湯を細かい Entity に分けるのは、検索要件が増えてから検討する
- これにより schema versioning と大会プリセットの差し替えをしやすくする

## Data flow
1. View から Observation Store にイベントを渡す
2. `Quick Brew` では `QuickBrewUseCase` が入力からおすすめ `BrewRecipe` を返す
3. `Research` では `RecipeUseCase` が Recipe の取得・保存・複製を行う
4. `RecipeResolver` が `BrewRecipe` を `BrewSessionPlan` へ展開する
5. `BrewSessionModel` は `BrewSessionPlan` を元にタイマー進行を管理する
6. Repository が JSON payload と Domain model を相互変換する

## Migration strategy from current code
1. **Schema introduction**
   - `BrewRecipe` 系モデルと `RecipeRepository` を追加する
   - 既存 `BrewInput / BrewPlan` は当面残す
2. **Preset adapter**
   - 4-6を `RecipePresetFactory.fourSix()` として再定義する
   - 既存 `BrewPlanner` は 4-6プリセット生成器として縮退させる
3. **Guide migration**
   - `BrewSessionModel` を `BrewSessionPlan` ベースへ切り替える
   - `currentStepIndex` は可変長イベント列に対応させる
   - 既存の Live Activity manager / builder / widget 構成は維持し、payload だけを可変レシピへ対応させる
4. **UI migration**
   - Home を「Quick Brew / Research」の2導線中心へ置き換える
   - Quick Brew は最短入力、Research はレシピライブラリ / エディタ中心にする
   - 抽出ガイド UI は可変投数・温度変更表示に対応する
5. **Legacy cleanup**
   - 6投固定の `PourStep.Phase.balance/strength` と `TasteProfile` 依存を段階的に整理する

## Preset mapping examples
- **4-6**
  - `bloom`, `flavorControl`, `strengthControl`
- **短時間4投**
  - `bloom`, `extraction`
- **浸漬ハイブリッド**
  - `immersion`, `drip`
- **温度変化型**
  - 同一 `extraction` phase 内で `TemperatureProfile.stepwise`

## UI implications
- Home の役割は「1つの 4-6 計算画面」から「Quick Brew / Research の入口」に変える
- Quick Brew は少数入力 + おすすめレシピカードを主役にする
- Research は Recipe Library と Recipe Editor を中心にする
- Brew Guide は以下を固定表示項目として扱う
  - 現在フェーズ
  - 次のアクションまでの残り時間
  - 次の累計g
  - 今回足すg
  - 現在または次の温度
- Live Activity も `BrewSessionPlan` の表示項目だけを参照する
- 既存の表示優先順位である `残り時間 -> 次の累計g -> 今回足すg` は維持する
- 既存ユーザーが違和感なく使えるよう、タイマー開始・停止・終了導線は大きく変えない

## Testing policy
- `QuickBrewGenerator` は入力数を絞ったルールベース生成としてテストする
- `RecipeResolver` と `RecipePresetFactory` を純粋関数として重点テストする
- JSON schema の encode/decode 互換性テストを追加する
- 可変投数、温度変更、攪拌あり、浸漬フェーズありの代表ケースをテストする
- `BrewSessionModel` は 6投固定ケースだけでなく、4投・2フェーズ・温度変化ケースで確認する
