package com.nevsk1y.savio.ui

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
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
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nevsk1y.savio.R
import com.nevsk1y.savio.ui.theme.SavioBlue
import kotlinx.coroutines.delay

@Composable
fun BrandIntro(onFinished: () -> Unit) {
    val scale = remember { Animatable(.78f) }
    val alpha = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        alpha.animateTo(1f, tween(300))
        scale.animateTo(1f, tween(540, easing = FastOutSlowInEasing))
        delay(520)
        alpha.animateTo(0f, tween(240))
        onFinished()
    }
    Box(
        Modifier
            .fillMaxSize()
            .background(Brush.linearGradient(listOf(Color(0xFF0766FF), Color(0xFF304DFF), Color(0xFF7049F5)))),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.scale(scale.value).alpha(alpha.value)) {
            Box(Modifier.size(150.dp), contentAlignment = Alignment.Center) {
                SavioMark(Modifier.size(118.dp), Color.White)
            }
            Spacer(Modifier.height(10.dp))
            Text("SAVIO", color = Color.White, fontWeight = FontWeight.Black, fontSize = 38.sp, letterSpacing = (-1.2).sp)
            Text(
                "Сохраняй важное. Возвращайся к идеям.",
                color = Color.White.copy(alpha = .78f),
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(top = 7.dp)
            )
        }
    }
}

private data class OnboardingPage(
    val imageRes: Int,
    val glyph: Glyph,
    val titleRu: String,
    val titleEn: String,
    val bodyRu: String,
    val bodyEn: String,
    val chipOneRu: String,
    val chipOneEn: String,
    val chipTwoRu: String,
    val chipTwoEn: String,
    val colorA: Color,
    val colorB: Color
)

private val onboardingPages = listOf(
    OnboardingPage(R.drawable.onboarding_save, Glyph.LINK, "Сохраняй прямо из ленты", "Save straight from your feed", "Нажми «Поделиться» в Instagram, браузере или галерее — и выбери SAVIO.", "Tap Share in Instagram, your browser or gallery — then choose SAVIO.", "Instagram", "Instagram", "Сохранено", "Saved", Color(0xFF0766FF), Color(0xFF694BFA)),
    OnboardingPage(R.drawable.onboarding_organize, Glyph.FOLDER, "Каждая идея на своём месте", "Every idea in its place", "Рецепты, поездки и вдохновение лежат в понятных папках, а не теряются среди скриншотов.", "Recipes, trips and inspiration live in clear folders instead of getting lost among screenshots.", "Идеи", "Ideas", "Рецепты", "Recipes", Color(0xFF694BFA), Color(0xFF9A55F7)),
    OnboardingPage(R.drawable.onboarding_comment, Glyph.EDIT, "Добавляй свою мысль", "Add your own thought", "Оставь комментарий к ссылке, фото или видео — и сразу вспомни, почему это было важно.", "Add a comment to a link, photo or video and instantly remember why it mattered.", "Комментарий", "Comment", "Не забудется", "Remembered", Color(0xFFFF7A30), Color(0xFFFFB329))
)

@Composable
fun Onboarding(copy: SavioCopy, onComplete: () -> Unit) {
    var page by remember { mutableIntStateOf(0) }
    Column(Modifier.fillMaxSize().padding(horizontal = 20.dp, vertical = 18.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            SavioWordmark(compact = true)
            if (page < onboardingPages.lastIndex) {
                TextButton(onClick = onComplete) {
                    Text(copy.t("Пропустить", "Skip"), fontWeight = FontWeight.Bold)
                }
            }
        }

        Spacer(Modifier.weight(1f))

        AnimatedContent(
            targetState = page,
            transitionSpec = { (fadeIn(tween(260)) + scaleIn(initialScale = .97f)) togetherWith (fadeOut(tween(170)) + scaleOut(targetScale = 1.02f)) },
            label = "onboarding"
        ) { pageIndex ->
            val item = onboardingPages[pageIndex]
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                OnboardingArtwork(item, copy)
                Spacer(Modifier.height(30.dp))
                Text(
                    copy.t(item.titleRu, item.titleEn),
                    fontWeight = FontWeight.Black,
                    fontSize = 30.sp,
                    lineHeight = 34.sp,
                    textAlign = TextAlign.Center,
                    letterSpacing = (-.8).sp
                )
                Spacer(Modifier.height(13.dp))
                Text(
                    copy.t(item.bodyRu, item.bodyEn),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontSize = 16.sp,
                    textAlign = TextAlign.Center,
                    lineHeight = 23.sp,
                    modifier = Modifier.padding(horizontal = 8.dp)
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

@Composable
private fun OnboardingArtwork(item: OnboardingPage, copy: SavioCopy) {
    val motion = rememberInfiniteTransition(label = "onboarding-float")
    val lift by motion.animateFloat(
        initialValue = -5f,
        targetValue = 5f,
        animationSpec = infiniteRepeatable(tween(2600, easing = LinearEasing), RepeatMode.Reverse),
        label = "artwork-lift"
    )
    Surface(
        modifier = Modifier.fillMaxWidth().height(252.dp),
        shape = RoundedCornerShape(38.dp),
        color = MaterialTheme.colorScheme.surface,
        border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = .55f)),
        shadowElevation = 4.dp
    ) {
        Box(
            Modifier.fillMaxSize()
        ) {
            Image(
                painter = painterResource(item.imageRes),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
            Box(
                Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Black.copy(alpha = .04f), Color.Black.copy(alpha = .14f), Color.Black.copy(alpha = .30f))
                        )
                    )
            )
            FloatingLabel(
                text = copy.t(item.chipOneRu, item.chipOneEn),
                color = item.colorA,
                modifier = Modifier.align(Alignment.TopStart).padding(start = 18.dp, top = 24.dp)
            )
            Surface(
                modifier = Modifier
                    .align(Alignment.Center)
                    .size(122.dp)
                    .graphicsLayer { translationY = lift },
                shape = RoundedCornerShape(38.dp),
                color = Color.Transparent,
                shadowElevation = 14.dp
            ) {
                Box(
                    Modifier.background(Brush.linearGradient(listOf(item.colorA, item.colorB))),
                    contentAlignment = Alignment.Center
                ) {
                    SavioGlyph(item.glyph, Modifier.size(62.dp), Color.White, 3.5.dp)
                }
            }
            FloatingLabel(
                text = copy.t(item.chipTwoRu, item.chipTwoEn),
                color = item.colorB,
                modifier = Modifier.align(Alignment.BottomEnd).padding(end = 18.dp, bottom = 24.dp)
            )
        }
    }
}

@Composable
private fun FloatingLabel(text: String, color: Color, modifier: Modifier = Modifier) {
    Surface(modifier = modifier, shape = RoundedCornerShape(99.dp), color = MaterialTheme.colorScheme.surface, shadowElevation = 7.dp) {
        Row(Modifier.padding(horizontal = 13.dp, vertical = 9.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(9.dp).background(color, CircleShape))
            Spacer(Modifier.width(8.dp))
            Text(text, fontWeight = FontWeight.ExtraBold, fontSize = 12.sp)
        }
    }
}
