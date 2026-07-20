package com.nevsk1y.savio.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nevsk1y.savio.ui.theme.SavioBlue
import com.nevsk1y.savio.ui.theme.SavioBlueBright
import kotlinx.coroutines.delay

@Composable
fun BrandIntro(onFinished: () -> Unit) {
    val scale = remember { Animatable(.72f) }
    val alpha = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        alpha.animateTo(1f, tween(320))
        scale.animateTo(1f, tween(520, easing = FastOutSlowInEasing))
        delay(420)
        alpha.animateTo(0f, tween(260))
        onFinished()
    }
    Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.scale(scale.value).alpha(alpha.value)) {
            SavioMark(Modifier.size(112.dp))
            Spacer(Modifier.height(15.dp))
            Text("SAVIO", fontWeight = FontWeight.Black, fontSize = 34.sp, letterSpacing = (-1).sp)
            Text("Сохрани сейчас. Найди потом.", color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.padding(top = 5.dp))
        }
    }
}

private data class OnboardingPage(val glyph: Glyph, val titleRu: String, val titleEn: String, val bodyRu: String, val bodyEn: String, val colorA: Color, val colorB: Color)

private val onboardingPages = listOf(
    OnboardingPage(Glyph.LINK, "Не теряй полезное в скроллинге", "Don't lose useful things while scrolling", "Нажми «Поделиться» в Instagram, браузере или галерее — и выбери SAVIO.", "Tap Share in Instagram, your browser or gallery — then choose SAVIO.", Color(0xFF0B4DFF), Color(0xFF6C55FF)),
    OnboardingPage(Glyph.FOLDER, "Всё на своём месте", "Everything in its place", "Рецепты, идеи, поездки, работа. Раскладывай сразу или разбирай Входящие позже.", "Recipes, ideas, trips and work. File them now or sort Inbox later.", Color(0xFF7C5CFC), Color(0xFFFF6B8A)),
    OnboardingPage(Glyph.SEARCH, "Сохрани мысль, а не только файл", "Save the thought, not just the file", "Добавь описание: зачем сохранил и что хочешь сделать. Поиск вернёт идею в нужный момент.", "Add why you saved it and what to do next. Search brings the idea back when needed.", Color(0xFFFF7A30), Color(0xFFFFB000))
)

@Composable
fun Onboarding(copy: SavioCopy, onComplete: () -> Unit) {
    var page by remember { mutableIntStateOf(0) }
    val current = onboardingPages[page]
    Column(Modifier.fillMaxSize().padding(horizontal = 22.dp, vertical = 18.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            SavioWordmark(compact = true)
            if (page < onboardingPages.lastIndex) TextButton(onClick = onComplete) { Text(copy.t("Пропустить", "Skip")) }
        }
        Spacer(Modifier.weight(1f))
        AnimatedContent(
            targetState = current,
            transitionSpec = { (fadeIn(tween(260)) + scaleIn(initialScale = .96f)) togetherWith (fadeOut(tween(180)) + scaleOut(targetScale = 1.03f)) },
            label = "onboarding"
        ) { item ->
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Surface(
                    shape = RoundedCornerShape(42.dp),
                    color = Color.Transparent,
                    modifier = Modifier.size(238.dp)
                ) {
                    Box(Modifier.background(Brush.linearGradient(listOf(item.colorA, item.colorB))), contentAlignment = Alignment.Center) {
                        SavioGlyph(item.glyph, Modifier.size(92.dp), Color.White, 5.dp)
                        SavioMark(Modifier.align(Alignment.BottomEnd).padding(20.dp).size(56.dp), Color.White.copy(alpha = .22f))
                    }
                }
                Spacer(Modifier.height(32.dp))
                Text(
                    copy.t(item.titleRu, item.titleEn),
                    fontWeight = FontWeight.Black,
                    fontSize = 30.sp,
                    lineHeight = 33.sp,
                    textAlign = TextAlign.Center,
                    letterSpacing = (-.7).sp
                )
                Spacer(Modifier.height(13.dp))
                Text(
                    copy.t(item.bodyRu, item.bodyEn),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    lineHeight = 21.sp
                )
            }
        }
        Spacer(Modifier.weight(1f))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            onboardingPages.indices.forEach { index ->
                Box(
                    Modifier
                        .padding(horizontal = 4.dp)
                        .width(if (index == page) 28.dp else 8.dp)
                        .height(8.dp)
                        .background(if (index == page) SavioBlue else MaterialTheme.colorScheme.outline.copy(alpha = .45f), CircleShape)
                )
            }
        }
        Spacer(Modifier.height(22.dp))
        SavioPrimaryButton(
            if (page == onboardingPages.lastIndex) copy.t("Начать сохранять", "Start saving") else copy.t("Дальше", "Continue"),
            { if (page == onboardingPages.lastIndex) onComplete() else page++ },
            Modifier.fillMaxWidth()
        )
    }
}
