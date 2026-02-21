# Scaffold Reference

## Minimal feature scaffold

```text
Features/
  Home/
    HomeView.swift
    HomeModel.swift
```

## HomeModel template

```swift
import Observation

@Observable
final class HomeModel {
    var title: String = "Home"
    var isLoading: Bool = false

    func onAppear() {
        // load initial data if needed
    }
}
```

## HomeView template

```swift
import SwiftUI

struct HomeView: View {
    @State private var model = HomeModel()

    var body: some View {
        VStack(spacing: 12) {
            Text(model.title)
            if model.isLoading { ProgressView() }
        }
        .padding()
        .onAppear { model.onAppear() }
    }
}
```

## Naming
- Feature folder: PascalCase (`Home`, `Settings`)
- Files: `<FeatureName>View.swift`, `<FeatureName>Model.swift`
- Observable type: `<FeatureName>Model`
