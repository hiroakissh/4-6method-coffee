---
name: swiftui-observation
description: Use when implementing or refactoring this repo's iOS app with SwiftUI + Observation framework (Xcode 26.3+), including feature scaffolding, state modeling with @Observable, and PR-ready checks.
---

# swiftui-observation

Repository-specific workflow for SwiftUI + Observation development.

## When to use
- User asks to build or refactor iOS UI/features in this repo.
- Work involves `@Observable` state and SwiftUI screen composition.
- Need consistent structure + PR checklist for this project.

## Quick workflow
1. Confirm/refresh target behavior in `design-docs/`.
2. Add feature with minimal structure:
   - `Features/<FeatureName>/<FeatureName>View.swift`
   - `Features/<FeatureName>/<FeatureName>Model.swift` (`@Observable`)
3. Keep business state in model, rendering in view.
4. Run local checks requested by the task; if unavailable, report limitation.
5. Update docs when behavior/rules changed.

## Implementation rules
- Prefer `@Observable` over introducing extra state layers by default.
- Keep UI logic lightweight; move mutable state/operations to model.
- Use small, composable SwiftUI views.
- Make smallest viable diff first, then iterate.

## Output checklist
- Summarize changed files and why.
- Provide commands used for validation.
- Note risks or follow-up tasks.

## References
- For scaffolding and naming conventions, read `references/scaffold.md`.
- For review checklist, read `references/review-checklist.md`.
