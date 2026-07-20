package com.nevsk1y.savio.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nevsk1y.savio.data.SavioIds
import com.nevsk1y.savio.data.SavioState
import com.nevsk1y.savio.ui.theme.SavioBlue
import com.nevsk1y.savio.ui.theme.SavioGreen
import com.nevsk1y.savio.ui.theme.SavioOrange
import com.nevsk1y.savio.ui.theme.SavioPurple

data class UsefulStory(
    val id: Int,
    val ruTitle: String,
    val enTitle: String,
    val ruBody: String,
    val enBody: String,
    val tagRu: String,
    val tagEn: String,
    val colorA: Color,
    val colorB: Color
)

val UsefulStories = listOf(
    UsefulStory(1, "Правило двух минут", "The two-minute rule", "Если действие занимает меньше двух минут — сделай его сразу.", "If it takes less than two minutes, do it now.", "ПРОДУКТИВНОСТЬ", "PRODUCTIVITY", Color(0xFF0B4DFF), Color(0xFF6C55FF)),
    UsefulStory(2, "Вкуснее без спешки", "Better without rushing", "Дай стейку отдохнуть 5–10 минут после жарки — сок останется внутри.", "Rest steak for 5–10 minutes after cooking to keep it juicy.", "ЕДА", "FOOD", Color(0xFFFF6B35), Color(0xFFFFB000)),
    UsefulStory(3, "Мозг помнит контекст", "Your brain remembers context", "Запиши одной строкой, зачем сохранил материал. Найти смысл будет легче.", "Write one line about why you saved it. Meaning becomes searchable.", "ИДЕИ", "IDEAS", Color(0xFF7C5CFC), Color(0xFFD457FF)),
    UsefulStory(4, "Скриншот — не система", "A screenshot is not a system", "Сохраняй сразу в папку и добавляй пару слов — так идея не потеряется.", "Save straight into a folder and add a few words so the idea survives.", "SAVIO", "SAVIO", Color(0xFF057A63), Color(0xFF18B989)),
    UsefulStory(5, "Путешествуй легче", "Travel lighter", "Храни брони, места и вдохновение в одной папке поездки.", "Keep bookings, places and inspiration in one trip folder.", "ПУТЕШЕСТВИЯ", "TRAVEL", Color(0xFF1376D3), Color(0xFF38BDF8)),
    UsefulStory(6, "Одна идея — одно действие", "One idea, one action", "Добавь к сохранённому материалу следующий шаг, даже самый маленький.", "Attach one next step to a saved item, even a tiny one.", "ФОКУС", "FOCUS", Color(0xFF6B4EFF), Color(0xFFB16CFF)),
    UsefulStory(7, "Лента закончилась", "The feed is complete", "Семь карточек достаточно. Теперь выбери одну и примени.", "Seven cards are enough. Pick one and use it.", "БЕЗ БЕСКОНЕЧНОГО СКРОЛЛА", "NO INFINITE SCROLL", Color(0xFF0B1020), Color(0xFF334155))
)

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
    onOpenFeed: () -> Unit
) {
    val visibleItems = state.items.filterNot { it.isArchived }
    val recentItems = visibleItems.sortedByDescending { it.createdAt }.take(5)
    val inboxCount = visibleItems.count { it.folderId == SavioIds.INBOX }
    val favorites = visibleItems.count { it.isFavorite }

    LazyColumn(
        modifier = Modifier.fillMaxWidth(),
        contentPadding = PaddingValues(start = 18.dp, end = 18.dp, top = 12.dp, bottom = 118.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp)
    ) {
        item {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                SavioWordmark(Modifier.weight(1f))
                SavioIconButton(Glyph.SEARCH, copy.t("Поиск", "Search"), onSearch)
            }
        }
        item { SavioHeroCard(copy, onAdd) }
        item {
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.fillMaxWidth()) {
                MetricCard(Glyph.INBOX, inboxCount.toString(), copy.t("Входящие", "Inbox"), SavioBlue, { onOpenFolder(SavioIds.INBOX) }, Modifier.weight(1f))
                MetricCard(Glyph.FILE, visibleItems.size.toString(), copy.t("Сохранено", "Saved"), SavioPurple, {}, Modifier.weight(1f))
                MetricCard(Glyph.STAR, favorites.toString(), copy.t("Избранное", "Favorites"), Color(0xFFFFB000), onOpenFavorites, Modifier.weight(1f))
            }
        }
        item { SectionHeader(copy.t("Мои папки", "My folders"), copy.t("Все", "All")) { } }
        item {
            LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp), contentPadding = PaddingValues(end = 6.dp)) {
                items(state.folders, key = { it.id }) { folder ->
                    FolderCard(
                        folder = folder,
                        count = visibleItems.count { it.folderId == folder.id },
                        copy = copy,
                        onClick = { onOpenFolder(folder.id) },
                        modifier = Modifier.width(154.dp)
                    )
                }
            }
        }
        if (state.settings.usefulFeedEnabled) {
            item { SectionHeader(copy.t("Полезный скроллинг", "Useful scrolling"), copy.t("7 карточек", "7 cards"), onOpenFeed) }
            item {
                UsefulPreviewCard(UsefulStories.first(), copy, onOpenFeed)
            }
        }
        item { SectionHeader(copy.t("Недавно сохранено", "Recently saved")) }
        if (recentItems.isEmpty()) {
            item {
                EmptyState(
                    Glyph.INBOX,
                    copy.t("Здесь появится важное", "Important things will appear here"),
                    copy.t("Нажми + или выбери SAVIO в меню «Поделиться» любого приложения.", "Tap + or choose SAVIO in another app's Share menu."),
                    copy.t("Сохранить первое", "Save the first one"),
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

@Composable
fun UsefulPreviewCard(story: UsefulStory, copy: SavioCopy, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(28.dp),
        color = Color.Transparent,
        modifier = modifier.fillMaxWidth()
    ) {
        Box(
            Modifier
                .background(Brush.linearGradient(listOf(story.colorA, story.colorB)))
                .padding(22.dp)
        ) {
            Column(Modifier.fillMaxWidth(.83f)) {
                Text(
                    if (copy.isEnglish) story.tagEn else story.tagRu,
                    color = Color.White.copy(alpha = .72f),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Black,
                    letterSpacing = .8.sp
                )
                Spacer(Modifier.height(15.dp))
                Text(
                    if (copy.isEnglish) story.enTitle else story.ruTitle,
                    color = Color.White,
                    fontWeight = FontWeight.Black,
                    fontSize = 24.sp,
                    lineHeight = 26.sp
                )
                Spacer(Modifier.height(8.dp))
                Text(
                    if (copy.isEnglish) story.enBody else story.ruBody,
                    color = Color.White.copy(alpha = .88f),
                    lineHeight = 20.sp,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis
                )
                Spacer(Modifier.height(18.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(copy.t("Листай с пользой", "Scroll with purpose"), color = Color.White, fontWeight = FontWeight.Bold)
                    Spacer(Modifier.width(9.dp))
                    Box(Modifier.size(26.dp).clip(RoundedCornerShape(9.dp)).background(Color.White.copy(alpha=.18f)), contentAlignment = Alignment.Center) {
                        SavioGlyph(Glyph.BACK, Modifier.size(13.dp), Color.White)
                    }
                }
            }
            SavioMark(Modifier.align(Alignment.TopEnd).size(64.dp), Color.White.copy(alpha = .18f))
        }
    }
}
