# Brew Recipe Platform Plan

## Purpose
4-6メソッド専用の計算アプリから、世界大会レシピを分解・抽象化して扱える
「抽出設計ツール」へ移行するための実装計画をまとめる。

## Championship-inspired recipe examples
以下は「史実の完全再現データ」ではなく、アプリ設計に必要な抽出構造の例として扱う。

- **4-6**
  - 前半で味、後半で濃度を制御する複数回注湯
- **flow-control**
  - 前半高流量、後半低流量のように流量差で抽出を組む
- **simple pulse**
  - 少数パラメータで再現性を重視するシンプルなパルス注湯
- **temperature-shift**
  - 抽出途中で湯温を変化させる
- **short extraction**
  - 4投前後、短時間で設計された効率型抽出
- **immersion hybrid**
  - 浸漬からドリップへ移るハイブリッド抽出

## Common structure
全レシピで共通化する軸は以下の5つ。

1. **Pour**
   - 回数
   - タイミング
   - 量
2. **Flow**
   - 強い / 弱い
   - 連続 / パルス
3. **Temperature**
   - 一定 / 変化
4. **Agitation**
   - なし / スワール / スプーンなど
5. **Phase**
   - 蒸らし / メイン抽出 / 調整 / 浸漬 / 仕上げ

## Product entry modes
### Quick Brew
- 少数入力からおすすめレシピを返す
- ユーザーは「設計」ではなく「選択」に集中する
- 内部では既存プリセットの選択または軽量なルール生成を行う
- 出力は最終的に `BrewRecipe` に正規化する

### Research
- `BrewRecipe` を直接編集し、比較し、分析する
- プリセットの複製、改変、ログ比較はこちらに寄せる
- 世界大会レシピは研究対象としてこのモードに自然に乗る

## Recommended JSON v1
```json
{
  "schemaVersion": 1,
  "id": "recipe-four-six",
  "metadata": {
    "name": "4-6 Method",
    "device": "v60",
    "sourceType": "preset",
    "tags": ["competition", "pulse", "flavor-control"]
  },
  "defaults": {
    "coffeeDoseGrams": 20,
    "totalWaterGrams": 300,
    "grindLevel": "medium",
    "ratio": 15.0
  },
  "phases": [
    {
      "id": "bloom",
      "type": "bloom",
      "temperature": {
        "mode": "fixed",
        "points": [{ "time": 0, "celsius": 92 }]
      },
      "agitation": [],
      "pours": [
        {
          "id": "pour-1",
          "startSecond": 0,
          "amountGrams": 60,
          "targetCumulativeGrams": 60,
          "flowRate": "medium",
          "position": "center"
        }
      ]
    }
  ]
}
```

## Recommended Swift model v1
```swift
struct BrewRecipe: Codable, Hashable, Identifiable {
    var id: UUID
    var metadata: RecipeMetadata
    var defaults: RecipeDefaults
    var phases: [BrewPhase]
}

struct BrewPhase: Codable, Hashable, Identifiable {
    var id: String
    var type: PhaseType
    var temperature: TemperatureProfile
    var agitation: [AgitationAction]
    var pours: [PourAction]
}

struct PourAction: Codable, Hashable, Identifiable {
    var id: String
    var startSecond: Int
    var amountGrams: Int
    var targetCumulativeGrams: Int
    var flowRate: FlowRate
    var position: PourPosition
}
```

## Why this split is necessary
- `BrewInput` は「4-6を計算するための入力」であり、一般レシピの表現には狭すぎる
- `BrewPlan` は「6投の計算結果」であり、浸漬や4投や温度変更を自然に持てない
- `BrewRecipe` は編集対象、`BrewSessionPlan` は再生対象として分けると UI と Domain が整理しやすい

## Implementation phases
1. **Phase 1: Schema foundation**
   - `BrewRecipe` 系モデル追加
   - `RecipeRepository` 追加
   - `RecipeEntity(payloadJSON)` 追加
   - 4-6プリセットを JSON 化
2. **Phase 2: Quick Brew introduction**
   - `QuickBrewRequest` と `QuickBrewGenerator` を追加
   - 少数入力から `BrewRecipe` を返す
   - おすすめ抽出のカードUIを追加
3. **Phase 3: Session guide migration**
   - `RecipeResolver` で `BrewSessionPlan` を生成
   - `BrewSessionModel` を可変投数対応に変更
   - Live Activity を可変ステップ対応に変更
4. **Phase 4: UI restructuring**
   - Home を Quick Brew / Research の2導線に再構成
   - Recipe Editor を追加
   - Brew Guide で phase / temperature / agitation を表示
5. **Phase 5: Learning loop**
   - `BrewLog` を `recipeID` 紐づきへ変更
   - `quick / research` の利用モードも記録する
   - 味結果から改善提案を返す仕組みを追加

## Immediate build order
1. **レシピJSON設計**
   - 先に schemaVersion を含む JSON 契約を固定する
2. **Swiftモデル設計**
   - 現行 repo は Observation 前提なので、Store は維持しつつ Domain model は UI 非依存にする
   - TCA を後で採る場合でも、そのまま流用できる型境界にする
3. **Quick Brew 入口**
   - 少数入力からおすすめレシピを返す最短導線を先に作る
4. **UI: 抽出ガイド**
   - 可変投数へ対応し、次に phase / temperature 表示を足す

## Risk notes
- 現行 `AppStore` と `BrewSessionModel` は 4-6前提の state を持っているため、途中で adapter 層が必要になる
- 既存の `TasteProfile` は 4-6固有の意味を持つため、将来は「preset input」へ隔離する必要がある
- Quick Brew の責務を広げすぎると Research と競合するため、入力項目数と編集範囲を厳しく制限する必要がある
- 永続化を細粒度 Entity に急いで分解すると移行コストが上がるため、MVP は JSON payload 保存が安全
