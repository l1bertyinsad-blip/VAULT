package com.nevsk1y.savio.ui

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.BorderStroke
import com.nevsk1y.savio.data.SavioItem
import com.nevsk1y.savio.data.SavioItemType
import com.nevsk1y.savio.data.SavioRepository
import com.nevsk1y.savio.data.SavioState
import com.nevsk1y.savio.ui.theme.SavioBlue
import com.nevsk1y.savio.ui.theme.SavioGreen

@Composable
fun ProfileScreen(
    state: SavioState,
    repository: SavioRepository,
    copy: SavioCopy,
    onNotes: () -> Unit,
    onArchive: () -> Unit
) {
    var confirmReset by remember { mutableStateOf(false) }
    LazyColumn(
        contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 12.dp, bottom = 118.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item { ScreenHeader(copy.t("Профиль", "Profile"), copy) }
        item {
            Surface(shape = RoundedCornerShape(28.dp), color = MaterialTheme.colorScheme.surface, tonalElevation = 1.dp) {
                Row(Modifier.fillMaxWidth().padding(18.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(58.dp).clip(CircleShape).background(SavioBlue), contentAlignment = Alignment.Center) {
                        SavioMark(Modifier.size(40.dp), Color.White)
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(copy.t("Моё пространство", "My space"), fontWeight = FontWeight.Black, fontSize = 19.sp)
                        Text(copy.t("Всё хранится на устройстве", "Everything stays on device"), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                    Surface(color = SavioGreen.copy(alpha = .12f), shape = RoundedCornerShape(99.dp)) {
                        Text(copy.t("Локально", "Local"), color = SavioGreen, fontWeight = FontWeight.Bold, fontSize = 11.sp, modifier = Modifier.padding(horizontal = 9.dp, vertical = 6.dp))
                    }
                }
            }
        }
        item {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                ProfileShortcut(Glyph.NOTE, copy.t("Заметки", "Notes"), state.items.count { it.type == SavioItemType.NOTE }, onNotes, Modifier.weight(1f))
                ProfileShortcut(Glyph.ARCHIVE, copy.t("Архив", "Archive"), state.items.count { it.isArchived }, onArchive, Modifier.weight(1f))
            }
        }
        item { SettingsGroupTitle(copy.t("Язык", "Language")) }
        item {
            Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
                Row(Modifier.fillMaxWidth().padding(8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    LanguageButton("RU", state.settings.language == "ru", { repository.setLanguage("ru") }, Modifier.weight(1f))
                    LanguageButton("EN", state.settings.language == "en", { repository.setLanguage("en") }, Modifier.weight(1f))
                }
            }
        }
        item { SettingsGroupTitle(copy.t("Оформление", "Appearance")) }
        item {
            Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
                Row(Modifier.fillMaxWidth().padding(8.dp), horizontalArrangement = Arrangement.spacedBy(7.dp)) {
                    ThemeButton(copy.t("Система", "System"), state.settings.theme == "system", { repository.setTheme("system") }, Modifier.weight(1f))
                    ThemeButton(copy.t("Светлая", "Light"), state.settings.theme == "light", { repository.setTheme("light") }, Modifier.weight(1f))
                    ThemeButton(copy.t("Тёмная", "Dark"), state.settings.theme == "dark", { repository.setTheme("dark") }, Modifier.weight(1f))
                }
            }
        }
        item {
            SettingRow(
                glyph = Glyph.STAR,
                title = copy.t("Полезный скроллинг", "Useful scrolling"),
                subtitle = copy.t("Конечная лента из 7 карточек", "A finite 7-card feed"),
                trailing = { Switch(state.settings.usefulFeedEnabled, repository::setUsefulFeedEnabled) }
            )
        }
        item {
            Surface(shape = RoundedCornerShape(24.dp), color = MaterialTheme.colorScheme.primaryContainer) {
                Row(Modifier.padding(18.dp), verticalAlignment = Alignment.Top) {
                    SavioGlyph(Glyph.LOCK, Modifier.size(25.dp), MaterialTheme.colorScheme.primary)
                    Spacer(Modifier.width(13.dp))
                    Column {
                        Text(copy.t("Приватность без мелкого шрифта", "Privacy without fine print"), fontWeight = FontWeight.Black)
                        Spacer(Modifier.height(5.dp))
                        Text(
                            copy.t("В этой версии нет аккаунта, рекламы и аналитических трекеров. Сохранённое лежит внутри приложения и попадает только в резервную копию Android, если она включена у тебя.", "This version has no account, ads or analytics trackers. Saved content stays in the app and only enters Android backup if you enable it."),
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            lineHeight = 20.sp
                        )
                    }
                }
            }
        }
        item {
            TextButton(onClick = { confirmReset = true }, modifier = Modifier.fillMaxWidth()) {
                SavioGlyph(Glyph.TRASH, Modifier.size(19.dp), MaterialTheme.colorScheme.error)
                Spacer(Modifier.width(8.dp))
                Text(copy.t("Удалить все данные", "Delete all data"), color = MaterialTheme.colorScheme.error, fontWeight = FontWeight.Bold)
            }
        }
        item {
            Text("SAVIO for Android · 1.0.0", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.labelMedium, modifier = Modifier.fillMaxWidth())
        }
    }

    if (confirmReset) AlertDialog(
        onDismissRequest = { confirmReset = false },
        title = { Text(copy.t("Очистить SAVIO?", "Clear SAVIO?"), fontWeight = FontWeight.Black) },
        text = { Text(copy.t("Все сохранённые файлы, ссылки, заметки и папки будут удалены с устройства.", "All saved files, links, notes and folders will be removed from this device.")) },
        confirmButton = { TextButton(onClick = { repository.clearAllUserData(); confirmReset = false }) { Text(copy.t("Удалить всё", "Delete everything"), color = MaterialTheme.colorScheme.error) } },
        dismissButton = { TextButton(onClick = { confirmReset = false }) { Text(copy.t("Отмена", "Cancel")) } }
    )
}

@Composable
private fun ProfileShortcut(glyph: Glyph, title: String, count: Int, onClick: () -> Unit, modifier: Modifier) {
    Surface(onClick = onClick, shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface, modifier = modifier) {
        Column(Modifier.padding(17.dp)) {
            SavioGlyph(glyph, Modifier.size(24.dp), SavioBlue)
            Spacer(Modifier.height(14.dp))
            Text(title, fontWeight = FontWeight.Black)
            Text(count.toString(), color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

@Composable
private fun SettingsGroupTitle(text: String) {
    Text(text.uppercase(), color = MaterialTheme.colorScheme.onSurfaceVariant, fontWeight = FontWeight.Black, fontSize = 11.sp, letterSpacing = .8.sp)
}

@Composable
private fun LanguageButton(text: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier) {
    Button(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(15.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = if (selected) SavioBlue else Color.Transparent,
            contentColor = if (selected) Color.White else MaterialTheme.colorScheme.onSurface
        ),
        elevation = ButtonDefaults.buttonElevation(0.dp)
    ) { Text(text, fontWeight = FontWeight.Black) }
}

@Composable
private fun ThemeButton(text: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier,
        shape = RoundedCornerShape(14.dp),
        border = if (selected) BorderStroke(1.5.dp, SavioBlue) else ButtonDefaults.outlinedButtonBorder,
        colors = ButtonDefaults.outlinedButtonColors(contentColor = if (selected) SavioBlue else MaterialTheme.colorScheme.onSurfaceVariant),
        contentPadding = PaddingValues(horizontal = 6.dp)
    ) { Text(text, fontSize = 12.sp, fontWeight = FontWeight.Bold, maxLines = 1) }
}

@Composable
private fun SettingRow(glyph: Glyph, title: String, subtitle: String, trailing: @Composable () -> Unit) {
    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface) {
        Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(42.dp).clip(RoundedCornerShape(13.dp)).background(MaterialTheme.colorScheme.primaryContainer), contentAlignment = Alignment.Center) {
                SavioGlyph(glyph, Modifier.size(21.dp), MaterialTheme.colorScheme.primary)
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, fontWeight = FontWeight.ExtraBold)
                Text(subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
            }
            trailing()
        }
    }
}

@Composable
fun ArchiveScreen(state: SavioState, copy: SavioCopy, onBack: () -> Unit, onOpenItem: (String) -> Unit, onRestore: (String) -> Unit) {
    val archived = state.items.filter { it.isArchived }
    Column(Modifier.fillMaxSize()) {
        ScreenHeader(copy.t("Архив", "Archive"), copy, onBack)
        if (archived.isEmpty()) EmptyState(Glyph.ARCHIVE, copy.t("Архив пуст", "Archive is empty"), copy.t("Сюда можно убрать материалы, которые пока не нужны.", "Keep items here when you do not need them right now."))
        else LazyColumn(contentPadding = PaddingValues(18.dp, 0.dp, 18.dp, 30.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(archived, key = { it.id }) { item ->
                ArchivedItemRow(item, copy, { onOpenItem(item.id) }, { onRestore(item.id) })
            }
        }
    }
}

@Composable
private fun ArchivedItemRow(item: SavioItem, copy: SavioCopy, onClick: () -> Unit, onRestore: () -> Unit) {
    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface, onClick = onClick) {
        Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            ItemPreview(item, Modifier.size(62.dp)); Spacer(Modifier.width(12.dp))
            Text(item.title, fontWeight = FontWeight.ExtraBold, modifier = Modifier.weight(1f), maxLines = 2)
            TextButton(onClick = onRestore) { Text(copy.t("Вернуть", "Restore")) }
        }
    }
}
