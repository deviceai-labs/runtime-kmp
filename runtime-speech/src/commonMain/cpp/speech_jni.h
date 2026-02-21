#ifndef SPEECH_JNI_H
#define SPEECH_JNI_H

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

// ═══════════════════════════════════════════════════════════════
//                    SPEECH-TO-TEXT (STT)
// ═══════════════════════════════════════════════════════════════

JNIEXPORT jboolean JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeInitStt(
    JNIEnv *env, jobject thiz,
    jstring modelPath,
    jstring language,
    jboolean translate,
    jint maxThreads,
    jboolean useGpu,
    jboolean useVad,
    jboolean singleSegment,
    jboolean noContext);

JNIEXPORT jstring JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeTranscribe(
    JNIEnv *env, jobject thiz,
    jstring audioPath);

JNIEXPORT jobject JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeTranscribeDetailed(
    JNIEnv *env, jobject thiz,
    jstring audioPath);

JNIEXPORT jstring JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeTranscribeAudio(
    JNIEnv *env, jobject thiz,
    jfloatArray samples);

JNIEXPORT void JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeTranscribeStream(
    JNIEnv *env, jobject thiz,
    jfloatArray samples,
    jobject callback);

JNIEXPORT void JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeCancelStt(
    JNIEnv *env, jobject thiz);

JNIEXPORT void JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeShutdownStt(
    JNIEnv *env, jobject thiz);

// ═══════════════════════════════════════════════════════════════
//                    TEXT-TO-SPEECH (TTS)
// ═══════════════════════════════════════════════════════════════

JNIEXPORT jboolean JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeInitTts(
    JNIEnv *env, jobject thiz,
    jstring modelPath,
    jstring configPath,
    jstring espeakDataPath,
    jint speakerId,
    jfloat speechRate,
    jint sampleRate,
    jfloat sentenceSilence);

JNIEXPORT jshortArray JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeSynthesize(
    JNIEnv *env, jobject thiz,
    jstring text);

JNIEXPORT jboolean JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeSynthesizeToFile(
    JNIEnv *env, jobject thiz,
    jstring text,
    jstring outputPath);

JNIEXPORT void JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeSynthesizeStream(
    JNIEnv *env, jobject thiz,
    jstring text,
    jobject callback);

JNIEXPORT void JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeCancelTts(
    JNIEnv *env, jobject thiz);

JNIEXPORT void JNICALL
Java_io_github_nikhilbhutani_SpeechBridge_nativeShutdownTts(
    JNIEnv *env, jobject thiz);

#ifdef __cplusplus
}
#endif

#endif // SPEECH_JNI_H
