package com.nevsk1y.savio.ui

import android.graphics.BitmapFactory
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
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
            .size(50.dp)
            .clip(RoundedCornerShape(17.dp))
            .background(MaterialTheme.colorScheme.surface)
            .semantics { contentDescription = label }
    ) {
        SavioGlyph(glyph, Modifier.size(25.dp), color = MaterialTheme.colorScheme.onSurface, stroke = 2.25.dp)
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
    val motion = rememberInfiniteTransition(label = "hero-motion")
    val glowPosition by motion.animateFloat(
        initialValue = .68f,
        targetValue = .92f,
        animationSpec = infiniteRepeatable(tween(5200, easing = LinearEasing), RepeatMode.Reverse),
        label = "hero-glow"
    )
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(32.dp),
        colors = CardDefaults.cardColors(containerColor = Color.Transparent)
    ) {
        Box(
            Modifier
                .fillMaxWidth()
                .background(
                    Brush.linearGradient(
                        listOf(Color(0xFF075CFF), Color(0xFF315BFF), Color(0xFF7654F6))
                    )
                )
                .padding(horizontal = 25.dp, vertical = 27.dp)
        ) {
            Canvas(Modifier.matchParentSize()) {
                drawCircle(
                    color = Color.White.copy(alpha = .065f),
                    radius = size.width * .26f,
                    center = androidx.compose.ui.geometry.Offset(size.width * glowPosition, size.height * .34f)
                )
            }
            Column(Modifier.fillMaxWidth()) {
                Text(
                    copy.t("Всё важное —\nв одном месте.", "Everything important —\nin one place."),
                    color = Color.White,
                    fontSize = 31.sp,
                    lineHeight = 33.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = (-.9).sp
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    copy.t("Рилсы, рецепты, идеи и файлы. Сохраняй за одно касание — находи без поисков по чатам.", "Reels, recipes, ideas and files. Save in one tap and find without digging through chats."),
                    color = Color.White.copy(alpha = .88f),
                    fontSize = 16.sp,
                    lineHeight = 22.sp,
                    modifier = Modifier.fillMaxWidth(.93f)
                )
                Spacer(Modifier.height(23.dp))
                Button(
                    onClick = onAdd,
                    modifier = Modifier.height(52.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color.White, contentColor = SavioBlue),
                    shape = RoundedCornerShape(17.dp),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 19.dp)
                ) {
                    SavioGlyph(Glyph.PLUS, Modifier.size(20.dp), color = SavioBlue, stroke = 2.4.dp)
                    Spacer(Modifier.width(9.dp))
                    Text(copy.t("Добавить в SAVIO", "Add to SAVIO"), fontWeight = FontWeight.ExtraBold, fontSize = 15.sp)
                }
            }
        }
    }
}

@Composable
fun QuickAccessCard(glyph: Glyph, value: String, label: String, color: Color, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(25.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 0.dp,
        shadowElevation = 1.dp,
        modifier = modifier.animateContentSize()
    ) {
        Row(Modifier.padding(17.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier
                    .size(53.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .background(Brush.linearGradient(listOf(color, color.copy(alpha = .72f)))),
                contentAlignment = Alignment.Center
            ) {
                SavioGlyph(glyph, Modifier.size(27.dp), Color.White, stroke = 2.25.dp)
            }
            Spacer(Modifier.width(13.dp))
            Column(Modifier.weight(1f)) {
                Text(label, fontWeight = FontWeight.ExtraBold, fontSize = 16.sp, maxLines = 1)
                Spacer(Modifier.height(3.dp))
                Text(value, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
            }
        }
    }
}

@Composable
fun FolderCard(folder: SavioFolder, count: Int, copy: SavioCopy, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val folderColor = parseColor(folder.color)
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(27.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 0.dp,
        shadowElevation = 1.dp,
        modifier = modifier.animateContentSize()
    ) {
        Column(Modifier.padding(horizontal = 18.dp, vertical = 17.dp)) {
            Box(
                Modifier
                    .size(58.dp)
                    .clip(RoundedCornerShape(19.dp))
                    .background(Brush.linearGradient(listOf(folderColor, folderColor.copy(alpha = .72f)))),
                contentAlignment = Alignment.Center
            ) {
                SavioGlyph(
                    if (folder.isSystem) Glyph.INBOX else Glyph.FOLDER,
                    Modifier.size(30.dp),
                    Color.White,
                    stroke = 2.35.dp
                )
            }
            Spacer(Modifier.height(14.dp))
            Text(folder.displayName(copy), fontWeight = FontWeight.ExtraBold, fontSize = 17.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Spacer(Modifier.height(4.dp))
            Text(copy.itemCount(count), color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
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
        modifier = modifier.fillMaxWidth().animateContentSize(),
        shape = RoundedCornerShape(25.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 0.dp,
        shadowElevation = 1.dp
    ) {
        Row(Modifier.padding(13.dp), verticalAlignment = Alignment.CenterVertically) {
            ItemPreview(item, Modifier.size(82.dp))
            Spacer(Modifier.width(15.dp))
            Column(Modifier.weight(1f)) {
                Text(item.title, fontWeight = FontWeight.ExtraBold, fontSize = 16.sp, maxLines = 2, overflow = TextOverflow.Ellipsis)
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
                val commentPreview = item.description.ifBlank { item.thought }
                if (commentPreview.isNotBlank()) {
                    Spacer(Modifier.height(5.dp))
                    Text(commentPreview, color = SavioBlue, style = MaterialTheme.typography.bodySmall, maxLines = 1, overflow = TextOverflow.Ellipsis)
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
