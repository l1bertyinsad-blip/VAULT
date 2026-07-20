package com.nevsk1y.savio.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

val SavioBlue = Color(0xFF0B4DFF)
val SavioBlueBright = Color(0xFF3472FF)
val SavioInk = Color(0xFF0B1020)
val SavioMuted = Color(0xFF65708A)
val SavioSurface = Color(0xFFF5F7FC)
val SavioCard = Color(0xFFFFFFFF)
val SavioPurple = Color(0xFF7C5CFC)
val SavioOrange = Color(0xFFFF8A3D)
val SavioGreen = Color(0xFF18B989)

private val LightColors = lightColorScheme(
    primary = SavioBlue,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFDCE6FF),
    onPrimaryContainer = Color(0xFF001848),
    secondary = SavioPurple,
    background = SavioSurface,
    onBackground = SavioInk,
    surface = SavioCard,
    onSurface = SavioInk,
    surfaceVariant = Color(0xFFEAF0FF),
    onSurfaceVariant = SavioMuted,
    outline = Color(0xFFD5DCEC),
    error = Color(0xFFD92D20)
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFF82A6FF),
    onPrimary = Color(0xFF001A52),
    primaryContainer = Color(0xFF173E9F),
    onPrimaryContainer = Color(0xFFDCE6FF),
    secondary = Color(0xFFB9A8FF),
    background = Color(0xFF090D18),
    onBackground = Color(0xFFF1F4FF),
    surface = Color(0xFF121827),
    onSurface = Color(0xFFF1F4FF),
    surfaceVariant = Color(0xFF1B2540),
    onSurfaceVariant = Color(0xFFB9C1D6),
    outline = Color(0xFF34415F),
    error = Color(0xFFFFB4AB)
)

@Composable
fun SavioTheme(theme: String, content: @Composable () -> Unit) {
    val dark = when (theme) {
        "dark" -> true
        "light" -> false
        else -> isSystemInDarkTheme()
    }
    val colors = if (dark) DarkColors else LightColors
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            if (Build.VERSION.SDK_INT < 35) {
                @Suppress("DEPRECATION")
                run {
                    window.statusBarColor = Color.Transparent.toArgb()
                    window.navigationBarColor = colors.background.toArgb()
                }
            }
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !dark
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !dark
        }
    }
    MaterialTheme(colorScheme = colors, content = content)
}
