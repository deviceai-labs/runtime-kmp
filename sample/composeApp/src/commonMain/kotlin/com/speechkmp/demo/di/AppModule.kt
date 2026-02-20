package com.speechkmp.demo.di

import com.speechkmp.demo.AudioRecorder
import com.speechkmp.demo.SpeechViewModel
import org.koin.dsl.module

val appModule = module {
    single { AudioRecorder() }
    single { SpeechViewModel(get()) }
}
