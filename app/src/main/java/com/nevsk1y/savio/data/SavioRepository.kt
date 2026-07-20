package com.nevsk1y.savio.data

import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.provider.OpenableColumns
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.util.Locale
import java.util.UUID

class SavioRepository private constructor(context: Context) {
    private val appContext = context.applicationContext
    private val resolver: ContentResolver = appContext.contentResolver
    private val stateFile = File(appContext.filesDir, "savio_state.json")
    private val storageDir = File(appContext.filesDir, "savio").apply { mkdirs() }
    private val lock = Any()

    private val _state = MutableStateFlow(loadState())
    val state: StateFlow<SavioState> = _state.asStateFlow()

    fun createFolder(name: String, color: String = "#0B4DFF", glyph: String = "folder"): String {
        val cleaned = name.trim().ifBlank { if (isEnglish()) "New folder" else "Новая папка" }
        val id = UUID.randomUUID().toString()
        mutate { current ->
            current.copy(
                folders = current.folders + SavioFolder(
                    id = id,
                    name = cleaned,
                    color = color,
                    glyph = glyph,
                    createdAt = System.currentTimeMillis()
                )
            )
        }
        return id
    }

    fun renameFolder(folderId: String, name: String) {
        val cleaned = name.trim()
        if (cleaned.isBlank()) return
        mutate { current ->
            current.copy(folders = current.folders.map { if (it.id == folderId) it.copy(name = cleaned) else it })
        }
    }

    fun deleteFolder(folderId: String) {
        if (folderId == SavioIds.INBOX) return
        mutate { current ->
            current.copy(
                folders = current.folders.filterNot { it.id == folderId },
                items = current.items.map { if (it.folderId == folderId) it.copy(folderId = SavioIds.INBOX) else it }
            )
        }
    }

    fun addNote(title: String, body: String, folderId: String = SavioIds.INBOX): String {
        val now = System.currentTimeMillis()
        val id = UUID.randomUUID().toString()
        val fallback = if (isEnglish()) "New note" else "Новая заметка"
        val item = SavioItem(
            id = id,
            folderId = validFolder(folderId),
            type = SavioItemType.NOTE,
            title = title.trim().ifBlank { fallback },
            description = body.trim(),
            createdAt = now,
            updatedAt = now
        )
        mutate { it.copy(items = listOf(item) + it.items) }
        return id
    }

    fun addLink(rawText: String, folderId: String = SavioIds.INBOX): String {
        val value = rawText.trim()
        val url = extractUrl(value)
        val now = System.currentTimeMillis()
        val id = UUID.randomUUID().toString()
        val title = url?.let(::hostTitle) ?: value.lineSequence().firstOrNull().orEmpty().take(80)
        val item = SavioItem(
            id = id,
            folderId = validFolder(folderId),
            type = if (url != null) SavioItemType.LINK else SavioItemType.NOTE,
            title = title.ifBlank { if (isEnglish()) "Saved text" else "Сохранённый текст" },
            description = if (url != null && value != url) value else "",
            sourceUrl = url.orEmpty(),
            createdAt = now,
            updatedAt = now
        )
        mutate { it.copy(items = listOf(item) + it.items) }
        return id
    }

    fun importUris(uris: List<Uri>, folderId: String = SavioIds.INBOX): Int {
        val imported = uris.distinct().mapNotNull { importUri(it, folderId) }
        if (imported.isNotEmpty()) mutate { it.copy(items = imported + it.items) }
        return imported.size
    }

    @Suppress("DEPRECATION")
    fun importSharedIntent(intent: Intent?): Int {
        if (intent == null) return 0
        return when (intent.action) {
            Intent.ACTION_SEND -> {
                val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                if (uri != null) {
                    importUris(listOf(uri))
                } else {
                    val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                        ?: intent.getStringExtra(Intent.EXTRA_SUBJECT)
                        ?: return 0
                    addLink(text)
                    1
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM).orEmpty()
                importUris(uris)
            }
            else -> 0
        }
    }

    fun toggleFavorite(itemId: String) {
        mutate { current ->
            current.copy(items = current.items.map {
                if (it.id == itemId) it.copy(isFavorite = !it.isFavorite, updatedAt = System.currentTimeMillis()) else it
            })
        }
    }

    fun toggleArchive(itemId: String) {
        mutate { current ->
            current.copy(items = current.items.map {
                if (it.id == itemId) it.copy(isArchived = !it.isArchived, updatedAt = System.currentTimeMillis()) else it
            })
        }
    }

    fun updateItem(itemId: String, title: String, description: String, thought: String) {
        mutate { current ->
            current.copy(items = current.items.map {
                if (it.id == itemId) it.copy(
                    title = title.trim().ifBlank { it.title },
                    description = description.trim(),
                    thought = thought.trim(),
                    updatedAt = System.currentTimeMillis()
                ) else it
            })
        }
    }

    fun moveItem(itemId: String, folderId: String) {
        val destination = validFolder(folderId)
        mutate { current ->
            current.copy(items = current.items.map {
                if (it.id == itemId) it.copy(folderId = destination, updatedAt = System.currentTimeMillis()) else it
            })
        }
    }

    fun deleteItem(itemId: String) {
        val item = _state.value.items.firstOrNull { it.id == itemId }
        if (item != null && item.localPath.isNotBlank()) runCatching { File(item.localPath).delete() }
        mutate { current -> current.copy(items = current.items.filterNot { it.id == itemId }) }
    }

    fun setLanguage(language: String) {
        mutate { it.copy(settings = it.settings.copy(language = if (language == "en") "en" else "ru")) }
    }

    fun setTheme(theme: String) {
        val safeTheme = if (theme in setOf("light", "dark", "system")) theme else "system"
        mutate { it.copy(settings = it.settings.copy(theme = safeTheme)) }
    }

    fun setUsefulFeedEnabled(enabled: Boolean) {
        mutate { it.copy(settings = it.settings.copy(usefulFeedEnabled = enabled)) }
    }

    fun clearAllUserData() {
        storageDir.listFiles().orEmpty().forEach { it.delete() }
        synchronized(lock) {
            val seeded = seedState(_state.value.settings)
            saveState(seeded)
            _state.value = seeded
        }
    }

    private fun importUri(uri: Uri, folderId: String): SavioItem? = runCatching {
        val now = System.currentTimeMillis()
        val mime = resolver.getType(uri).orEmpty()
        val displayName = queryDisplayName(uri).ifBlank { "savio-${UUID.randomUUID()}" }
        val extension = displayName.substringAfterLast('.', "").take(12)
        val storedName = buildString {
            append(UUID.randomUUID())
            if (extension.isNotBlank()) append('.').append(extension.lowercase(Locale.ROOT))
        }
        val destination = File(storageDir, storedName)
        resolver.openInputStream(uri)?.use { input ->
            destination.outputStream().use { output -> input.copyTo(output) }
        } ?: return null

        val type = when {
            mime.startsWith("image/") -> SavioItemType.IMAGE
            mime.startsWith("video/") -> SavioItemType.VIDEO
            else -> SavioItemType.FILE
        }
        SavioItem(
            id = UUID.randomUUID().toString(),
            folderId = validFolder(folderId),
            type = type,
            title = displayName.substringBeforeLast('.').ifBlank { displayName },
            originalName = displayName,
            mimeType = mime,
            localPath = destination.absolutePath,
            createdAt = now,
            updatedAt = now
        )
    }.getOrNull()

    private fun validFolder(folderId: String): String =
        if (_state.value.folders.any { it.id == folderId }) folderId else SavioIds.INBOX

    private fun queryDisplayName(uri: Uri): String {
        var cursor: Cursor? = null
        return try {
            cursor = resolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            if (cursor != null && cursor.moveToFirst()) cursor.getString(0).orEmpty() else ""
        } catch (_: Exception) {
            ""
        } finally {
            cursor?.close()
        }
    }

    private fun extractUrl(text: String): String? {
        val token = text.split(Regex("\\s+")).firstOrNull {
            it.startsWith("https://", true) || it.startsWith("http://", true)
        } ?: return null
        return token.trimEnd('.', ',', ')', ']', '}', ';')
    }

    private fun hostTitle(url: String): String = runCatching {
        Uri.parse(url).host.orEmpty().removePrefix("www.").ifBlank { url.take(80) }
    }.getOrDefault(url.take(80))

    private fun isEnglish(): Boolean = _state.value.settings.language == "en"

    private inline fun mutate(transform: (SavioState) -> SavioState) {
        synchronized(lock) {
            val updated = transform(_state.value)
            saveState(updated)
            _state.value = updated
        }
    }

    private fun loadState(): SavioState {
        if (!stateFile.exists()) return seedState()
        return runCatching {
            val decoded = decodeState(JSONObject(stateFile.readText(Charsets.UTF_8)))
            if (decoded.settings.designVersion < 2) {
                decoded.copy(settings = decoded.settings.copy(theme = "light", usefulFeedEnabled = false, designVersion = 2))
                    .also(::saveState)
            } else {
                decoded
            }
        }
            .getOrElse { seedState() }
    }

    private fun saveState(state: SavioState) {
        val temp = File(stateFile.parentFile, "${stateFile.name}.tmp")
        temp.writeText(encodeState(state).toString(), Charsets.UTF_8)
        if (stateFile.exists()) stateFile.delete()
        if (!temp.renameTo(stateFile)) {
            stateFile.writeText(temp.readText(Charsets.UTF_8), Charsets.UTF_8)
            temp.delete()
        }
    }

    private fun seedState(settings: SavioSettings = SavioSettings()): SavioState {
        val now = System.currentTimeMillis()
        return SavioState(
            folders = listOf(
                SavioFolder(SavioIds.INBOX, "Входящие", "#0B4DFF", "inbox", now, true),
                SavioFolder(SavioIds.IDEAS, "Идеи", "#7C5CFC", "spark", now + 1),
                SavioFolder(SavioIds.RECIPES, "Рецепты", "#FF8A3D", "recipe", now + 2),
                SavioFolder(SavioIds.TRAVEL, "Путешествия", "#18B989", "travel", now + 3),
                SavioFolder(SavioIds.WORK, "Работа", "#2684FF", "work", now + 4)
            ),
            items = emptyList(),
            settings = settings
        )
    }

    private fun encodeState(state: SavioState): JSONObject = JSONObject().apply {
        put("folders", JSONArray().apply {
            state.folders.forEach { folder ->
                put(JSONObject().apply {
                    put("id", folder.id)
                    put("name", folder.name)
                    put("color", folder.color)
                    put("glyph", folder.glyph)
                    put("createdAt", folder.createdAt)
                    put("isSystem", folder.isSystem)
                })
            }
        })
        put("items", JSONArray().apply {
            state.items.forEach { item ->
                put(JSONObject().apply {
                    put("id", item.id)
                    put("folderId", item.folderId)
                    put("type", item.type.name)
                    put("title", item.title)
                    put("description", item.description)
                    put("thought", item.thought)
                    put("originalName", item.originalName)
                    put("mimeType", item.mimeType)
                    put("localPath", item.localPath)
                    put("sourceUrl", item.sourceUrl)
                    put("createdAt", item.createdAt)
                    put("updatedAt", item.updatedAt)
                    put("isFavorite", item.isFavorite)
                    put("isArchived", item.isArchived)
                })
            }
        })
        put("settings", JSONObject().apply {
            put("language", state.settings.language)
            put("theme", state.settings.theme)
            put("usefulFeedEnabled", state.settings.usefulFeedEnabled)
            put("designVersion", state.settings.designVersion)
        })
    }

    private fun decodeState(root: JSONObject): SavioState {
        val foldersJson = root.optJSONArray("folders") ?: JSONArray()
        val itemsJson = root.optJSONArray("items") ?: JSONArray()
        val folders = buildList {
            for (index in 0 until foldersJson.length()) {
                val value = foldersJson.getJSONObject(index)
                add(SavioFolder(
                    id = value.getString("id"),
                    name = value.getString("name"),
                    color = value.optString("color", "#0B4DFF"),
                    glyph = value.optString("glyph", "folder"),
                    createdAt = value.optLong("createdAt", System.currentTimeMillis()),
                    isSystem = value.optBoolean("isSystem", false)
                ))
            }
        }.ifEmpty { seedState().folders }
        val items = buildList {
            for (index in 0 until itemsJson.length()) {
                val value = itemsJson.getJSONObject(index)
                add(SavioItem(
                    id = value.getString("id"),
                    folderId = value.optString("folderId", SavioIds.INBOX),
                    type = runCatching { SavioItemType.valueOf(value.optString("type")) }.getOrDefault(SavioItemType.FILE),
                    title = value.optString("title"),
                    description = value.optString("description"),
                    thought = value.optString("thought"),
                    originalName = value.optString("originalName"),
                    mimeType = value.optString("mimeType"),
                    localPath = value.optString("localPath"),
                    sourceUrl = value.optString("sourceUrl"),
                    createdAt = value.optLong("createdAt", System.currentTimeMillis()),
                    updatedAt = value.optLong("updatedAt", System.currentTimeMillis()),
                    isFavorite = value.optBoolean("isFavorite", false),
                    isArchived = value.optBoolean("isArchived", false)
                ))
            }
        }
        val settingsJson = root.optJSONObject("settings") ?: JSONObject()
        return SavioState(
            folders = folders,
            items = items,
            settings = SavioSettings(
                language = settingsJson.optString("language", "ru"),
                theme = settingsJson.optString("theme", "light"),
                usefulFeedEnabled = settingsJson.optBoolean("usefulFeedEnabled", false),
                designVersion = settingsJson.optInt("designVersion", 1)
            )
        )
    }

    companion object {
        @Volatile private var instance: SavioRepository? = null

        fun get(context: Context): SavioRepository = instance ?: synchronized(this) {
            instance ?: SavioRepository(context).also { instance = it }
        }
    }
}
