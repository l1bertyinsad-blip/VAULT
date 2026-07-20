package com.nevsk1y.savio.ui

import android.content.Context
import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.nevsk1y.savio.ShareImportEvent
import com.nevsk1y.savio.data.SavioFolder
import com.nevsk1y.savio.data.SavioIds
import com.nevsk1y.savio.data.SavioRepository
import com.nevsk1y.savio.ui.theme.SavioBlue
import com.nevsk1y.savio.ui.theme.SavioBlueBright
import com.nevsk1y.savio.ui.theme.SavioTheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

private enum class TopTab(val glyph: Glyph) { HOME(Glyph.HOME), FOLDERS(Glyph.FOLDER), FAVORITES(Glyph.STAR), PROFILE(Glyph.PERSON) }
private const val OnboardingVersion = 2

private sealed interface Route {
    data object Main : Route
    data class Folder(val id: String) : Route
    data class Item(val id: String) : Route
    data object Search : Route
    data object Notes : Route
    data object Archive : Route
}

@Composable
fun SavioRoot(repository: SavioRepository, shareEvent: ShareImportEvent?, consumeShareEvent: () -> Unit) {
    val state by repository.state.collectAsState()
    val context = LocalContext.current
    var introFinished by rememberSaveable { mutableStateOf(false) }
    var onboardingFinished by rememberSaveable {
        mutableStateOf(
            context.getSharedPreferences("savio_prefs", Context.MODE_PRIVATE)
                .getInt("onboarding_version", 0) >= OnboardingVersion
        )
    }
    val copy = SavioCopy(state.settings.language)

    SavioTheme(state.settings.theme) {
        AnimatedContent(
            targetState = when {
                !introFinished -> 0
                !onboardingFinished -> 1
                else -> 2
            },
            transitionSpec = { fadeIn() togetherWith fadeOut() },
            label = "root"
        ) { step ->
            when (step) {
                0 -> BrandIntro { introFinished = true }
                1 -> Onboarding(copy) {
                    context.getSharedPreferences("savio_prefs", Context.MODE_PRIVATE)
                        .edit()
                        .putInt("onboarding_version", OnboardingVersion)
                        .apply()
                    onboardingFinished = true
                }
                else -> MainSavio(repository, shareEvent, consumeShareEvent)
            }
        }
    }
}

@Composable
private fun MainSavio(repository: SavioRepository, shareEvent: ShareImportEvent?, consumeShareEvent: () -> Unit) {
    val state by repository.state.collectAsState()
    val copy = SavioCopy(state.settings.language)
    var selectedTab by rememberSaveable { mutableStateOf(TopTab.HOME) }
    var route by remember { mutableStateOf<Route>(Route.Main) }
    var previousRoute by remember { mutableStateOf<Route>(Route.Main) }
    var quickAdd by remember { mutableStateOf(false) }
    var editDialog by remember { mutableStateOf(EditDialog.NONE) }
    var renameFolder by remember { mutableStateOf<SavioFolder?>(null) }
    var isImporting by remember { mutableStateOf(false) }
    val snackbar = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    fun navigate(destination: Route) {
        previousRoute = route
        route = destination
    }
    fun goBack() {
        route = previousRoute
        previousRoute = Route.Main
    }
    fun destinationFolder(): String = (route as? Route.Folder)?.id ?: SavioIds.INBOX
    fun announceImport(count: Int) {
        if (count <= 0) return
        scope.launch {
            snackbar.showSnackbar(copy.t("Сохранено во Входящие: $count", "Saved to Inbox: $count"))
        }
    }
    fun importUris(uris: List<Uri>) {
        if (uris.isEmpty()) return
        isImporting = true
        val folderId = destinationFolder()
        scope.launch(Dispatchers.IO) {
            val count = repository.importUris(uris, folderId)
            withContext(Dispatchers.Main) {
                isImporting = false
                announceImport(count)
            }
        }
    }

    val mediaPicker = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(20)) { uris -> importUris(uris) }
    val filePicker = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { uris -> importUris(uris) }

    LaunchedEffect(shareEvent?.token) {
        shareEvent ?: return@LaunchedEffect
        snackbar.showSnackbar(copy.t("Сохранено из другого приложения: ${shareEvent.count}", "Saved from another app: ${shareEvent.count}"))
        consumeShareEvent()
    }

    BackHandler(enabled = route != Route.Main || selectedTab != TopTab.HOME) {
        if (route != Route.Main) goBack() else selectedTab = TopTab.HOME
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        snackbarHost = { SnackbarHost(snackbar) },
        bottomBar = {
            if (route == Route.Main) {
                SavioBottomBar(selectedTab, { selectedTab = it }, copy) { quickAdd = true }
            }
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(top = padding.calculateTopPadding(), bottom = if (route == Route.Main) 0.dp else padding.calculateBottomPadding())) {
            when (val current = route) {
                Route.Main -> when (selectedTab) {
                    TopTab.HOME -> HomeScreen(
                        state, copy,
                        onAdd = { quickAdd = true },
                        onSearch = { navigate(Route.Search) },
                        onOpenFolder = { navigate(Route.Folder(it)) },
                        onOpenItem = { navigate(Route.Item(it)) },
                        onFavorite = repository::toggleFavorite,
                        onOpenFavorites = { selectedTab = TopTab.FAVORITES },
                        onOpenAllFolders = { selectedTab = TopTab.FOLDERS }
                    )
                    TopTab.FOLDERS -> FoldersScreen(state, copy, { navigate(Route.Folder(it)) }, { editDialog = EditDialog.CREATE_FOLDER })
                    TopTab.FAVORITES -> FavoritesScreen(state, copy, { navigate(Route.Item(it)) }, repository::toggleFavorite)
                    TopTab.PROFILE -> ProfileScreen(state, repository, copy, { navigate(Route.Notes) }, { navigate(Route.Archive) })
                }
                is Route.Folder -> FolderDetailScreen(current.id, state, copy, ::goBack, { navigate(Route.Item(it)) }, repository::toggleFavorite, { quickAdd = true }, { renameFolder = it })
                is Route.Item -> ItemDetailScreen(current.id, state, repository, copy, ::goBack)
                Route.Search -> SearchScreen(state, copy, ::goBack, { navigate(Route.Item(it)) }, repository::toggleFavorite)
                Route.Notes -> NotesScreen(state, copy, ::goBack, { navigate(Route.Item(it)) }, repository::toggleFavorite, { editDialog = EditDialog.NOTE })
                Route.Archive -> ArchiveScreen(state, copy, ::goBack, { navigate(Route.Item(it)) }, repository::toggleArchive)
            }

            if (isImporting) {
                Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = .18f)), contentAlignment = Alignment.Center) {
                    Surface(shape = RoundedCornerShape(22.dp), color = MaterialTheme.colorScheme.surface, shadowElevation = 14.dp) {
                        Row(Modifier.padding(horizontal = 22.dp, vertical = 18.dp), verticalAlignment = Alignment.CenterVertically) {
                            CircularProgressIndicator(Modifier.size(26.dp), strokeWidth = 3.dp)
                            Spacer(Modifier.width(13.dp))
                            Text(copy.t("Сохраняем в SAVIO…", "Saving to SAVIO…"), fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }

    if (quickAdd) QuickAddSheet(
        copy = copy,
        onDismiss = { quickAdd = false },
        onMedia = {
            quickAdd = false
            mediaPicker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageAndVideo))
        },
        onFiles = {
            quickAdd = false
            filePicker.launch(arrayOf("*/*"))
        },
        onLink = { quickAdd = false; editDialog = EditDialog.LINK },
        onNote = { quickAdd = false; editDialog = EditDialog.NOTE }
    )

    when (editDialog) {
        EditDialog.LINK -> AddLinkDialog(copy, { editDialog = EditDialog.NONE }) {
            repository.addLink(it, destinationFolder())
            editDialog = EditDialog.NONE
            announceImport(1)
        }
        EditDialog.NOTE -> AddNoteDialog(copy, { editDialog = EditDialog.NONE }) { title, body ->
            repository.addNote(title, body, destinationFolder())
            editDialog = EditDialog.NONE
            announceImport(1)
        }
        EditDialog.CREATE_FOLDER -> FolderNameDialog(copy, onDismiss = { editDialog = EditDialog.NONE }) {
            repository.createFolder(it)
            editDialog = EditDialog.NONE
        }
        EditDialog.NONE -> Unit
    }

    renameFolder?.let { folder ->
        FolderNameDialog(copy, folder, { renameFolder = null }) {
            repository.renameFolder(folder.id, it)
            renameFolder = null
        }
    }
}

@Composable
private fun SavioBottomBar(selected: TopTab, onSelect: (TopTab) -> Unit, copy: SavioCopy, onAdd: () -> Unit) {
    Box(Modifier.fillMaxWidth().height(106.dp).padding(horizontal = 12.dp), contentAlignment = Alignment.BottomCenter) {
        Surface(
            shape = RoundedCornerShape(29.dp),
            color = MaterialTheme.colorScheme.surface.copy(alpha = .98f),
            shadowElevation = 20.dp,
            tonalElevation = 1.dp,
            modifier = Modifier.fillMaxWidth().height(84.dp)
        ) {
            Row(Modifier.fillMaxSize().padding(horizontal = 5.dp), verticalAlignment = Alignment.CenterVertically) {
                BottomTab(TopTab.HOME, selected, onSelect, copy, Modifier.weight(1f))
                BottomTab(TopTab.FOLDERS, selected, onSelect, copy, Modifier.weight(1f))
                Spacer(Modifier.width(74.dp))
                BottomTab(TopTab.FAVORITES, selected, onSelect, copy, Modifier.weight(1f))
                BottomTab(TopTab.PROFILE, selected, onSelect, copy, Modifier.weight(1f))
            }
        }
        FloatingActionButton(
            onClick = onAdd,
            shape = CircleShape,
            containerColor = Color.Transparent,
            contentColor = Color.White,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .size(68.dp)
                .semantics { contentDescription = "Add" }
        ) {
            Box(Modifier.fillMaxSize().background(Brush.linearGradient(listOf(SavioBlueBright, SavioBlue)), CircleShape), contentAlignment = Alignment.Center) {
                SavioGlyph(Glyph.PLUS, Modifier.size(30.dp), Color.White, 3.dp)
            }
        }
    }
}

@Composable
private fun BottomTab(tab: TopTab, selected: TopTab, onSelect: (TopTab) -> Unit, strings: SavioCopy, modifier: Modifier) {
    val copy = when (tab) {
        TopTab.HOME -> strings.t("Главная", "Home")
        TopTab.FOLDERS -> strings.t("Папки", "Folders")
        TopTab.FAVORITES -> strings.t("Избранное", "Favorites")
        TopTab.PROFILE -> strings.t("Профиль", "Profile")
    }
    Column(
        modifier
            .clip(RoundedCornerShape(18.dp))
            .clickable { onSelect(tab) }
            .padding(vertical = 9.dp)
            .semantics { contentDescription = copy },
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        SavioGlyph(tab.glyph, Modifier.size(25.dp), if (tab == selected) SavioBlue else MaterialTheme.colorScheme.onSurfaceVariant, stroke = 2.2.dp)
        Spacer(Modifier.height(5.dp))
        Text(
            copy,
            color = if (tab == selected) SavioBlue else MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = if (tab == selected) FontWeight.Black else FontWeight.Medium,
            fontSize = 11.sp,
            maxLines = 1
        )
    }
}
