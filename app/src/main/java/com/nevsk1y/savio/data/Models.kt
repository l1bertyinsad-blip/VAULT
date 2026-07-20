package com.nevsk1y.savio.data

enum class SavioItemType { IMAGE, VIDEO, FILE, LINK, NOTE }

data class SavioFolder(
    val id: String,
    val name: String,
    val color: String,
    val glyph: String,
    val createdAt: Long,
    val isSystem: Boolean = false
)

data class SavioItem(
    val id: String,
    val folderId: String,
    val type: SavioItemType,
    val title: String,
    val description: String = "",
    val thought: String = "",
    val originalName: String = "",
    val mimeType: String = "",
    val localPath: String = "",
    val sourceUrl: String = "",
    val createdAt: Long,
    val updatedAt: Long,
    val isFavorite: Boolean = false,
    val isArchived: Boolean = false
)

data class SavioSettings(
    val language: String = "ru",
    val theme: String = "light",
    val usefulFeedEnabled: Boolean = false,
    val designVersion: Int = 2
)

data class SavioState(
    val folders: List<SavioFolder>,
    val items: List<SavioItem>,
    val settings: SavioSettings = SavioSettings()
)

object SavioIds {
    const val INBOX = "folder-inbox"
    const val IDEAS = "folder-ideas"
    const val RECIPES = "folder-recipes"
    const val TRAVEL = "folder-travel"
    const val WORK = "folder-work"
}
