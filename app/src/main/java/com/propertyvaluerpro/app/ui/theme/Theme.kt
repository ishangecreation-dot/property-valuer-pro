package com.propertyvaluerpro.app.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.propertyvaluerpro.app.R

object AppColors {
    val PrimaryNavy = Color(0xFF16324F)
    val PrimaryNavyLight = Color(0xFF284B70)
    val PrimaryNavyDark = Color(0xFF0F243B)
    val PrimaryNavyBorder = Color(0xFF243B55)
    val ProfessionalBlue = Color(0xFF2878B5)
    val PrimaryActionTeal = Color(0xFF159A91)
    val Background = Color(0xFFF5F7FA)
    val Cards = Color(0xFFFFFFFF)
    val MainText = Color(0xFF25313D)
    val SecondaryText = Color(0xFF718096)
    val Borders = Color(0xFFE2E8F0)
    val Warning = Color(0xFFE9A23B)
    val Error = Color(0xFFD64545)
    val Success = Color(0xFF249B68)
    val AntiqueGold = Color(0xFFD4AF37)
    val GoldDarkText = Color(0xFF8C711C)
    val DarkSlate = Color(0xFF0F172A)
    val SurfaceDim = Color(0xFFD9DADB)
    val SurfaceContainerLow = Color(0xFFF3F4F5)
    val SurfaceContainerHigh = Color(0xFFE7E8E9)
    val ErrorBg = Color(0xFFFEF2F2)
    val SuccessBg = Color(0xFFF0FDF4)
    val UncertainBg = Color(0xFFFFFBEB)
    val MetaBlue = Color(0xFF0081FB)
    val MetaBannerBg = Color(0xFFF0F4F9)
    val MutedSlate = Color(0xFF94A3B8)
}

val ManropeFontFamily = FontFamily(
    Font(R.font.manrope, FontWeight.Normal),
    Font(R.font.manrope, FontWeight.Medium),
    Font(R.font.manrope, FontWeight.SemiBold),
    Font(R.font.manrope, FontWeight.Bold),
    Font(R.font.manrope, FontWeight.ExtraBold),
)

val JetBrainsMonoFontFamily = FontFamily(
    Font(R.font.jetbrains_mono, FontWeight.Normal),
    Font(R.font.jetbrains_mono, FontWeight.Medium),
    Font(R.font.jetbrains_mono, FontWeight.Bold),
)

private val PropertyValuerColorScheme = lightColorScheme(
    primary = AppColors.PrimaryNavy,
    onPrimary = Color.White,
    secondary = AppColors.PrimaryActionTeal,
    onSecondary = Color.White,
    tertiary = AppColors.ProfessionalBlue,
    onTertiary = Color.White,
    background = AppColors.Background,
    onBackground = AppColors.MainText,
    surface = AppColors.Cards,
    onSurface = AppColors.MainText,
    surfaceVariant = AppColors.SurfaceContainerLow,
    onSurfaceVariant = AppColors.SecondaryText,
    outline = AppColors.Borders,
    error = AppColors.Error,
    onError = Color.White,
)

private val PropertyValuerTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = ManropeFontFamily,
        fontSize = 26.sp,
        fontWeight = FontWeight.ExtraBold,
        color = AppColors.MainText,
        letterSpacing = (-0.5).sp,
    ),
    headlineMedium = TextStyle(
        fontFamily = ManropeFontFamily,
        fontSize = 20.sp,
        fontWeight = FontWeight.Bold,
        color = AppColors.MainText,
        letterSpacing = (-0.3).sp,
    ),
    titleLarge = TextStyle(
        fontFamily = ManropeFontFamily,
        fontSize = 18.sp,
        fontWeight = FontWeight.Bold,
        color = AppColors.MainText,
    ),
    titleMedium = TextStyle(
        fontFamily = ManropeFontFamily,
        fontSize = 16.sp,
        fontWeight = FontWeight.SemiBold,
        color = AppColors.MainText,
    ),
    bodyLarge = TextStyle(
        fontSize = 15.sp,
        fontWeight = FontWeight.Normal,
        color = AppColors.MainText,
        lineHeight = 22.sp,
    ),
    bodyMedium = TextStyle(
        fontSize = 13.5.sp,
        fontWeight = FontWeight.Normal,
        color = AppColors.SecondaryText,
        lineHeight = 19.sp,
    ),
    labelLarge = TextStyle(
        fontFamily = ManropeFontFamily,
        fontSize = 14.sp,
        fontWeight = FontWeight.SemiBold,
        color = AppColors.MainText,
    ),
)

private val PropertyValuerShapes = Shapes(
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp),
)

@Composable
fun PropertyValuerProTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = PropertyValuerColorScheme,
        typography = PropertyValuerTypography,
        shapes = PropertyValuerShapes,
        content = content,
    )
}
