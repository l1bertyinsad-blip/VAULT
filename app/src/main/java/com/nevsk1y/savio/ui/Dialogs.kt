package com.nevsk1y.savio.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nevsk1y.savio.data.SavioFolder

enum class EditDialog { NONE, LINK, NOTE, CREATE_FOLDER }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QuickAddSheet(copy: SavioCopy, onDismiss: () -> Unit, onMedia: () -> Unit, onFiles: () -> Unit, onLink: () -> Unit, onNote: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, shape = RoundedCornerShape(topStart = 30.dp, topEnd = 30.dp)) {
        Column(Modifier.fillMaxWidth().padding(start = 18.dp, end = 18.dp, bottom = 34.dp)) {
            Text(copy.t("Что сохраним?", "What are we saving?"), fontWeight = FontWeight.Black, fontSize = 26.sp)
            Text(copy.t("Можно также выбрать SAVIO в меню «Поделиться». Ссылка из Instagram попадёт во Входящие.", "You can also choose SAVIO in any Share menu. An Instagram link goes to Inbox."), color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 7.dp, bottom = 17.dp))
            QuickAction(Glyph.IMAGE, copy.t("Фото или видео", "Photo or video"), copy.t("Системная галерея без доступа ко всей медиатеке", "System picker without full library access"), onMedia)
            HorizontalDivider(Modifier.padding(start = 58.dp))
            QuickAction(Glyph.FILE, copy.t("Файл", "File"), copy.t("PDF, документ, архив и другое", "PDF, document, archive and more"), onFiles)
            HorizontalDivider(Modifier.padding(start = 58.dp))
            QuickAction(Glyph.LINK, copy.t("Ссылка", "Link"), copy.t("Вставить рецепт, рилс или статью", "Paste a recipe, reel or article"), onLink)
            HorizontalDivider(Modifier.padding(start = 58.dp))
            QuickAction(Glyph.NOTE, copy.t("Заметка", "Note"), copy.t("Записать идею, пока не исчезла", "Catch an idea before it disappears"), onNote)
        }
    }
}

@Composable
private fun QuickAction(glyph: Glyph, title: String, subtitle: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Surface(shape = RoundedCornerShape(15.dp), color = MaterialTheme.colorScheme.primaryContainer) {
            SavioGlyph(glyph, Modifier.padding(12.dp).size(25.dp), MaterialTheme.colorScheme.primary)
        }
        Spacer(Modifier.width(13.dp))
        Column {
            Text(title, fontWeight = FontWeight.ExtraBold)
            Text(subtitle, color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
fun AddLinkDialog(copy: SavioCopy, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    var value by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(copy.t("Сохранить ссылку", "Save a link"), fontWeight = FontWeight.Black) },
        text = { OutlinedTextField(value, { value = it }, placeholder = { Text("https://…") }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp), minLines = 2) },
        confirmButton = { TextButton(enabled = value.isNotBlank(), onClick = { onSave(value) }) { Text(copy.t("Сохранить", "Save"), fontWeight = FontWeight.Bold) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(copy.t("Отмена", "Cancel")) } }
    )
}

@Composable
fun AddNoteDialog(copy: SavioCopy, onDismiss: () -> Unit, onSave: (String, String) -> Unit) {
    var title by remember { mutableStateOf("") }
    var body by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(copy.t("Новая заметка", "New note"), fontWeight = FontWeight.Black) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                OutlinedTextField(title, { title = it }, label = { Text(copy.t("Название", "Title")) }, modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(16.dp))
                OutlinedTextField(body, { body = it }, label = { Text(copy.t("Текст", "Text")) }, modifier = Modifier.fillMaxWidth(), minLines = 4, shape = RoundedCornerShape(16.dp))
            }
        },
        confirmButton = { TextButton(enabled = title.isNotBlank() || body.isNotBlank(), onClick = { onSave(title, body) }) { Text(copy.t("Сохранить", "Save"), fontWeight = FontWeight.Bold) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(copy.t("Отмена", "Cancel")) } }
    )
}

@Composable
fun FolderNameDialog(copy: SavioCopy, folder: SavioFolder? = null, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    var name by remember(folder?.id) { mutableStateOf(folder?.name.orEmpty()) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (folder == null) copy.t("Новая папка", "New folder") else copy.t("Переименовать папку", "Rename folder"), fontWeight = FontWeight.Black) },
        text = { OutlinedTextField(name, { name = it }, label = { Text(copy.t("Название", "Name")) }, modifier = Modifier.fillMaxWidth(), singleLine = true, shape = RoundedCornerShape(16.dp)) },
        confirmButton = { TextButton(enabled = name.isNotBlank(), onClick = { onSave(name) }) { Text(copy.t("Готово", "Done"), fontWeight = FontWeight.Bold) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(copy.t("Отмена", "Cancel")) } }
    )
}
