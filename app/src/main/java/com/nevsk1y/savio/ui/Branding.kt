package com.nevsk1y.savio.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nevsk1y.savio.ui.theme.SavioBlue

@Composable
fun SavioMark(modifier: Modifier = Modifier, color: Color = SavioBlue) {
    Canvas(modifier = modifier) {
        val w = size.width
        val h = size.height
        // The head and bookmark are deliberately separated: the gap is part of
        // SAVIO's mark and keeps it readable even at launcher-icon size.
        drawCircle(color, radius = w * 0.12f, center = Offset(w * 0.5f, h * 0.14f))
        val path = Path().apply {
            moveTo(w * 0.25f, h * 0.455f)
            quadraticTo(w * 0.25f, h * 0.38f, w * 0.325f, h * 0.38f)
            lineTo(w * 0.675f, h * 0.38f)
            quadraticTo(w * 0.75f, h * 0.38f, w * 0.75f, h * 0.455f)
            lineTo(w * 0.75f, h * 0.85f)
            quadraticTo(w * 0.75f, h * 0.90f, w * 0.71f, h * 0.865f)
            lineTo(w * 0.525f, h * 0.715f)
            quadraticTo(w * 0.5f, h * 0.695f, w * 0.475f, h * 0.715f)
            lineTo(w * 0.29f, h * 0.865f)
            quadraticTo(w * 0.25f, h * 0.90f, w * 0.25f, h * 0.85f)
            close()
        }
        drawPath(path, color)
    }
}

@Composable
fun SavioWordmark(modifier: Modifier = Modifier, compact: Boolean = false) {
    Row(modifier = modifier, verticalAlignment = Alignment.CenterVertically) {
        SavioMark(Modifier.size(if (compact) 29.dp else 42.dp))
        Spacer(Modifier.width(if (compact) 8.dp else 10.dp))
        Text(
            text = "SAVIO",
            fontSize = if (compact) 20.sp else 27.sp,
            fontWeight = FontWeight.Black,
            letterSpacing = (-0.75).sp,
            color = MaterialTheme.colorScheme.onBackground
        )
    }
}

enum class Glyph { HOME, FOLDER, STAR, PERSON, PLUS, SEARCH, NOTE, LINK, IMAGE, VIDEO, FILE, INBOX, CHECK, CLOSE, MORE, ARCHIVE, BACK, UP, DOWN, GLOBE, MOON, LOCK, TRASH, EDIT, MOVE }

@Composable
fun SavioGlyph(
    glyph: Glyph,
    modifier: Modifier = Modifier,
    color: Color = MaterialTheme.colorScheme.onSurface,
    stroke: Dp = 2.dp
) {
    Box(modifier, contentAlignment = Alignment.Center) {
        Canvas(Modifier.matchParentSize()) {
            val s = size.minDimension
            val lw = stroke.toPx()
            val style = Stroke(width = lw, cap = androidx.compose.ui.graphics.StrokeCap.Round, join = androidx.compose.ui.graphics.StrokeJoin.Round)
            fun line(x1: Float, y1: Float, x2: Float, y2: Float) = drawLine(color, Offset(s*x1,s*y1), Offset(s*x2,s*y2), lw, cap = androidx.compose.ui.graphics.StrokeCap.Round)
            when (glyph) {
                Glyph.HOME -> {
                    val p=Path().apply{moveTo(s*.15f,s*.48f);lineTo(s*.5f,s*.18f);lineTo(s*.85f,s*.48f);moveTo(s*.25f,s*.42f);lineTo(s*.25f,s*.82f);lineTo(s*.75f,s*.82f);lineTo(s*.75f,s*.42f)}; drawPath(p, color, style = style)
                }
                Glyph.FOLDER -> {
                    val p=Path().apply{moveTo(s*.12f,s*.3f);lineTo(s*.4f,s*.3f);lineTo(s*.48f,s*.4f);lineTo(s*.88f,s*.4f);lineTo(s*.82f,s*.78f);lineTo(s*.18f,s*.78f);close()}; drawPath(p, color, style = style)
                }
                Glyph.STAR -> {
                    val p=Path(); for(i in 0..9){val a=(-Math.PI/2+i*Math.PI/5).toFloat();val r=if(i%2==0)s*.36f else s*.16f;val x=s*.5f+kotlin.math.cos(a)*r;val y=s*.5f+kotlin.math.sin(a)*r;if(i==0)p.moveTo(x,y)else p.lineTo(x,y)};p.close();drawPath(p, color, style = style)
                }
                Glyph.PERSON -> { drawCircle(color,s*.16f,Offset(s*.5f,s*.32f),style=style);drawArc(color,200f,140f,false,Offset(s*.18f,s*.5f),androidx.compose.ui.geometry.Size(s*.64f,s*.42f),style=style) }
                Glyph.PLUS -> { line(.5f,.18f,.5f,.82f);line(.18f,.5f,.82f,.5f) }
                Glyph.SEARCH -> { drawCircle(color,s*.25f,Offset(s*.43f,s*.43f),style=style);line(.62f,.62f,.84f,.84f) }
                Glyph.NOTE -> { drawRoundRect(color,Offset(s*.22f,s*.14f),androidx.compose.ui.geometry.Size(s*.56f,s*.72f),CornerRadius(s*.08f),style=style);line(.34f,.37f,.66f,.37f);line(.34f,.52f,.66f,.52f);line(.34f,.67f,.56f,.67f) }
                Glyph.LINK -> { drawArc(color,135f,180f,false,Offset(s*.1f,s*.34f),androidx.compose.ui.geometry.Size(s*.48f,s*.36f),style=style);drawArc(color,-45f,180f,false,Offset(s*.42f,s*.3f),androidx.compose.ui.geometry.Size(s*.48f,s*.36f),style=style);line(.37f,.61f,.63f,.39f) }
                Glyph.IMAGE -> { drawRoundRect(color,Offset(s*.14f,s*.18f),androidx.compose.ui.geometry.Size(s*.72f,s*.64f),CornerRadius(s*.08f),style=style);drawCircle(color,s*.07f,Offset(s*.67f,s*.37f),style=style);val p=Path().apply{moveTo(s*.2f,s*.72f);lineTo(s*.4f,s*.5f);lineTo(s*.53f,s*.63f);lineTo(s*.64f,s*.53f);lineTo(s*.82f,s*.72f)};drawPath(p, color, style = style) }
                Glyph.VIDEO -> { drawRoundRect(color,Offset(s*.13f,s*.23f),androidx.compose.ui.geometry.Size(s*.55f,s*.54f),CornerRadius(s*.08f),style=style);val p=Path().apply{moveTo(s*.68f,s*.4f);lineTo(s*.87f,s*.3f);lineTo(s*.87f,s*.7f);lineTo(s*.68f,s*.6f);close()};drawPath(p, color, style = style) }
                Glyph.FILE -> { val p=Path().apply{moveTo(s*.25f,s*.1f);lineTo(s*.62f,s*.1f);lineTo(s*.78f,s*.27f);lineTo(s*.78f,s*.88f);lineTo(s*.25f,s*.88f);close();moveTo(s*.62f,s*.1f);lineTo(s*.62f,s*.28f);lineTo(s*.78f,s*.28f)};drawPath(p, color, style = style) }
                Glyph.INBOX -> { val p=Path().apply{moveTo(s*.16f,s*.23f);lineTo(s*.84f,s*.23f);lineTo(s*.9f,s*.73f);lineTo(s*.62f,s*.73f);quadraticTo(s*.58f,s*.84f,s*.5f,s*.84f);quadraticTo(s*.42f,s*.84f,s*.38f,s*.73f);lineTo(s*.1f,s*.73f);close()};drawPath(p, color, style = style);line(.32f,.48f,.68f,.48f) }
                Glyph.CHECK -> { line(.2f,.52f,.42f,.74f);line(.42f,.74f,.82f,.28f) }
                Glyph.CLOSE -> { line(.23f,.23f,.77f,.77f);line(.77f,.23f,.23f,.77f) }
                Glyph.MORE -> { listOf(.25f,.5f,.75f).forEach{drawCircle(color,s*.055f,Offset(s*it,s*.5f))} }
                Glyph.ARCHIVE -> { drawRect(color,Offset(s*.18f,s*.33f),androidx.compose.ui.geometry.Size(s*.64f,s*.48f),style=style);drawRect(color,Offset(s*.13f,s*.19f),androidx.compose.ui.geometry.Size(s*.74f,s*.15f),style=style);line(.39f,.52f,.61f,.52f) }
                Glyph.BACK -> { line(.7f,.2f,.3f,.5f);line(.3f,.5f,.7f,.8f) }
                Glyph.UP -> { line(.2f,.66f,.5f,.34f);line(.5f,.34f,.8f,.66f) }
                Glyph.DOWN -> { line(.2f,.34f,.5f,.66f);line(.5f,.66f,.8f,.34f) }
                Glyph.GLOBE -> { drawCircle(color,s*.36f,Offset(s*.5f,s*.5f),style=style);drawOval(color,Offset(s*.35f,s*.14f),androidx.compose.ui.geometry.Size(s*.3f,s*.72f),style=style);line(.15f,.5f,.85f,.5f) }
                Glyph.MOON -> { val p=Path().apply{arcTo(Rect(s*.2f,s*.12f,s*.82f,s*.86f),60f,250f,false);quadraticTo(s*.22f,s*.73f,s*.2f,s*.12f);close()};drawPath(p, color, style = style) }
                Glyph.LOCK -> { drawRoundRect(color,Offset(s*.22f,s*.4f),androidx.compose.ui.geometry.Size(s*.56f,s*.44f),CornerRadius(s*.08f),style=style);drawArc(color,180f,180f,false,Offset(s*.32f,s*.12f),androidx.compose.ui.geometry.Size(s*.36f,s*.48f),style=style) }
                Glyph.TRASH -> { drawRect(color,Offset(s*.28f,s*.28f),androidx.compose.ui.geometry.Size(s*.44f,s*.55f),style=style);line(.2f,.28f,.8f,.28f);line(.4f,.16f,.6f,.16f);line(.42f,.4f,.42f,.7f);line(.58f,.4f,.58f,.7f) }
                Glyph.EDIT -> { line(.22f,.75f,.32f,.53f);line(.32f,.53f,.68f,.17f);line(.68f,.17f,.82f,.31f);line(.82f,.31f,.46f,.67f);line(.46f,.67f,.22f,.75f) }
                Glyph.MOVE -> { line(.5f,.12f,.5f,.88f);line(.12f,.5f,.88f,.5f);line(.5f,.12f,.4f,.24f);line(.5f,.12f,.6f,.24f);line(.88f,.5f,.76f,.4f);line(.88f,.5f,.76f,.6f) }
            }
        }
    }
}
