import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let appGroupIdentifier = "group.com.nevsk1y.vault"
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let destinationButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private var folderEntries: [SharedFolderCatalog.Entry] = []
    private var selectedFolderID: UUID?
    private var isSaving = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureInterface()
        loadFolderCatalog()
    }

    private func configureInterface() {
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 360, height: 330)

        let icon = UIImageView(image: UIImage(systemName: "archivebox.fill"))
        icon.tintColor = UIColor(red: 0.49, green: 0.19, blue: 0.96, alpha: 1)
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .semibold)
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = "VAULT"
        title.font = .systemFont(ofSize: 25, weight: .bold)
        title.textAlignment = .center

        statusLabel.text = "Выберите папку или сохраните во «Входящие»"
        statusLabel.font = .preferredFont(forTextStyle: .subheadline)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        spinner.hidesWhenStopped = true

        var destinationConfiguration = UIButton.Configuration.tinted()
        destinationConfiguration.title = "Входящие"
        destinationConfiguration.image = UIImage(systemName: "folder.fill")
        destinationConfiguration.imagePadding = 8
        destinationButton.configuration = destinationConfiguration
        destinationButton.tintColor = UIColor(red: 0.49, green: 0.19, blue: 0.96, alpha: 1)
        destinationButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        destinationButton.showsMenuAsPrimaryAction = true

        var saveConfiguration = UIButton.Configuration.filled()
        saveConfiguration.title = "Сохранить в VAULT"
        saveButton.configuration = saveConfiguration
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        saveButton.tintColor = UIColor(red: 0.49, green: 0.19, blue: 0.96, alpha: 1)
        saveButton.addTarget(self, action: #selector(startSaving), for: .touchUpInside)

        cancelButton.setTitle("Отмена", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelSharing), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, title, statusLabel, destinationButton, saveButton, spinner, cancelButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 64),
            icon.heightAnchor.constraint(equalToConstant: 56),
            destinationButton.widthAnchor.constraint(equalToConstant: 270),
            destinationButton.heightAnchor.constraint(equalToConstant: 44),
            saveButton.widthAnchor.constraint(equalToConstant: 270),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadFolderCatalog() {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ),
              let data = try? Data(contentsOf: groupURL.appendingPathComponent("FolderCatalog.json")),
              let catalog = try? JSONDecoder().decode(SharedFolderCatalog.self, from: data) else {
            destinationButton.menu = UIMenu(children: [])
            return
        }

        folderEntries = catalog.folders.sorted {
            if $0.isSystem != $1.isSystem { return $0.isSystem }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        selectedFolderID = folderEntries.first(where: \.isSystem)?.id
        updateDestinationMenu()
    }

    private func updateDestinationMenu() {
        let actions = folderEntries.map { entry in
            UIAction(
                title: entry.name,
                image: UIImage(systemName: entry.symbolName),
                state: entry.id == selectedFolderID ? .on : .off
            ) { [weak self] _ in
                self?.selectedFolderID = entry.id
                self?.setDestinationTitle(entry.name)
                self?.updateDestinationMenu()
            }
        }
        destinationButton.menu = UIMenu(title: "Куда сохранить", children: actions)
        if let selected = folderEntries.first(where: { $0.id == selectedFolderID }) {
            setDestinationTitle(selected.name)
        }
    }

    private func setDestinationTitle(_ title: String) {
        var configuration = destinationButton.configuration
        configuration?.title = title
        destinationButton.configuration = configuration
    }

    @objc private func startSaving() {
        guard !isSaving else { return }
        isSaving = true
        saveButton.isEnabled = false
        destinationButton.isEnabled = false
        statusLabel.text = "Сохраняем материалы…"
        spinner.startAnimating()
        Task { await saveSharedItems() }
    }

    private func saveSharedItems() async {
        let inputItems = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            if let fallbackURL = await firstSharedWebURL(in: inputItems) {
                await MainActor.run {
                    UIPasteboard.general.url = fallbackURL
                    spinner.stopAnimating()
                    statusLabel.text = "Ссылка скопирована. Откройте VAULT, нажмите «+» и «Вставить»."
                }
                try? await Task.sleep(for: .milliseconds(1_400))
                await MainActor.run { extensionContext?.completeRequest(returningItems: nil) }
            } else {
                await finishWithError("Не удалось открыть общее хранилище VAULT.")
            }
            return
        }

        let incoming = groupURL.appendingPathComponent("Incoming", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: incoming, withIntermediateDirectories: true)
        } catch {
            await finishWithError("Не удалось подготовить папку импорта.")
            return
        }

        var savedCount = 0
        var seenURLs = Set<String>()

        for inputItem in inputItems {
            let fallbackText = inputItem.attributedContentText?.string ?? ""
            for provider in inputItem.attachments ?? [] {
                do {
                    if let typeIdentifier = preferredMediaTypeIdentifier(for: provider) {
                        try await copyMedia(
                            from: provider,
                            typeIdentifier: typeIdentifier,
                            into: incoming,
                            folderID: selectedFolderID
                        )
                        savedCount += 1
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                              let value = try await loadString(
                                from: provider,
                                typeIdentifier: UTType.url.identifier
                              ),
                              let url = extractWebURL(from: value),
                              seenURLs.insert(url.absoluteString).inserted {
                        try saveLink(
                            url: url,
                            text: fallbackText,
                            suggestedName: provider.suggestedName,
                            into: incoming,
                            folderID: selectedFolderID
                        )
                        savedCount += 1
                    } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                              let value = try await loadString(
                                from: provider,
                                typeIdentifier: UTType.plainText.identifier
                              ),
                              let url = extractWebURL(from: value),
                              seenURLs.insert(url.absoluteString).inserted {
                        try saveLink(
                            url: url,
                            text: value,
                            suggestedName: provider.suggestedName,
                            into: incoming,
                            folderID: selectedFolderID
                        )
                        savedCount += 1
                    }
                    await updateStatus("Сохранено в VAULT: \(savedCount)")
                } catch {
                    continue
                }
            }
        }

        guard savedCount > 0 else {
            await finishWithError("Подходящие фото, видео или ссылки не найдены.")
            return
        }

        await MainActor.run {
            spinner.stopAnimating()
            statusLabel.text = savedCount == 1
                ? "Материал добавлен в «\(destinationName)»"
                : "В «\(destinationName)» добавлено: \(savedCount)"
        }
        try? await Task.sleep(for: .milliseconds(650))
        await MainActor.run {
            extensionContext?.completeRequest(returningItems: nil)
        }
    }

    private func preferredMediaTypeIdentifier(for provider: NSItemProvider) -> String? {
        provider.registeredTypeIdentifiers.first { identifier in
            guard let type = UTType(identifier) else { return false }
            return type.conforms(to: .image) || type.conforms(to: .movie)
        }
    }

    private func copyMedia(
        from provider: NSItemProvider,
        typeIdentifier: String,
        into incoming: URL,
        folderID: UUID?
    ) async throws {
        let temporaryURL = try await loadFile(from: provider, typeIdentifier: typeIdentifier)
        let type = UTType(typeIdentifier)
        let fallbackExtension = type?.conforms(to: .movie) == true ? "mov" : "jpg"
        let fileExtension = temporaryURL.pathExtension.isEmpty
            ? (type?.preferredFilenameExtension ?? fallbackExtension)
            : temporaryURL.pathExtension
        let prefix = folderID.map { "\($0.uuidString)--" } ?? ""
        let destination = incoming.appendingPathComponent("\(prefix)\(UUID().uuidString).\(fileExtension)")
        try FileManager.default.copyItem(at: temporaryURL, to: destination)
    }

    private func saveLink(
        url: URL,
        text: String,
        suggestedName: String?,
        into incoming: URL,
        folderID: UUID?
    ) throws {
        let host = url.host?.replacingOccurrences(of: "www.", with: "") ?? "Ссылка"
        let isInstagram = host.contains("instagram.com")
        let fallbackTitle = isInstagram && url.path.contains("/reel") ? "Instagram Reel" : host
        let cleanText = text
            .replacingOccurrences(of: url.absoluteString, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestedTitle = suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let payload = SharedLinkPayload(
            version: 1,
            url: url.absoluteString,
            title: suggestedTitle.isEmpty ? fallbackTitle : suggestedTitle,
            caption: cleanText,
            source: host,
            folderID: folderID
        )
        let destination = incoming.appendingPathComponent("\(UUID().uuidString).vaultlink")
        try JSONEncoder().encode(payload).write(to: destination, options: .atomic)
    }

    private func loadFile(from provider: NSItemProvider, typeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let error { continuation.resume(throwing: error) }
                else if let url { continuation.resume(returning: url) }
                else { continuation.resume(throwing: CocoaError(.fileNoSuchFile)) }
            }
        }
    }

    private func loadString(from provider: NSItemProvider, typeIdentifier: String) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url = item as? URL {
                    continuation.resume(returning: url.absoluteString)
                } else if let string = item as? String {
                    continuation.resume(returning: string)
                } else if let data = item as? Data {
                    continuation.resume(returning: String(data: data, encoding: .utf8))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func extractWebURL(from value: String) -> URL? {
        let candidates = value
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        for candidate in candidates {
            let cleaned = candidate.trimmingCharacters(
                in: CharacterSet(charactersIn: "<>[](){}\"'.,;!?")
            )
            guard let url = URL(string: cleaned),
                  let scheme = url.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  url.host != nil else { continue }
            return url
        }
        return nil
    }

    private func firstSharedWebURL(in inputItems: [NSExtensionItem]) async -> URL? {
        for inputItem in inputItems {
            for provider in inputItem.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let value = try? await loadString(
                    from: provider,
                    typeIdentifier: UTType.url.identifier
                   ),
                   let url = extractWebURL(from: value) {
                    return url
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let value = try? await loadString(
                    from: provider,
                    typeIdentifier: UTType.plainText.identifier
                   ),
                   let url = extractWebURL(from: value) {
                    return url
                }
            }
        }
        return nil
    }

    @MainActor
    private func updateStatus(_ text: String) {
        statusLabel.text = text
    }

    @MainActor
    private func finishWithError(_ message: String) {
        spinner.stopAnimating()
        statusLabel.text = message
        isSaving = false
        saveButton.isEnabled = true
        destinationButton.isEnabled = true
    }

    private var destinationName: String {
        folderEntries.first(where: { $0.id == selectedFolderID })?.name ?? "Входящие"
    }

    @objc private func cancelSharing() {
        extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
    }
}

private struct SharedLinkPayload: Codable {
    let version: Int
    let url: String
    let title: String
    let caption: String
    let source: String
    let folderID: UUID?
}

private struct SharedFolderCatalog: Codable {
    struct Entry: Codable {
        let id: UUID
        let name: String
        let symbolName: String
        let isSystem: Bool
    }

    let version: Int
    let folders: [Entry]
}
