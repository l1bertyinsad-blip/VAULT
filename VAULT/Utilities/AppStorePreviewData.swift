import SwiftData

@MainActor
enum AppStorePreviewData {
    static func seed(in context: ModelContext) {
        let inbox = VaultFolder(
            name: "Входящие",
            colorIdentifier: "purple",
            symbolName: "tray.full.fill",
            sortOrder: -1_000,
            isSystem: true
        )
        let recipes = VaultFolder(
            name: "Рецепты",
            colorIdentifier: "orange",
            symbolName: "fork.knife",
            sortOrder: 0,
            template: .recipes
        )
        let design = VaultFolder(
            name: "Идеи для дома",
            colorIdentifier: "pink",
            symbolName: "house.fill",
            sortOrder: 1,
            template: .design
        )
        let travel = VaultFolder(
            name: "Путешествия",
            colorIdentifier: "blue",
            symbolName: "airplane",
            sortOrder: 2,
            template: .travel
        )

        [inbox, recipes, design, travel].forEach { context.insert($0) }

        let items = [
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now,
                folder: recipes,
                title: "Паста с томатами и базиликом",
                caption: "Быстрый ужин за 20 минут",
                note: "Купить свежий базилик",
                tags: ["ужин", "итальянское"],
                sourceURLString: "https://www.instagram.com/reel/vault-recipe/",
                isFavorite: true,
                status: "Попробовать"
            ),
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now.addingTimeInterval(-1_800),
                folder: design,
                title: "Спокойная рабочая зона",
                caption: "Светлое дерево и тёплый свет",
                tags: ["интерьер", "рабочее место"],
                sourceURLString: "https://www.behance.net/gallery/vault-workspace",
                isFavorite: true,
                status: "Идея"
            ),
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now.addingTimeInterval(-3_600),
                folder: travel,
                title: "Кофейни Стамбула",
                caption: "Маршрут на один свободный день",
                tags: ["кофе", "Стамбул"],
                sourceURLString: "https://maps.apple.com/?q=Istanbul",
                status: "Запланировано"
            ),
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now.addingTimeInterval(-5_400),
                folder: inbox,
                title: "Идея для выходных",
                caption: "Сохранено из Safari",
                sourceURLString: "https://example.com/weekend"
            ),
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now.addingTimeInterval(-900_000),
                folder: design,
                title: "Цветовая палитра для спальни",
                caption: "Вернуться к идее перед ремонтом",
                sourceURLString: "https://www.pinterest.com/",
                isFavorite: true,
                status: "В работе"
            ),
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now.addingTimeInterval(-7_200),
                folder: inbox,
                title: "Книга о маленьких привычках",
                caption: "Вернуться к списку после работы",
                note: "Проверить, есть ли аудиоверсия",
                sourceURLString: "https://books.apple.com/"
            ),
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now.addingTimeInterval(-86_400),
                folder: design,
                title: "Капсульный гардероб на осень",
                caption: "Спокойные цвета и простые сочетания",
                sourceURLString: "https://example.com/capsule-wardrobe",
                isFavorite: true,
                status: "Идея"
            ),
            VaultMediaItem(
                mediaType: .link,
                localFileName: "",
                thumbnailFileName: "",
                createdAt: .now.addingTimeInterval(-172_800),
                folder: recipes,
                title: "Завтрак без спешки",
                caption: "Сохранённый рецепт на выходные",
                sourceURLString: "https://example.com/weekend-breakfast",
                status: "Попробовать"
            )
        ]
        items.forEach { context.insert($0) }

        context.insert(VaultNote(
            title: "Идеи на неделю",
            body: "Приготовить новый рецепт\nВыбрать светильник\nСпланировать поездку",
            isPinned: true,
            colorIdentifier: "orange"
        ))
        context.insert(VaultNote(
            title: "Не забыть",
            body: "Сравнить варианты рабочего стола",
            colorIdentifier: "purple"
        ))
        try? context.save()
    }
}
