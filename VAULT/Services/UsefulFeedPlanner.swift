import Foundation

enum UsefulFeedReason: Equatable {
    case inbox
    case favorite
    case personalThought
    case rediscovery
    case recent

    var title: String {
        switch self {
        case .inbox: "Из входящих"
        case .favorite: "Вы хотели это запомнить"
        case .personalThought: "Здесь осталась ваша мысль"
        case .rediscovery: "Стоит вспомнить"
        case .recent: "Недавно сохранено"
        }
    }

    var symbolName: String {
        switch self {
        case .inbox: "tray.full.fill"
        case .favorite: "star.fill"
        case .personalThought: "quote.bubble.fill"
        case .rediscovery: "clock.arrow.circlepath"
        case .recent: "sparkles"
        }
    }
}

struct UsefulFeedEntry: Identifiable {
    let item: VaultMediaItem
    let reason: UsefulFeedReason

    var id: UUID { item.id }
}

enum UsefulFeedPlanner {
    @MainActor
    static func entries(
        from items: [VaultMediaItem],
        date: Date = .now,
        limit: Int = 12
    ) -> [UsefulFeedEntry] {
        items
            .filter { !$0.isArchived }
            .sorted { score(for: $0, date: date) > score(for: $1, date: date) }
            .prefix(max(0, limit))
            .map { UsefulFeedEntry(item: $0, reason: reason(for: $0, date: date)) }
    }

    @MainActor
    static func reason(for item: VaultMediaItem, date: Date = .now) -> UsefulFeedReason {
        if item.folder?.isSystem == true { return .inbox }
        if item.isFavorite { return .favorite }
        if !item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .personalThought
        }
        if ageInDays(of: item, date: date) >= 14 { return .rediscovery }
        return .recent
    }

    @MainActor
    private static func score(for item: VaultMediaItem, date: Date) -> Int {
        let age = ageInDays(of: item, date: date)
        var score = min(age, 180)
        if item.folder?.isSystem == true { score += 700 }
        if item.isFavorite { score += 360 }
        if !item.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { score += 120 }
        if age <= 2 { score += 180 }

        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let stableSeed = item.id.uuidString.unicodeScalars.reduce(day) {
            (($0 &* 31) &+ Int($1.value)) % 10_007
        }
        score += stableSeed % 67
        return score
    }

    private static func ageInDays(of item: VaultMediaItem, date: Date) -> Int {
        max(0, Calendar.current.dateComponents([.day], from: item.createdAt, to: date).day ?? 0)
    }
}
