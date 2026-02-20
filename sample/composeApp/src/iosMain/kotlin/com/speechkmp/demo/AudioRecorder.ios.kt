package com.speechkmp.demo

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.get
import platform.AVFAudio.AVAudioEngine
import platform.AVFAudio.AVAudioFormat
import platform.AVFAudio.AVAudioPCMFormatFloat32
import platform.AVFAudio.AVAudioSession

@OptIn(ExperimentalForeignApi::class)
@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual class AudioRecorder actual constructor() {

    private val engine = AVAudioEngine()
    private val samples = mutableListOf<Float>()
    private var recording = false

    actual fun startRecording() {
        if (recording) return

        // Request microphone permission first
        AVAudioSession.sharedInstance().requestRecordPermission { granted ->
            if (!granted) return@requestRecordPermission

            val inputNode = engine.inputNode
            val format = AVAudioFormat(
                commonFormat = AVAudioPCMFormatFloat32,
                sampleRate = 16000.0,
                channels = 1u,
                interleaved = false
            ) ?: return@requestRecordPermission

            samples.clear()
            recording = true

            inputNode.installTapOnBus(
                bus = 0u,
                bufferSize = 4096u,
                format = format
            ) { buffer, _ ->
                buffer ?: return@installTapOnBus
                val channelData = buffer.floatChannelData ?: return@installTapOnBus
                val frameLength = buffer.frameLength.toInt()
                val channel = channelData[0] ?: return@installTapOnBus
                for (i in 0 until frameLength) {
                    samples.add(channel[i])
                }
            }

            engine.startAndReturnError(null)
        }
    }

    actual fun stopRecording(): FloatArray {
        if (!recording) return FloatArray(0)
        recording = false
        engine.inputNode.removeTapOnBus(0u)
        engine.stop()
        return samples.toFloatArray()
    }
}
