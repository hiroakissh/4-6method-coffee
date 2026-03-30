import SwiftUI

struct BrewAssistantView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var session = BrewSessionModel()
    @State private var didSaveLog = false
    @State private var showingNoteField = false

    private let tasteFeedbackOptions: [TasteProfile] = [.light, .balanced, .sweet]
    private let strengthFeedbackOptions = BrewStrengthFeedback.allCases
    private let overallFeedbackOptions = BrewOverallFeedback.allCases

    var body: some View {
        let plan = store.currentPlan
        let progress = progressRatio(for: plan)
        let summary = session.nextActionSummary(in: plan)

        NavigationStack {
            ZStack {
                assistantBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        header
                        timerHero(summary: summary)
                        nextActionCard(summary: summary, progress: progress)
                        controls
                        schedule(plan: plan)
                        logComposer(plan: plan)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                session.load(plan: plan)
            }
            .onChange(of: plan.id) { _, _ in
                session.load(plan: plan)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    session.syncElapsedTime()
                }
            }
            .alert("抽出ログを保存しました", isPresented: $didSaveLog) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var assistantBackground: some View {
        LinearGradient(
            colors: [
                AppDesignTokens.Colors.backgroundTop,
                AppDesignTokens.Colors.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee1.opacity(0.18),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 300
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee4.opacity(0.2),
                    .clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button {
                store.selectedTab = .planner
            } label: {
                Image(systemName: "xmark")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text("抽出ガイド")
                .appTextStyle(.screenTitle)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Spacer()

            Menu {
                Button("タイマーをリセット", role: .destructive) {
                    session.resetTimer()
                }
                Button("プラン画面へ戻る") {
                    store.selectedTab = .planner
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(AppDesignTokens.Typography.font(.title3, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 40, height: 40)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
        }
    }

    private func timerHero(summary: BrewSessionModel.NextActionSummary) -> some View {
        let size: CGFloat = 300
        let clampedProgress = min(max(summary.segmentProgress, 0), 1)

        return ZStack {
            Circle()
                .stroke(AppDesignTokens.Colors.timerRingTrack, lineWidth: 12)

            if clampedProgress > 0 {
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        AppDesignTokens.Colors.timerRingProgress,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 12) {
                Text("第\(summary.currentStep.id)投")
                    .appTextStyle(.itemTitle)
                    .foregroundStyle(AppDesignTokens.Colors.timerRingProgress)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(AppDesignTokens.Colors.timerStepBadgeBackground)
                    .overlay {
                        Capsule()
                            .stroke(AppDesignTokens.Colors.timerStepBadgeBorder, lineWidth: 1)
                    }
                    .clipShape(Capsule())

                Text(currentStateText(for: summary))
                    .appTextStyle(.sectionLabel)
                    .foregroundStyle(AppDesignTokens.Colors.textSecondary)

                Text(PourStep.timeLabel(from: summary.remainingSeconds))
                    .appTextStyle(.heroValue)
                    .foregroundStyle(AppDesignTokens.Colors.timerMainValue)
                    .shadow(color: Color.black.opacity(0.28), radius: 1, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
        }
        .frame(width: size, height: size)
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Button {
                session.resetTimer()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 64, height: 64)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Button {
                if session.isRunning {
                    session.pause()
                } else {
                    session.start()
                }
            } label: {
                Image(systemName: session.isRunning ? "pause.fill" : "play.fill")
                    .font(AppDesignTokens.Typography.font(.largeTitle, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 92, height: 92)
                    .background(AppDesignTokens.Colors.activeSegment)
                    .clipShape(Circle())
                    .shadow(color: AppDesignTokens.Colors.coffee1.opacity(0.45), radius: 14, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            Button {
                session.syncElapsedTime()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 64, height: 64)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func nextActionCard(summary: BrewSessionModel.NextActionSummary, progress: Double) -> some View {
        cardContainer(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(nextActionTitle(for: summary))
                        .appTextStyle(.sectionTitle)
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    Text(currentActionDetailText(for: summary))
                        .appTextStyle(.supporting)
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                }

                Spacer()

                infoChip(title: "総湯量", value: "\(summary.totalWaterGrams)g")
            }

            HStack(spacing: 12) {
                timerMetricCard(
                    title: targetCumulativeLabel(for: summary),
                    value: "\(summary.targetCumulativeGrams)g",
                    accent: AppDesignTokens.Colors.timerRingProgress
                )

                timerMetricCard(
                    title: additionalAmountLabel(for: summary),
                    value: additionalAmountValue(for: summary),
                    accent: AppDesignTokens.Colors.timerAmountAccent
                )
            }

            HStack(spacing: 10) {
                infoChip(title: "経過", value: PourStep.timeLabel(from: summary.elapsedSeconds))
                infoChip(title: "現在", value: "第\(summary.currentStep.id)投")
                if let nextStep = summary.nextStep {
                    infoChip(title: "次", value: "第\(nextStep.id)投")
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppDesignTokens.Colors.meterTrack)

                    Capsule()
                        .fill(AppDesignTokens.Colors.meterFill)
                        .frame(width: max(16, proxy.size.width * progress))
                }
            }
            .frame(height: 12)
        }
    }

    private func schedule(plan: BrewPlan) -> some View {
        cardContainer(spacing: 12) {
            Text("スケジュール")
                .appTextStyle(.sectionTitle)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)

            ForEach(plan.steps) { step in
                HStack(alignment: .top, spacing: 12) {
                    statusDot(for: session.stepStatus(for: step))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("第\(step.id)投 · 累計 \(step.cumulativeGrams)g")
                            .appTextStyle(.itemTitle)
                            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        Text("開始 \(step.startLabel) / 今回 +\(step.amountGrams)g / 待ち \(step.waitSeconds)s")
                            .appTextStyle(.supporting)
                            .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)

                if step.id != plan.steps.count {
                    Divider().overlay(AppDesignTokens.Colors.controlBorder)
                }
            }
        }
    }

    private func logComposer(plan: BrewPlan) -> some View {
        cardContainer(spacing: 14) {
            Text("抽出レビュー")
                .appTextStyle(.sectionTitle)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)

            Text("抽出が終わったら、3つだけ選んで保存できます。")
                .appTextStyle(.supporting)
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)

            feedbackChoiceGroup(title: "味の印象") {
                ForEach(tasteFeedbackOptions, id: \.self) { option in
                    feedbackButton(
                        title: option.displayName,
                        isSelected: session.tasteFeedback == option
                    ) {
                        session.tasteFeedback = option
                    }
                }
            }

            feedbackChoiceGroup(title: "濃度感") {
                ForEach(strengthFeedbackOptions) { option in
                    feedbackButton(
                        title: option.displayName,
                        isSelected: session.strengthFeedback == option
                    ) {
                        session.strengthFeedback = option
                    }
                }
            }

            feedbackChoiceGroup(title: "総合評価") {
                ForEach(overallFeedbackOptions) { option in
                    feedbackButton(
                        title: option.displayName,
                        isSelected: session.overallFeedback == option
                    ) {
                        session.overallFeedback = option
                    }
                }
            }

            optionalNoteSection

            Button {
                session.pause()
                session.saveLogIfPossible(plan: plan, store: store)
                didSaveLog = true
            } label: {
                Label("この抽出を保存", systemImage: "square.and.arrow.down")
                    .appTextStyle(.itemTitle)
                    .foregroundStyle(AppDesignTokens.Colors.ctaText)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .background(AppDesignTokens.Colors.ctaBackground)
                    .clipShape(Capsule())
                    .shadow(color: AppDesignTokens.Colors.coffee5.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
    }

    private var optionalNoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingNoteField.toggle()
                }
            } label: {
                HStack {
                    Text(showingNoteField || !session.note.isEmpty ? "詳細メモを閉じる" : "詳細メモを追加")
                        .appTextStyle(.itemTitle)
                        .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    Spacer()
                    Image(systemName: showingNoteField || !session.note.isEmpty ? "chevron.up" : "chevron.down")
                        .font(AppDesignTokens.Typography.font(.body, weight: .bold))
                        .foregroundStyle(AppDesignTokens.Colors.textSecondary)
                }
                .padding(.horizontal, 18)
                .frame(height: 52)
                .background(AppDesignTokens.Colors.controlBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            if showingNoteField || !session.note.isEmpty {
                TextEditor(text: $session.note)
                    .appTextStyle(.body)
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 92)
                    .padding(8)
                    .background(AppDesignTokens.Colors.memoFieldBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func feedbackChoiceGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .appTextStyle(.itemTitle)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            HStack(spacing: 8) {
                content()
            }
        }
    }

    private func feedbackButton(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .appTextStyle(.itemTitle)
                .foregroundStyle(
                    isSelected
                    ? AppDesignTokens.Colors.textPrimary
                    : AppDesignTokens.Colors.textSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            isSelected
                            ? AppDesignTokens.Colors.activeSegment
                            : AppDesignTokens.Colors.controlBackground
                        )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func statusDot(for status: BrewSessionModel.StepStatus) -> some View {
        let color = color(for: status)
        let systemName = icon(for: status)

        return Image(systemName: systemName)
            .font(AppDesignTokens.Typography.font(.body, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 16, height: 16)
    }

    private func timerMetricCard(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .appTextStyle(.supportingStrong)
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            Text(value)
                .appTextStyle(.metricValue)
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.controlBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func infoChip(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .appTextStyle(.supportingStrong)
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            Text(value)
                .appTextStyle(.supportingStrong)
                .monospacedDigit()
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppDesignTokens.Colors.secondaryButtonBackground)
        .clipShape(Capsule())
    }

    private func cardContainer<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppDesignTokens.Colors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous)
                .stroke(AppDesignTokens.Colors.cardBorder, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppDesignTokens.Radius.card, style: .continuous))
        .shadow(color: AppDesignTokens.Colors.cardShadow, radius: 22, x: 0, y: 12)
    }

    private func progressRatio(for plan: BrewPlan) -> Double {
        min(Double(session.elapsedSeconds) / Double(max(plan.estimatedTotalSeconds, 1)), 1)
    }

    private func nextActionTitle(for summary: BrewSessionModel.NextActionSummary) -> String {
        if let nextStep = summary.nextStep {
            return "次は第\(nextStep.id)投"
        }
        if summary.isAwaitingFinish {
            return "仕上がりまで"
        }
        return "抽出完了"
    }

    private func targetCumulativeLabel(for summary: BrewSessionModel.NextActionSummary) -> String {
        if summary.isComplete {
            return "仕上がり"
        }
        if summary.isAwaitingFinish {
            return "仕上がり目標"
        }
        return "次の累計"
    }

    private func additionalAmountLabel(for summary: BrewSessionModel.NextActionSummary) -> String {
        summary.isFinalPhase ? "追加注湯" : "今回足す量"
    }

    private func additionalAmountValue(for summary: BrewSessionModel.NextActionSummary) -> String {
        summary.additionalGrams > 0 ? "+\(summary.additionalGrams)g" : "なし"
    }

    private func currentStateText(for summary: BrewSessionModel.NextActionSummary) -> String {
        if summary.isComplete {
            return "抽出完了"
        }
        if !summary.isRunning, summary.elapsedSeconds > 0 {
            return "停止中"
        }
        return summary.currentStep.phase.displayName
    }

    private func currentActionDetailText(for summary: BrewSessionModel.NextActionSummary) -> String {
        if summary.isComplete {
            return "抽出は完了しています"
        }

        return "いまは +\(summary.currentStep.amountGrams)g / 累計 \(summary.currentStep.cumulativeGrams)g"
    }

    private func icon(for status: BrewSessionModel.StepStatus) -> String {
        switch status {
        case .done:
            return "checkmark.circle.fill"
        case .active:
            return "circle.fill"
        case .upcoming:
            return "circle"
        }
    }

    private func color(for status: BrewSessionModel.StepStatus) -> Color {
        switch status {
        case .done:
            return AppDesignTokens.Colors.timerRingProgress
        case .active:
            return AppDesignTokens.Colors.timerAmountAccent
        case .upcoming:
            return AppDesignTokens.Colors.textSecondary
        }
    }
}

#Preview {
    BrewAssistantView()
        .environment(AppStore.preview)
}
