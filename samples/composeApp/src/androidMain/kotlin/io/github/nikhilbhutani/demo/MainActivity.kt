package io.github.nikhilbhutani.demo

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.app.ActivityCompat
import io.github.nikhilbhutani.models.PlatformStorage

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Must run before ModelRegistry.initialize() which is triggered lazily
        // inside SpeechViewModel.initialize() from HomeScreen's LaunchedEffect.
        PlatformStorage.initialize(this)

        // Request microphone access upfront so it's ready when the user taps Record.
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                0
            )
        }

        setContent { App() }
    }
}
