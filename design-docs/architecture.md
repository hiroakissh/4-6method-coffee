# Architecture (Minimal)

## Target
- iOS app using SwiftUI + Observation Framework
- Xcode 26.3+

## Proposed minimal structure
```text
App/
  AppEntry.swift
  RootView.swift
Features/
  Home/
    HomeView.swift
    HomeModel.swift   // @Observable
Shared/
  Components/
  Extensions/
```

## Data flow
1. `HomeModel` が状態を保持する（`@Observable`）。
2. `HomeView` は model を監視し、UI を更新する。
3. ユーザー操作で model の状態を変更する。
