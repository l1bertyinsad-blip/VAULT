import SwiftData
import SwiftUI

struct FolderEditorSheet: View {
    enum Mode { case create, edit(VaultFolder) }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let mode: Mode
    let nextSortOrder: Int
    @State private var name: String
    @State private var colorIdentifier: String
    @State private var symbolName: String
    @State private var template: VaultFolderTemplate

    private let symbols = ["folder.fill", "gamecontroller.fill", "paintpalette.fill", "film.fill", "cart.fill", "star.fill"]

    init(mode: Mode, nextSortOrder: Int = 0) {
        self.mode = mode
        self.nextSortOrder = nextSortOrder
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _colorIdentifier = State(initialValue: "purple")
            _symbolName = State(initialValue: "folder.fill")
            _template = State(initialValue: .general)
        case .edit(let folder):
            _name = State(initialValue: folder.name)
            _colorIdentifier = State(initialValue: folder.colorIdentifier)
            _symbolName = State(initialValue: folder.symbolName)
            _template = State(initialValue: folder.template)
        }
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, Дизайн", text: $name)
                        .textInputAutocapitalization(.sentences)
                        .accessibilityIdentifier("folderNameField")
                }

                Section("Назначение") {
                    Picker("Шаблон", selection: $template) {
                        ForEach(VaultFolderTemplate.allCases) { template in
                            Label(template.title, systemImage: template.symbolName)
                                .tag(template)
                        }
                    }
                    .onChange(of: template) { _, newValue in
                        if symbolName == "folder.fill" || mode.isCreate {
                            symbolName = newValue.symbolName
                        }
                    }
                    Text("Шаблон добавляет подходящие статусы и поля карточек.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Цвет") {
                    HStack(spacing: 14) {
                        ForEach(VaultPalette.colors, id: \.id) { option in
                            Button {
                                colorIdentifier = option.id
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if colorIdentifier == option.id {
                                            Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Цвет \(option.id)")
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Иконка") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(symbols, id: \.self) { symbol in
                            Button {
                                symbolName = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .font(.title3)
                                    .frame(width: 38, height: 38)
                                    .foregroundStyle(symbolName == symbol ? VaultPalette.purple : .secondary)
                                    .background(symbolName == symbol ? VaultPalette.purple.opacity(0.12) : .clear, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.isCreate ? "Создать" : "Сохранить") { save() }
                        .disabled(!isValid)
                        .accessibilityIdentifier("saveFolderButton")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var title: String { mode.isCreate ? "Новая папка" : "Редактировать папку" }

    private func save() {
        switch mode {
        case .create:
            _ = VaultOperations.createFolder(
                name: name,
                colorIdentifier: colorIdentifier,
                symbolName: symbolName,
                sortOrder: nextSortOrder,
                template: template,
                in: context
            )
        case .edit(let folder):
            _ = VaultOperations.update(
                folder,
                name: name,
                colorIdentifier: colorIdentifier,
                symbolName: symbolName,
                template: template,
                in: context
            )
        }
        dismiss()
    }
}

private extension FolderEditorSheet.Mode {
    var isCreate: Bool {
        switch self {
        case .create: true
        case .edit: false
        }
    }
}
