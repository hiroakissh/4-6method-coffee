import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var bindableStore = store

        NavigationStack {
            ZStack {
                settingsBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header

                        cardContainer {
                            sectionTitle("単位")
                            Picker("重量単位", selection: $bindableStore.preferredUnit) {
                                Text("グラム(g)")
                                    .appTextStyle(.sectionLabel)
                                    .tag("g")
                            }
                            .pickerStyle(.menu)
                            .appTextStyle(.sectionLabel)
                            .tint(AppDesignTokens.Colors.headingAccent)
                        }

                        cardContainer {
                            sectionTitle("アシスタント")
                            Toggle("ステップ時の通知ヒント", isOn: $bindableStore.enableStepHaptics)
                                .appTextStyle(.sectionLabel)
                                .tint(AppDesignTokens.Colors.headingAccent)
                                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                        }

                        cardContainer {
                            sectionTitle("情報")
                            infoRow("バージョン", "1.0.0")
                            Divider().overlay(AppDesignTokens.Colors.controlBorder)
                            infoRow("プラン計算", "4:6 Method / 6 pours")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var settingsBackground: some View {
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
                    AppDesignTokens.Colors.coffee1.opacity(0.16),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 320
            )
        }
        .overlay {
            RadialGradient(
                colors: [
                    AppDesignTokens.Colors.coffee4.opacity(0.2),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack {
            Button {
                store.selectedTab = .planner
            } label: {
                Image(systemName: "arrow.left")
                    .font(AppDesignTokens.Typography.font(.title2, weight: .bold))
                    .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(AppDesignTokens.Colors.secondaryButtonBackground)
                    .overlay {
                        Circle().stroke(AppDesignTokens.Colors.controlBorder, lineWidth: 1)
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text("設定")
                .appTextStyle(.screenTitle)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
            Spacer()

            Circle()
                .fill(.clear)
                .frame(width: 56, height: 56)
        }
    }

    private func cardContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .appTextStyle(.sectionTitle)
            .foregroundStyle(AppDesignTokens.Colors.textPrimary)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .appTextStyle(.sectionLabel)
                .foregroundStyle(AppDesignTokens.Colors.textSecondary)
            Spacer()
            Text(value)
                .appTextStyle(.itemTitle)
                .foregroundStyle(AppDesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppStore.preview)
}
