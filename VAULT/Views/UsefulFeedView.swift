import SwiftData
import SwiftUI

struct UsefulFeedView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VaultMediaItem.createdAt, order: .reverse) private var allItems: [VaultMediaItem]
    @AppStorage("usefulFeedDay") private var storedDay = ""
    @AppStorage("usefulFeedViewedIDs") private var viewedIDsRaw = ""
    @State private var viewerItem: VaultMediaItem?
    @State private var thoughtItem: VaultMediaItem?

    let openImport: () -> Void

    private var activeItems: [VaultMediaItem] { allItems.filter { !$0.isArchived } }
    private var entries: [UsefulFeedEntry] { UsefulFeedPlanner.entries(from: activeItems) }
    private var viewedIDs: Set<String> {
        Set(viewedIDsRaw.split(separator: ",").map(String.init))
    }
    private var dailyGoal: Int { min(7, entries.count) }
    private var viewedToday: Int {
        let feedIDs = Set(entries.map { $0.id.uuidString })
        return viewedIDs.intersection(feedIDs).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                UsefulFeedBackground()
                ScrollView {
                    LazyVStack(spacing: 18) {
                        feedHeader
                        feedPromise

                        if entries.isEmpty {
                            emptyFeed
                        } else {
                            ForEach(entries) { entry in
                                UsefulFeedCard(
                                    entry: entry,
                                    open: { viewerItem = entry.item },
                                    toggleFavorite: { toggleFavorite(entry.item) },
                                    addThought: { thoughtItem = entry.item },
                                    archive: { archive(entry.item) }
                                )
                                .onAppear { markViewed(entry.item) }
                            }
                            feedFinish
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { prepareDailySession() }
            .fullScreenCover(item: $viewerItem) { item in
                MediaViewer(items: activeItems, initialItemID: item.id)
            }
            .sheet(item: $thoughtItem) { item in
                FeedThoughtSheet(item: item)
            }
        }
        .accessibilityIdentifier("usefulFeedView")
    }

    private var feedHeader: some View {
        HStack(spacing: 12) {
            Image("VaultMark")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text("VAULT FEED")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text("Только то, что сохранили вы")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: openImport) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 43, height: 43)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel("Импортировать")
        }
    }

    private var feedPromise: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("ПОЛЕЗНЫЙ СКРОЛЛИНГ")
                        .font(.caption.bold())
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.78))
                    Text("Листайте не чужую жизнь, а свои идеи.")
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "arrow.down")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.16), in: Circle())
            }

            if dailyGoal > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Сегодня")
                        Spacer()
                        Text("\(min(viewedToday, dailyGoal)) из \(dailyGoal) идей")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    ProgressView(value: Double(min(viewedToday, dailyGoal)), total: Double(dailyGoal))
                        .tint(.white)
                }
            } else {
                Text("Сохраните первую идею — и лента станет вашей.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color(red: 0.41, green: 0.25, blue: 0.96), Color(red: 0.17, green: 0.34, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 150, height: 150)
                .offset(x: 35, y: 55)
                .allowsHitTesting(false)
        }
        .shadow(color: VaultPalette.purple.opacity(0.24), radius: 24, y: 12)
    }

    private var emptyFeed: some View {
        VStack(spacing: 17) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(VaultPalette.purple)
            Text("Здесь появится ваша лента")
                .font(.title3.bold())
            Text("Сохраняйте рецепты, места, образы и мысли через «Поделиться». VAULT будет возвращать их тогда, когда вы готовы листать.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Добавить первую идею", action: openImport)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 42)
        .usefulGlassCard()
    }

    private var feedFinish: some View {
        VStack(spacing: 12) {
            Image(systemName: viewedToday >= dailyGoal ? "checkmark.seal.fill" : "leaf.fill")
                .font(.system(size: 34))
                .foregroundStyle(viewedToday >= dailyGoal ? .green : VaultPalette.purple)
            Text(viewedToday >= dailyGoal ? "Скроллинг уже принёс пользу" : "Это всё на сегодня")
                .font(.headline)
            Text("Выберите хотя бы одну идею, добавьте свою мысль или вернитесь к ней позже. Завтра порядок ленты обновится.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .usefulGlassCard()
    }

    private var todayKey: String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }

    private func prepareDailySession() {
        guard storedDay != todayKey else { return }
        storedDay = todayKey
        viewedIDsRaw = ""
    }

    private func markViewed(_ item: VaultMediaItem) {
        if storedDay != todayKey { prepareDailySession() }
        var ids = viewedIDs
        guard ids.insert(item.id.uuidString).inserted else { return }
        viewedIDsRaw = ids.sorted().joined(separator: ",")
    }

    private func toggleFavorite(_ item: VaultMediaItem) {
        item.isFavorite.toggle()
        try? context.save()
    }

    private func archive(_ item: VaultMediaItem) {
        item.isArchived = true
        try? context.save()
    }
}

private struct UsefulFeedCard: View {
    let entry: UsefulFeedEntry
    let open: () -> Void
    let toggleFavorite: () -> Void
    let addThought: () -> Void
    let archive: () -> Void

    private var item: VaultMediaItem { entry.item }
    private var displayTitle: String {
        let title = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? (item.folder?.name ?? "Сохранённая идея") : title
    }
    private var sourceTitle: String {
        guard let host = URL(string: item.sourceURLString)?.host else {
            return item.mediaType == .video ? "Видео" : "Фото"
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Label(entry.reason.title, systemImage: entry.reason.symbolName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VaultPalette.purple)
                Spacer()
                if let folder = item.folder {
                    Label(folder.name, systemImage: folder.symbolName)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Menu {
                    if let url = URL(string: item.sourceURLString), !item.sourceURLString.isEmpty {
                        Link("Открыть источник", destination: url)
                    }
                    Button("Убрать в архив", systemImage: "archivebox", action: archive)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 30, height: 30)
                }
                .accessibilityLabel("Действия")
            }
            .padding(16)

            AsyncThumbnailView(item: item)
                .frame(maxWidth: .infinity)
                .frame(height: 310)
                .contentShape(Rectangle())
                .onTapGesture(perform: open)

            VStack(alignment: .leading, spacing: 10) {
                Text(sourceTitle.uppercased())
                    .font(.caption2.bold())
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
                Text(displayTitle)
                    .font(.title3.bold())
                    .fixedSize(horizontal: false, vertical: true)

                if !item.caption.isEmpty {
                    Text(item.caption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !item.note.isEmpty {
                    Label(item.note, systemImage: "quote.opening")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(VaultPalette.purple)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    Button(action: toggleFavorite) {
                        Label(item.isFavorite ? "В избранном" : "Запомнить", systemImage: item.isFavorite ? "star.fill" : "star")
                    }
                    .buttonStyle(.bordered)

                    Button(action: addThought) {
                        Label("Мысль", systemImage: "square.and.pencil")
                    }
                    .buttonStyle(.bordered)

                    Spacer(minLength: 0)

                    Button("Открыть", action: open)
                        .buttonStyle(.borderedProminent)
                }
                .font(.caption.weight(.semibold))
                .controlSize(.small)
            }
            .padding(17)
        }
        .usefulGlassCard(cornerRadius: 26)
        .accessibilityIdentifier("usefulFeedCard_\(item.id.uuidString)")
    }
}

private struct FeedThoughtSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: VaultMediaItem
    @State private var note: String
    @State private var caption: String

    init(item: VaultMediaItem) {
        self.item = item
        _note = State(initialValue: item.note)
        _caption = State(initialValue: item.caption)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Зачем я это сохранил?") {
                    TextField("Моя мысль", text: $note, axis: .vertical)
                        .lineLimit(4...10)
                }
                Section("Короткое описание") {
                    TextField("Что здесь важного", text: $caption, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Сделать идею своей")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
                        item.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct UsefulFeedBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            Circle()
                .fill(Color.blue.opacity(0.09))
                .frame(width: 320, height: 320)
                .blur(radius: 50)
                .offset(x: 150, y: -300)
            Circle()
                .fill(VaultPalette.purple.opacity(0.09))
                .frame(width: 360, height: 360)
                .blur(radius: 60)
                .offset(x: -160, y: 360)
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func usefulGlassCard(cornerRadius: CGFloat = 22) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.32), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}
