# Architecture

## Target
- iOS app using SwiftUI + Observation Framework (`@Observable`)
- Xcode 26.3+
- Local persistence with SwiftData

## Core domain models
- **Bean**
  - 豆プロファイル（豆名 / 購入店名 / 購入日 / 産地・銘柄(任意) / 焙煎日(任意) / URL(任意) / メモ(任意) / 焙煎度）
- **BrewInput**
  - `coffeeDose`, `tasteProfile`, `roastLevel`, `grindSize`
- **BrewPlan / PourStep**
  - 6投分の注湯量、開始時刻、待機秒数、推奨湯温、総湯量
- **BrewLog**
  - `date`, `bean`, `input`, `plan`, `ratings`, `memo`, `actualBrewSeconds`

## Layers (Clean Architecture oriented)
```text
App/
  FourSixCoffeeApp.swift
  AppDependencies.swift
Features/
  ... SwiftUI views + @Observable feature models
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
```

## Dependency rules
1. `Features` は `Application` の公開インターフェースを使う。
2. `Application` は `Domain` の protocol（Repository）に依存する。
3. `Infrastructure` が `Domain` protocol を実装する。
4. `Domain` は SwiftUI / SwiftData へ依存しない。

## Data flow
1. View から Store（`@Observable`）にイベントを渡す。
2. Store が UseCase を呼び、入力検証とユースケース実行を行う。
3. UseCase が Repository protocol 経由で読み書きする。
4. SwiftData Repository が Entity と Domain model を相互変換する。
5. Store が state を更新し、View が再描画される。

## Persistence policy
- Bean と BrewLog を SwiftData に保存する。
- `BrewLog` は `beanID` を保持し、豆削除時はログを残して参照のみ `nil` 扱いにする。
- `BrewLog` の複合構造（`BrewInput`, `BrewPlan`, `TasteRatings`）は JSON エンコードで保存する。
- Bean の購入店名と購入日は必須として扱い、URLは保存前に `http/https` の絶対URLとして妥当性を検証する。

## Testing policy
- Domain service（`BrewPlanner`）は純粋関数としてテストする。
- UseCase は in-memory repository で分岐をテストする。
- SwiftData repository は in-memory `ModelContainer` で永続化挙動をテストする。
- 目標は高カバレッジ（90%）だが、実効性を損なう過剰なテストは避ける。
