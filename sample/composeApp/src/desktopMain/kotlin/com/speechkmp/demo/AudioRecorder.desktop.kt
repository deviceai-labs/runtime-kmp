package com.speechkmp.demo

import javax.sound.sampled.AudioFormat
import javax.sound.sampled.AudioSystem
import javax.sound.sampled.DataLine
import javax.sound.sampled.LineUnavailableException
import javax.sound.sampled.TargetDataLine

@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual class AudioRecorder actual constructor() {

    // 16 kHz, 16-bit, mono, signed, little-endian
    private val format = AudioFormat(16000f, 16, 1, true, false)
    private var line: TargetDataLine? = null
    private val collectedBytes = mutableListOf<Byte>()
    private var recordingThread: Thread? = null
    @Volatile private var isRecording = false

    actual fun startRecording() {
        if (isRecording) return

        val info = DataLine.Info(TargetDataLine::class.java, format)
        if (!AudioSystem.isLineSupported(info)) return

        val dataLine = try {
            AudioSystem.getLine(info) as TargetDataLine
        } catch (e: LineUnavailableException) {
            return
        }

        try {
            dataLine.open(format)
        } catch (e: LineUnavailableException) {
            return
        }

        collectedBytes.clear()
        line = dataLine
        isRecording = true
        dataLine.start()

        recordingThread = Thread {
            val buffer = ByteArray(4096)
            while (isRecording) {
                val read = dataLine.read(buffer, 0, buffer.size)
                if (read > 0) {
                    synchronized(collectedBytes) {
                        for (i in 0 until read) collectedBytes.add(buffer[i])
                    }
                }
            }
        }.also { it.start() }
    }

    actual fun stopRecording(): FloatArray {
        if (!isRecording) return FloatArray(0)
        isRecording = false
        recordingThread?.join()
        recordingThread = null
        line?.stop()
        line?.close()
        line = null

        // Convert little-endian 16-bit pairs to normalized floats
        val bytes = synchronized(collectedBytes) { collectedBytes.toByteArray() }
        val numSamples = bytes.size / 2
        return FloatArray(numSamples) { i ->
            val lo = bytes[i * 2].toInt() and 0xFF
            val hi = bytes[i * 2 + 1].toInt()
            val sample = (hi shl 8) or lo
            sample / 32768f
        }
    }
}
