# Architecture (MVP)

## Target
- iOS app using SwiftUI + Observation Framework (`@Observable`)
- Xcode 26.3+

## Domain models
- **BrewInput**
  - `coffeeDose`, `tasteProfile`, `roastLevel`, `grindSize`
- **BrewPlan**
  - `totalWater`, `recommendedTemperature`, `steps(1...6)`
- **PourStep**
  - `index`, `amountGrams`, `startSecond`, `waitSeconds`, `phase`
- **BrewLog**
  - `date`, `input`, `plan`, `memo`, `ratings`

## Layers
```text
Features/
  Home/              // 今日の推奨プランと直近ログ
  BrewAssistant/     // 6投タイマーと進行ガイド
  BrewLogs/          // 履歴一覧と再利用
  Beans/             // 豆管理(最小)
  Settings/          // アプリ設定(最小)
Models/
  AppStore.swift     // @Observable, app-wide state
  BrewModels.swift   // Domain model definitions
  BrewPlanner.swift  // Pure calculation logic
Preview/
  SampleData.swift
```

## State strategy
- グローバル状態は `AppStore` で一元管理し `@Observable` で配信する。
- 画面は `@Environment(AppStore.self)` で状態を取得し、描画を宣言的に保つ。
- タイマー進行など画面ローカルな可変状態は Feature 内モデルで保持する。

## Data flow
1. Planner入力を `AppStore.currentInput` に反映。
2. `BrewPlanner` が `BrewPlan` を算出し `AppStore.currentPlan` に保持。
3. Assistant が `currentPlan.steps` を使って6投タイマーを進行。
4. 抽出終了後、メモと評価を `BrewLog` として保存。
5. History から任意ログを選択すると `currentInput` を復元し再計算する。

## Notes
- 4-6計算ロジックは副作用なしの関数にしてUIから分離する。
- 補正係数（味方向/焙煎度/挽き目）は `BrewPlanner` に集約し、変更点を追跡しやすくする。
