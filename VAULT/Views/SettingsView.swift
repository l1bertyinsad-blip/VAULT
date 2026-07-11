import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("themeSelection") private var themeSelection = AppTheme.system.rawValue
    @State private var usedBytes: Int64 = 0
    @State private var showsDeleteAll = false
    @State private var cleanupError = false

    var body: some View {
        Form {
            Section("VAULT") {
                LabeledContent("Версия", value: appVersion)
                LabeledContent("Занято файлами", value: ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file))
            }

            Section("Оформление") {
                Picker("Тема", selection: $themeSelection) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("О приложении") {
                Label("VAULT хранит выбранные материалы только на этом устройстве.", systemImage: "lock.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Link(destination: URL(string: "https://www.apple.com/legal/privacy/")!) {
                    Label("Конфиденциальность Apple", systemImage: "arrow.up.right.square")
                }
            }

            Section {
                Button("Очистить все данные", role: .destructive) { showsDeleteAll = true }
            } footer: {
                Text("Будут удалены все папки, фото, видео и превью VAULT.")
            }
        }
        .navigationTitle("Настройки")
        .task { await refreshStorageSize() }
        .alert("Очистить все данные?", isPresented: $showsDeleteAll) {
            Button("Удалить всё", role: .destructive) { clearAll() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это действие нельзя отменить.")
        }
        .alert("Не удалось очистить файлы", isPresented: $cleanupError) {
            Button("ОК", role: .cancel) {}
        } message: {
            Text("Часть данных могла остаться на устройстве. Попробуйте ещё раз.")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func refreshStorageSize() async {
        usedBytes = await Task.detached { LocalFileService.shared.usedBytes() }.value
    }

    private func clearAll() {
        let folders = (try? context.fetch(FetchDescriptor<VaultFolder>())) ?? []
        folders.forEach { context.delete($0) }
        try? context.save()
        do {
            try LocalFileService.shared.deleteAll()
            usedBytes = 0
        } catch {
            cleanupError = true
        }
    }
}
