package com.nevsk1y.savio.ui

import com.nevsk1y.savio.data.SavioFolder
import com.nevsk1y.savio.data.SavioIds

class SavioCopy(private val language: String) {
    val isEnglish: Boolean get() = language == "en"
    fun t(ru: String, en: String): String = if (isEnglish) en else ru
    fun itemCount(value: Int): String = if (isEnglish) {
        if (value == 1) "1 item" else "$value items"
    } else {
        when {
            value % 10 == 1 && value % 100 != 11 -> "$value материал"
            value % 10 in 2..4 && value % 100 !in 12..14 -> "$value материала"
            else -> "$value материалов"
        }
    }
}

fun SavioFolder.displayName(copy: SavioCopy): String = when (id) {
    SavioIds.INBOX -> copy.t("Входящие", "Inbox")
    SavioIds.IDEAS -> copy.t("Идеи", "Ideas")
    SavioIds.RECIPES -> copy.t("Рецепты", "Recipes")
    SavioIds.TRAVEL -> copy.t("Путешествия", "Travel")
    SavioIds.WORK -> copy.t("Работа", "Work")
    else -> name
}
