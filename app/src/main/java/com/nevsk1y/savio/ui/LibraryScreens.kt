package com.nevsk1y.savio.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import com.nevsk1y.savio.BuildConfig
import com.nevsk1y.savio.data.SavioFolder
import com.nevsk1y.savio.data.SavioItem
import com.nevsk1y.savio.data.SavioItemType
import com.nevsk1y.savio.data.SavioRepository
import com.nevsk1y.savio.data.SavioState
import com.nevsk1y.savio.ui.theme.SavioBlue
import java.io.File

@Composable
fun ScreenHeader(title: String, copy: SavioCopy, onBack: (() -> Unit)? = null, action: Pair<Glyph, () -> Unit>? = null) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 18.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (onBack != null) {
            SavioIconButton(Glyph.BACK, copy.t("Назад", "Back"), onBack)
            Spacer(Modifier.width(12.dp))
        }
        Text(title, fontWeight = FontWeight.Black, fontSize = 28.sp, letterSpacing = (-.5).sp, modifier = Modifier.weight(1f), maxLines = 1, overflow = TextOverflow.Ellipsis)
        if (action != null) SavioIconButton(action.first, copy.t("Действие", "Action"), action.second)
    }
}

@Composable
fun FoldersScreen(state: SavioState, copy: SavioCopy, onOpenFolder: (String) -> Unit, onCreateFolder: () -> Unit) {
    Column(Modifier.fillMaxSize()) {
        ScreenHeader(copy.t("Мои папки", "My folders"), copy, action = Glyph.PLUS to onCreateFolder)
        Text(
            copy.t("Порядок для всего, что хочется не потерять.", "A home for everything worth keeping."),
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(horizontal = 18.dp)
        )
        Spacer(Modifier.height(16.dp))
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            contentPadding = PaddingValues(start = 18.dp, end = 18.dp, bottom = 118.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(state.folders, key = { it.id }) { folder ->
                FolderCard(folder, state.items.count { it.folderId == folder.id && !it.isArchived }, copy, { onOpenFolder(folder.id) })
            }
        }
    }
}

@Composable
fun FavoritesScreen(state: SavioState, copy: SavioCopy, onOpenItem: (String) -> Unit, onFavorite: (String) -> Unit) {
    val items = state.items.filter { it.isFavorite && !it.isArchived }.sortedByDescending { it.updatedAt }
    Column(Modifier.fillMaxSize()) {
        ScreenHeader(copy.t("Избранное", "Favorites"), copy)
        if (items.isEmpty()) {
            EmptyState(
                Glyph.STAR,
                copy.t("Пока пусто", "Nothing here yet"),
                copy.t("Отмечай звёздочкой идеи, к которым точно захочешь вернуться.", "Star ideas you definitely want to revisit.")
            )
        } else {
            LazyColumn(
                contentPadding = PaddingValues(start = 18.dp, end = 18.dp, bottom = 118.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(items, key = { it.id }) { item -> SavioItemCard(item, copy, { onOpenItem(item.id) }, { onFavorite(item.id) }) }
            }
        }
    }
}

@Composable
fun FolderDetailScreen(
    folderId: String,
    state: SavioState,
    copy: SavioCopy,
    onBack: () -> Unit,
    onOpenItem: (String) -> Unit,
    onFavorite: (String) -> Unit,
    onAdd: () -> Unit,
    onRename: (SavioFolder) -> Unit
) {
    val folder = state.folders.firstOrNull { it.id == folderId }
    val folderItems = state.items.filter { it.folderId == folderId && !it.isArchived }.sortedByDescending { it.createdAt }
    Column(Modifier.fillMaxSize()) {
        ScreenHeader(folder?.displayName(copy) ?: copy.t("Папка", "Folder"), copy, onBack, folder?.let { Glyph.EDIT to { onRename(it) } })
        if (folderItems.isEmpty()) {
            EmptyState(
                if (folder?.isSystem == true) Glyph.INBOX else Glyph.FOLDER,
                copy.t("В этой папке просторно", "This folder has room"),
                copy.t("Добавь фото, видео, ссылку, файл или заметку.", "Add a photo, video, link, file or note."),
                copy.t("Добавить", "Add"),
                onAdd
            )
        } else {
            LazyColumn(
                contentPadding = PaddingValues(start = 18.dp, end = 18.dp, bottom = 112.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(folderItems, key = { it.id }) { item ->
                    SavioItemCard(item, copy, { onOpenItem(item.id) }, { onFavorite(item.id) })
                }
            }
        }
    }
}

@Composable
fun SearchScreen(state: SavioState, copy: SavioCopy, onBack: () -> Unit, onOpenItem: (String) -> Unit, onFavorite: (String) -> Unit) {
    var query by remember { mutableStateOf("") }
    val normalized = query.trim()
    val results = state.items.filterNot { it.isArchived }.filter {
        normalized.isBlank() || listOf(it.title, it.description, it.thought, it.sourceUrl, it.originalName).any { field -> field.contains(normalized, ignoreCase = true) }
    }
    Column(Modifier.fillMaxSize()) {
        ScreenHeader(copy.t("Найти в SAVIO", "Search SAVIO"), copy, onBack)
        OutlinedTextField(
            value = query,
            onValueChange = { query = it },
            modifier = Modifier.fillMaxWidth().padding(horizontal = 18.dp),
            placeholder = { Text(copy.t("Идея, рецепт, ссылка…", "Idea, recipe, link…")) },
            leadingIcon = { SavioGlyph(Glyph.SEARCH, Modifier.size(21.dp), MaterialTheme.colorScheme.onSurfaceVariant) },
            singleLine = true,
            shape = RoundedCornerShape(18.dp)
        )
        Spacer(Modifier.height(14.dp))
        if (results.isEmpty()) {
            EmptyState(Glyph.SEARCH, copy.t("Ничего не найдено", "Nothing found"), copy.t("Попробуй другое слово или добавь описание к материалу.", "Try another word or add a description to the item."))
        } else {
            LazyColumn(
                contentPadding = PaddingValues(start = 18.dp, end = 18.dp, bottom = 30.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                item { Text(copy.t("Найдено: ${results.size}", "Found: ${results.size}"), color = MaterialTheme.colorScheme.onSurfaceVariant, fontWeight = FontWeight.Bold) }
                items(results, key = { it.id }) { item -> SavioItemCard(item, copy, { onOpenItem(item.id) }, { onFavorite(item.id) }) }
            }
        }
    }
}

@Composable
fun NotesScreen(state: SavioState, copy: SavioCopy, onBack: () -> Unit, onOpenItem: (String) -> Unit, onFavorite: (String) -> Unit, onAddNote: () -> Unit) {
    val notes = state.items.filter { it.type == SavioItemType.NOTE && !it.isArchived }
    Column(Modifier.fillMaxSize()) {
        ScreenHeader(copy.t("Заметки", "Notes"), copy, onBack, Glyph.PLUS to onAddNote)
        if (notes.isEmpty()) EmptyState(Glyph.NOTE, copy.t("Мысли любят запись", "Thoughts like being written down"), copy.t("Создай короткую заметку — её можно положить в любую папку.", "Create a quick note and keep it in any folder."), copy.t("Новая заметка", "New note"), onAddNote)
        else LazyColumn(contentPadding = PaddingValues(18.dp, 0.dp, 18.dp, 30.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(notes, key = { it.id }) { item -> SavioItemCard(item, copy, { onOpenItem(item.id) }, { onFavorite(item.id) }) }
        }
    }
}

@Composable
fun ItemDetailScreen(itemId: String, state: SavioState, repository: SavioRepository, copy: SavioCopy, onBack: () -> Unit) {
    val item = state.items.firstOrNull { it.id == itemId }
    if (item == null) {
        Column { ScreenHeader(copy.t("Материал", "Item"), copy, onBack); EmptyState(Glyph.FILE, copy.t("Материал не найден", "Item not found"), "") }
        return
    }
    val context = LocalContext.current
    var title by remember(item.id, item.updatedAt) { mutableStateOf(item.title) }
    var description by remember(item.id, item.updatedAt) { mutableStateOf(item.description) }
    var thought by remember(item.id, item.updatedAt) { mutableStateOf(item.thought) }
    var folderMenu by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }
    val folderName = state.folders.firstOrNull { it.id == item.folderId }?.displayName(copy).orEmpty()

    LazyColumn(contentPadding = PaddingValues(bottom = 34.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
        item { ScreenHeader(item.title, copy, onBack, Glyph.STAR to { repository.toggleFavorite(item.id) }) }
        item {
            Box(Modifier.padding(horizontal = 18.dp).fillMaxWidth().height(220.dp)) {
                ItemPreview(item, Modifier.fillMaxSize())
                if (item.isFavorite) {
                    Surface(shape = RoundedCornerShape(12.dp), color = Color(0xFFFFB800), modifier = Modifier.align(Alignment.TopEnd).padding(12.dp)) {
                        SavioGlyph(Glyph.STAR, Modifier.padding(8.dp).size(20.dp), Color.White)
                    }
                }
            }
        }
        item {
            Column(Modifier.padding(horizontal = 18.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(title, { title = it }, Modifier.fillMaxWidth(), label = { Text(copy.t("Название", "Title")) }, shape = RoundedCornerShape(17.dp))
                OutlinedTextField(description, { description = it }, Modifier.fillMaxWidth(), label = { Text(copy.t("Описание", "Description")) }, minLines = 3, shape = RoundedCornerShape(17.dp))
                OutlinedTextField(thought, { thought = it }, Modifier.fillMaxWidth(), label = { Text(copy.t("Почему я это сохранил", "Why I saved this")) }, minLines = 2, shape = RoundedCornerShape(17.dp))
                SavioPrimaryButton(copy.t("Сохранить изменения", "Save changes"), { repository.updateItem(item.id, title, description, thought) }, Modifier.fillMaxWidth())
            }
        }
        item {
            Column(Modifier.padding(horizontal = 18.dp)) {
                Text(copy.t("Расположение", "Location"), fontWeight = FontWeight.ExtraBold)
                Spacer(Modifier.height(8.dp))
                Box {
                    OutlinedButton(onClick = { folderMenu = true }, shape = RoundedCornerShape(15.dp)) {
                        SavioGlyph(Glyph.FOLDER, Modifier.size(19.dp), SavioBlue)
                        Spacer(Modifier.width(8.dp))
                        Text(folderName.ifBlank { copy.t("Входящие", "Inbox") })
                    }
                    DropdownMenu(folderMenu, { folderMenu = false }) {
                        state.folders.forEach { folder ->
                            DropdownMenuItem(
                                text = { Text(folder.displayName(copy)) },
                                onClick = { repository.moveItem(item.id, folder.id); folderMenu = false }
                            )
                        }
                    }
                }
            }
        }
        item {
            Row(Modifier.padding(horizontal = 18.dp).fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedButton(onClick = { openItem(context, item) }, modifier = Modifier.weight(1f), shape = RoundedCornerShape(15.dp)) {
                    SavioGlyph(if (item.type == SavioItemType.LINK) Glyph.LINK else Glyph.FILE, Modifier.size(18.dp), SavioBlue)
                    Spacer(Modifier.width(7.dp)); Text(copy.t("Открыть", "Open"))
                }
                OutlinedButton(onClick = { repository.toggleArchive(item.id); onBack() }, modifier = Modifier.weight(1f), shape = RoundedCornerShape(15.dp)) {
                    SavioGlyph(Glyph.ARCHIVE, Modifier.size(18.dp), SavioBlue)
                    Spacer(Modifier.width(7.dp)); Text(copy.t("В архив", "Archive"))
                }
            }
        }
        item {
            TextButton(onClick = { confirmDelete = true }, modifier = Modifier.fillMaxWidth()) {
                SavioGlyph(Glyph.TRASH, Modifier.size(18.dp), MaterialTheme.colorScheme.error)
                Spacer(Modifier.width(8.dp)); Text(copy.t("Удалить материал", "Delete item"), color = MaterialTheme.colorScheme.error)
            }
        }
    }

    if (confirmDelete) AlertDialog(
        onDismissRequest = { confirmDelete = false },
        title = { Text(copy.t("Удалить безвозвратно?", "Delete permanently?"), fontWeight = FontWeight.Black) },
        text = { Text(copy.t("Файл и описание будут удалены с устройства.", "The file and its description will be removed from this device.")) },
        confirmButton = { TextButton(onClick = { repository.deleteItem(item.id); confirmDelete = false; onBack() }) { Text(copy.t("Удалить", "Delete"), color = MaterialTheme.colorScheme.error) } },
        dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text(copy.t("Отмена", "Cancel")) } }
    )
}

private fun openItem(context: android.content.Context, item: SavioItem) {
    val intent = when {
        item.sourceUrl.isNotBlank() -> Intent(Intent.ACTION_VIEW, Uri.parse(item.sourceUrl))
        item.localPath.isNotBlank() && File(item.localPath).exists() -> {
            val uri = FileProvider.getUriForFile(context, "${BuildConfig.APPLICATION_ID}.files", File(item.localPath))
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, item.mimeType.ifBlank { "*/*" })
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
        }
        else -> null
    }
    if (intent != null) runCatching { context.startActivity(intent) }
}
