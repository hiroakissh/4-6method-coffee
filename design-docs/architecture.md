# Architecture (Minimal)

## Target
- iOS app using SwiftUI + Observation Framework
- Xcode 26.3+

## Core domains
- **RecipeInput**: 豆量(g), 味方向(甘め/普通/薄め), 焙煎度(浅/中/深)
- **PourPlan**: 1投目〜6投目の注湯量(g)と時間目安
- **BrewRecord**: 実測値とテイスティングメモ

## Proposed minimal structure
```text
App/
  AppEntry.swift
  RootView.swift
Features/
  Calculator/
    CalculatorView.swift
    CalculatorModel.swift      // @Observable
  Record/
    RecordView.swift
    RecordModel.swift          // @Observable
  History/
    HistoryView.swift
    HistoryModel.swift         // @Observable
Domain/
  FourSixCalculator.swift      // 4-6メソッド算出ロジック
  Models.swift                 // RecipeInput / PourPlan / BrewRecord
Shared/
  Components/
  Extensions/
```

## Data flow
1. CalculatorView が入力値を CalculatorModel に渡す。
2. CalculatorModel が FourSixCalculator を呼び、PourPlan を生成。
3. RecordView で実測値/メモを BrewRecord として保存。
4. HistoryView で過去レシピを参照し、再計算に再利用。

## Notes
- 算出ロジックは UI から分離し、Domain 層でテスト可能にする。
- 味方向・焙煎度の補正係数は将来拡張を見越して定数管理する。
