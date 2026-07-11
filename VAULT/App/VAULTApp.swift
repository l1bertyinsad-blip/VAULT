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
    @State private var showsSplash = !ProcessInfo.processInfo.arguments.contains("-UITesting")

    var body: some View {
        ZStack {
            FoldersView()

            if showsSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .task {
            guard showsSplash else { return }
            try? await Task.sleep(for: .milliseconds(850))
            withAnimation(.easeOut(duration: 0.28)) { showsSplash = false }
        }
    }
}
