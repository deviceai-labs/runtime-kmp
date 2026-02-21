package io.github.nikhilbhutani.demo.di

import io.github.nikhilbhutani.demo.AudioRecorder
import io.github.nikhilbhutani.demo.SpeechViewModel
import org.koin.dsl.module

val appModule = module {
    single { AudioRecorder() }
    single { SpeechViewModel(get()) }
}
