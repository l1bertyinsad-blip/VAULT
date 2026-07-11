import LocalAuthentication
import SwiftData
import SwiftUI

@main
struct VAULTApp: App {
    @AppStorage("themeSelection") private var themeSelection = AppTheme.system.rawValue

    private let container: ModelContainer = {
        let schema = Schema([VaultFolder.self, VaultMediaItem.self])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(AppTheme(rawValue: themeSelection)?.colorScheme)
                .tint(VaultPalette.purple)
        }
        .modelContainer(container)
    }
}

private struct AppRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @State private var showsSplash = !ProcessInfo.processInfo.arguments.contains("-UITesting")
    @State private var isUnlocked = ProcessInfo.processInfo.arguments.contains("-UITesting")
    @State private var authenticationError: String?

    var body: some View {
        ZStack {
            FoldersView()

            if appLockEnabled && !isUnlocked && !showsSplash {
                AppLockView(errorMessage: authenticationError) {
                    Task { await unlock() }
                }
                .zIndex(1)
            }

            if showsSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .task {
            if showsSplash {
                try? await Task.sleep(for: .milliseconds(850))
                withAnimation(.easeOut(duration: 0.28)) { showsSplash = false }
            }
            if appLockEnabled && !isUnlocked { await unlock() }
            if !appLockEnabled { isUnlocked = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active && appLockEnabled { isUnlocked = false }
            if phase == .active && appLockEnabled && !isUnlocked {
                Task { await unlock() }
            }
        }
        .onChange(of: appLockEnabled) { _, enabled in
            isUnlocked = !enabled
            if enabled { Task { await unlock() } }
        }
    }

    @MainActor
    private func unlock() async {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        var policyError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &policyError) else {
            isUnlocked = true
            authenticationError = "Защита устройства не настроена. Добавьте Face ID или код-пароль в настройках iPhone."
            return
        }
        do {
            isUnlocked = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Откройте личное пространство VAULT"
            )
            authenticationError = nil
        } catch {
            isUnlocked = false
            authenticationError = "Не удалось подтвердить владельца устройства."
        }
    }
}

private struct AppLockView: View {
    let errorMessage: String?
    let unlock: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 18) {
                Image("VaultMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 78)
                Text("VAULT заблокирован")
                    .font(.title2.bold())
                Text(errorMessage ?? "Подтвердите вход с помощью Face ID или код-пароля.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Открыть VAULT", action: unlock)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding(32)
        }
        .accessibilityIdentifier("appLockView")
    }
}
