package com.nevsk1y.savio.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.nevsk1y.savio.data.SavioIds
import com.nevsk1y.savio.data.SavioState
import com.nevsk1y.savio.ui.theme.SavioBlue

@Composable
fun HomeScreen(
    state: SavioState,
    copy: SavioCopy,
    onAdd: () -> Unit,
    onSearch: () -> Unit,
    onOpenFolder: (String) -> Unit,
    onOpenItem: (String) -> Unit,
    onFavorite: (String) -> Unit,
    onOpenFavorites: () -> Unit,
    onOpenAllFolders: () -> Unit
) {
    val visibleItems = state.items.filterNot { it.isArchived }
    val recentItems = visibleItems.sortedByDescending { it.createdAt }.take(5)
    val inboxCount = visibleItems.count { it.folderId == SavioIds.INBOX }
    val favorites = visibleItems.count { it.isFavorite }
    val folderRows = state.folders
        .filterNot { it.id == SavioIds.INBOX }
        .take(4)
        .chunked(2)

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 16.dp, bottom = 126.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                SavioWordmark(Modifier.weight(1f))
                SavioIconButton(Glyph.SEARCH, copy.t("Поиск", "Search"), onSearch)
            }
        }

        item { SavioHeroCard(copy, onAdd) }

        item { SectionHeader(copy.t("Быстрый доступ", "Quick access")) }

        item {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                QuickAccessCard(
                    glyph = Glyph.INBOX,
                    value = copy.itemCount(inboxCount),
                    label = copy.t("Входящие", "Inbox"),
                    color = SavioBlue,
                    onClick = { onOpenFolder(SavioIds.INBOX) },
                    modifier = Modifier.weight(1f)
                )
                QuickAccessCard(
                    glyph = Glyph.STAR,
                    value = copy.itemCount(favorites),
                    label = copy.t("Избранное", "Favorites"),
                    color = Color(0xFFFFA928),
                    onClick = onOpenFavorites,
                    modifier = Modifier.weight(1f)
                )
            }
        }

        item {
            SectionHeader(
                title = copy.t("Мои папки", "My folders"),
                action = copy.t("Все", "All"),
                onAction = onOpenAllFolders
            )
        }

        items(folderRows, key = { row -> row.joinToString("-") { it.id } }) { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.fillMaxWidth()) {
                row.forEach { folder ->
                    FolderCard(
                        folder = folder,
                        count = visibleItems.count { it.folderId == folder.id },
                        copy = copy,
                        onClick = { onOpenFolder(folder.id) },
                        modifier = Modifier.weight(1f).height(154.dp)
                    )
                }
                if (row.size == 1) Spacer(Modifier.weight(1f))
            }
        }

        item { SectionHeader(copy.t("Недавно сохранено", "Recently saved")) }

        if (recentItems.isEmpty()) {
            item {
                EmptyState(
                    Glyph.INBOX,
                    copy.t("Сохрани что-нибудь важное", "Save something important"),
                    copy.t("Нажми + или выбери SAVIO в меню «Поделиться» в Instagram, браузере или галерее.", "Tap + or choose SAVIO from the Share menu in Instagram, your browser or gallery."),
                    copy.t("Добавить первое", "Add the first one"),
                    onAdd
                )
            }
        } else {
            items(recentItems, key = { it.id }) { item ->
                SavioItemCard(item, copy, { onOpenItem(item.id) }, { onFavorite(item.id) })
            }
        }
    }
}
