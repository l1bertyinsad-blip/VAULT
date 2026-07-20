package com.nevsk1y.savio

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.nevsk1y.savio.data.SavioRepository
import com.nevsk1y.savio.ui.SavioRoot
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class ShareImportEvent(val count: Int, val token: Long = System.nanoTime())

class MainActivity : ComponentActivity() {
    private val importScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private lateinit var repository: SavioRepository
    private var shareEvent by mutableStateOf<ShareImportEvent?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        repository = SavioRepository.get(applicationContext)
        importFrom(intent)

        setContent {
            SavioRoot(
                repository = repository,
                shareEvent = shareEvent,
                consumeShareEvent = { shareEvent = null }
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        importFrom(intent)
    }

    private fun importFrom(sourceIntent: Intent?) {
        val snapshot = sourceIntent ?: return
        if (snapshot.action !in setOf(Intent.ACTION_SEND, Intent.ACTION_SEND_MULTIPLE)) return
        setIntent(Intent(this, MainActivity::class.java))
        importScope.launch {
            val count = repository.importSharedIntent(snapshot)
            if (count > 0) withContext(Dispatchers.Main) {
                shareEvent = ShareImportEvent(count)
            }
        }
    }

    override fun onDestroy() {
        importScope.cancel()
        super.onDestroy()
    }
}
