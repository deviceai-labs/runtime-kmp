package com.speechkmp.demo

import androidx.compose.runtime.Composable
import cafe.adriel.voyager.navigator.Navigator
import cafe.adriel.voyager.transitions.SlideTransition
import com.speechkmp.demo.di.appModule
import com.speechkmp.demo.theme.SpeechKMPTheme
import org.koin.compose.KoinApplication

@Composable
fun App() {
    KoinApplication(application = { modules(appModule) }) {
        SpeechKMPTheme {
            Navigator(HomeScreen()) { navigator ->
                SlideTransition(navigator)
            }
        }
    }
}
