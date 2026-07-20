package com.nevsk1y.savio.ui

import android.graphics.BitmapFactory
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.foundation.Image
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nevsk1y.savio.data.SavioFolder
import com.nevsk1y.savio.data.SavioItem
import com.nevsk1y.savio.data.SavioItemType
import com.nevsk1y.savio.ui.theme.SavioBlue
import com.nevsk1y.savio.ui.theme.SavioBlueBright
import com.nevsk1y.savio.ui.theme.SavioMuted
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.text.DateFormat
import java.util.Date

@Composable
fun SavioPrimaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Button(
        onClick = onClick,
        modifier = modifier.height(52.dp),
        shape = RoundedCornerShape(18.dp),
        colors = ButtonDefaults.buttonColors(containerColor = SavioBlue)
    ) {
        Text(text, fontWeight = FontWeight.Bold, fontSize = 16.sp)
    }
}

@Composable
fun SavioIconButton(glyph: Glyph, label: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    IconButton(
        onClick = onClick,
        modifier = modifier
            .size(46.dp)
            .clip(RoundedCornerShape(15.dp))
            .background(MaterialTheme.colorScheme.surface)
            .semantics { contentDescription = label }
    ) {
        SavioGlyph(glyph, Modifier.size(22.dp), color = MaterialTheme.colorScheme.onSurface)
    }
}

@Composable
fun SectionHeader(title: String, action: String? = null, onAction: (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.ExtraBold)
        if (action != null && onAction != null) {
            Text(
                action,
                color = SavioBlue,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
                    .clickable(onClick = onAction)
                    .padding(horizontal = 8.dp, vertical = 6.dp)
            )
        }
    }
}

@Composable
fun SavioHeroCard(copy: SavioCopy, onAdd: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(30.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Box(
            Modifier
                .background(
                    Brush.linearGradient(
                        listOf(SavioBlue, SavioBlueBright, Color(0xFF6A5CFF))
                    )
                )
                .padding(24.dp)
        ) {
            Canvas(Modifier.matchParentSize()) {
                drawCircle(Color.White.copy(alpha = .08f), radius = size.width * .42f, center = androidx.compose.ui.geometry.Offset(size.width * .96f, size.height * .08f))
                drawCircle(Color.White.copy(alpha = .06f), radius = size.width * .28f, center = androidx.compose.ui.geometry.Offset(size.width * .86f, size.height * .9f))
            }
            Column(Modifier.fillMaxWidth(.78f)) {
                Surface(color = Color.White.copy(alpha = .16f), shape = RoundedCornerShape(99.dp)) {
                    Text(
                        copy.t("ТВОЯ ПАМЯТЬ, НО УДОБНЕЕ", "YOUR MEMORY, BUT EASIER"),
                        color = Color.White,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = .7.sp,
                        modifier = Modifier.padding(horizontal = 11.dp, vertical = 7.dp)
                    )
                }
                Spacer(Modifier.height(18.dp))
                Text(
                    copy.t("Сохраняй сейчас.\nНаходи потом.", "Save now.\nFind it later."),
                    color = Color.White,
                    fontSize = 29.sp,
                    lineHeight = 31.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = (-.7).sp
                )
                Spacer(Modifier.height(10.dp))
                Text(
                    copy.t("Рилсы, рецепты, идеи, фото и файлы — всё в одном месте.", "Reels, recipes, ideas, photos and files — all in one place."),
                    color = Color.White.copy(alpha = .84f),
                    lineHeight = 20.sp
                )
                Spacer(Modifier.height(20.dp))
                Button(
                    onClick = onAdd,
                    colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = SavioBlue),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    SavioGlyph(Glyph.PLUS, Modifier.size(18.dp), color = SavioBlue)
                    Spacer(Modifier.width(8.dp))
                    Text(copy.t("Сохранить", "Save"), fontWeight = FontWeight.ExtraBold)
                }
            }
            SavioMark(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .size(90.dp),
                color = Color.White.copy(alpha = .22f)
            )
        }
    }
}

@Composable
fun MetricCard(glyph: Glyph, value: String, label: String, color: Color, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(20.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp,
        modifier = modifier
    ) {
        Column(Modifier.padding(15.dp)) {
            Box(
                Modifier
                    .size(34.dp)
                    .clip(RoundedCornerShape(11.dp))
                    .background(color.copy(alpha = .12f)),
                contentAlignment = Alignment.Center
            ) {
                SavioGlyph(glyph, Modifier.size(18.dp), color)
            }
            Spacer(Modifier.height(12.dp))
            Text(value, fontWeight = FontWeight.Black, fontSize = 22.sp)
            Text(label, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
        }
    }
}

@Composable
fun FolderCard(folder: SavioFolder, count: Int, copy: SavioCopy, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val folderColor = parseColor(folder.color)
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(24.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp,
        modifier = modifier
    ) {
        Column(Modifier.padding(17.dp)) {
            Box(
                Modifier
                    .size(49.dp)
                    .clip(RoundedCornerShape(16.dp))
                    .background(Brush.linearGradient(listOf(folderColor, folderColor.copy(alpha = .72f)))),
                contentAlignment = Alignment.Center
            ) {
                SavioGlyph(if (folder.isSystem) Glyph.INBOX else Glyph.FOLDER, Modifier.size(25.dp), Color.White)
            }
            Spacer(Modifier.height(16.dp))
            Text(folder.displayName(copy), fontWeight = FontWeight.ExtraBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Spacer(Modifier.height(3.dp))
            Text(copy.itemCount(count), color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
        }
    }
}

@Composable
fun SavioItemCard(
    item: SavioItem,
    copy: SavioCopy,
    onClick: () -> Unit,
    onFavorite: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(22.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp
    ) {
        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
            ItemPreview(item, Modifier.size(74.dp))
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(item.title, fontWeight = FontWeight.ExtraBold, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Spacer(Modifier.height(4.dp))
                val subtitle = when (item.type) {
                    SavioItemType.IMAGE -> copy.t("Фото", "Photo")
                    SavioItemType.VIDEO -> copy.t("Видео", "Video")
                    SavioItemType.FILE -> copy.t("Файл", "File")
                    SavioItemType.LINK -> copy.t("Ссылка", "Link")
                    SavioItemType.NOTE -> copy.t("Заметка", "Note")
                }
                Text(
                    "$subtitle · ${DateFormat.getDateInstance(DateFormat.SHORT).format(Date(item.createdAt))}",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodySmall
                )
                if (item.thought.isNotBlank()) {
                    Spacer(Modifier.height(5.dp))
                    Text("“${item.thought}”", color = SavioBlue, style = MaterialTheme.typography.bodySmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }
            IconButton(onClick = onFavorite) {
                SavioGlyph(
                    Glyph.STAR,
                    Modifier.size(22.dp),
                    color = if (item.isFavorite) Color(0xFFFFB800) else MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}

@Composable
fun ItemPreview(item: SavioItem, modifier: Modifier = Modifier) {
    val bitmap by localBitmap(item.localPath)
    val glyph = when (item.type) {
        SavioItemType.IMAGE -> Glyph.IMAGE
        SavioItemType.VIDEO -> Glyph.VIDEO
        SavioItemType.FILE -> Glyph.FILE
        SavioItemType.LINK -> Glyph.LINK
        SavioItemType.NOTE -> Glyph.NOTE
    }
    Box(
        modifier
            .clip(RoundedCornerShape(17.dp))
            .background(
                if (item.type == SavioItemType.NOTE) Color(0xFFFFF3C8)
                else if (item.type == SavioItemType.LINK) Color(0xFFE6ECFF)
                else MaterialTheme.colorScheme.surfaceVariant
            ),
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null && item.type == SavioItemType.IMAGE) {
            Image(bitmap!!, contentDescription = item.title, modifier = Modifier.matchParentSize(), contentScale = ContentScale.Crop)
        } else {
            SavioGlyph(glyph, Modifier.size(31.dp), color = if (item.type == SavioItemType.NOTE) Color(0xFFE09B00) else SavioBlue)
        }
    }
}

@Composable
private fun localBitmap(path: String) = produceState<ImageBitmap?>(initialValue = null, key1 = path) {
    value = if (path.isBlank() || !File(path).exists()) null else withContext(Dispatchers.IO) {
        runCatching {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            var sample = 1
            while (bounds.outWidth / sample > 720 || bounds.outHeight / sample > 720) sample *= 2
            BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })?.asImageBitmap()
        }.getOrNull()
    }
}

@Composable
fun EmptyState(glyph: Glyph, title: String, body: String, action: String? = null, onAction: (() -> Unit)? = null) {
    Column(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 30.dp, vertical = 42.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            Modifier
                .size(76.dp)
                .clip(RoundedCornerShape(25.dp))
                .background(MaterialTheme.colorScheme.primaryContainer),
            contentAlignment = Alignment.Center
        ) {
            SavioGlyph(glyph, Modifier.size(36.dp), MaterialTheme.colorScheme.primary)
        }
        Spacer(Modifier.height(19.dp))
        Text(title, fontWeight = FontWeight.Black, fontSize = 20.sp)
        Spacer(Modifier.height(7.dp))
        Text(body, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = androidx.compose.ui.text.style.TextAlign.Center, lineHeight = 20.sp)
        if (action != null && onAction != null) {
            Spacer(Modifier.height(20.dp))
            SavioPrimaryButton(action, onAction)
        }
    }
}

fun parseColor(value: String): Color = runCatching { Color(android.graphics.Color.parseColor(value)) }.getOrDefault(SavioBlue)
