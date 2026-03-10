/**
 * llm_jni.cpp
 *
 * Thin JNI delegate — converts Android/JVM types to plain C, then calls
 * the unified dai_llm_* API in deviceai_llm_engine.{h,cpp}.
 *
 * No inference logic lives here.
 */

#include "llm_jni.h"
#include "deviceai_llm_engine.h"

#include <jni.h>
#include <string>
#include <vector>

static std::string jstring_to_std(JNIEnv *env, jstring js) {
    if (!js) return "";
    const char *chars = env->GetStringUTFChars(js, nullptr);
    std::string s(chars);
    env->ReleaseStringUTFChars(js, chars);
    return s;
}

// Helper: unpack two parallel jobjectArrays into const char** vectors.
static void unpack_messages(
    JNIEnv *env,
    jobjectArray jRoles, jobjectArray jContents, int count,
    std::vector<std::string> &rolesStorage,
    std::vector<std::string> &contentsStorage,
    std::vector<const char *> &roles,
    std::vector<const char *> &contents
) {
    rolesStorage.resize(count);
    contentsStorage.resize(count);
    roles.resize(count);
    contents.resize(count);
    for (int i = 0; i < count; i++) {
        rolesStorage[i]    = jstring_to_std(env, (jstring)env->GetObjectArrayElement(jRoles,    i));
        contentsStorage[i] = jstring_to_std(env, (jstring)env->GetObjectArrayElement(jContents, i));
        roles[i]    = rolesStorage[i].c_str();
        contents[i] = contentsStorage[i].c_str();
    }
}

// Shared context passed through the streaming callback's user_data.
struct StreamCtx {
    JavaVM    *jvm;
    jobject    callback;   // global ref
    jmethodID  onToken;
    jmethodID  onError;
};

static void jni_on_token(const char *token, void *user_data) {
    auto *ctx = static_cast<StreamCtx *>(user_data);
    JNIEnv *env;
    ctx->jvm->AttachCurrentThread(&env, nullptr);
    jstring jToken = env->NewStringUTF(token ? token : "");
    env->CallVoidMethod(ctx->callback, ctx->onToken, jToken);
    env->DeleteLocalRef(jToken);
}

extern "C" {

JNIEXPORT jboolean JNICALL
Java_dev_deviceai_llm_engine_LlmJniEngine_nativeInit(
    JNIEnv *env, jobject,
    jstring jModelPath, jint contextSize, jint maxThreads, jboolean useGpu
) {
    std::string path = jstring_to_std(env, jModelPath);
    return dai_llm_init(path.c_str(), (int)contextSize, (int)maxThreads, (int)useGpu)
           ? JNI_TRUE : JNI_FALSE;
}

JNIEXPORT void JNICALL
Java_dev_deviceai_llm_engine_LlmJniEngine_nativeShutdown(JNIEnv *, jobject) {
    dai_llm_shutdown();
}

JNIEXPORT jstring JNICALL
Java_dev_deviceai_llm_engine_LlmJniEngine_nativeGenerate(
    JNIEnv *env, jobject,
    jobjectArray jRoles, jobjectArray jContents,
    jint maxTokens, jfloat temperature, jfloat topP, jint topK, jfloat repeatPenalty
) {
    int count = (int)env->GetArrayLength(jRoles);
    std::vector<std::string> rs, cs;
    std::vector<const char *> roles, contents;
    unpack_messages(env, jRoles, jContents, count, rs, cs, roles, contents);

    char *result = dai_llm_generate(
        roles.data(), contents.data(), count,
        (int)maxTokens, temperature, topP, (int)topK, repeatPenalty
    );

    jstring out = env->NewStringUTF(result ? result : "");
    dai_llm_free_string(result);
    return out;
}

JNIEXPORT void JNICALL
Java_dev_deviceai_llm_engine_LlmJniEngine_nativeGenerateStream(
    JNIEnv *env, jobject,
    jobjectArray jRoles, jobjectArray jContents,
    jint maxTokens, jfloat temperature, jfloat topP, jint topK, jfloat repeatPenalty,
    jobject jCallback
) {
    int count = (int)env->GetArrayLength(jRoles);
    std::vector<std::string> rs, cs;
    std::vector<const char *> roles, contents;
    unpack_messages(env, jRoles, jContents, count, rs, cs, roles, contents);

    jclass cbClass = env->GetObjectClass(jCallback);
    StreamCtx ctx;
    env->GetJavaVM(&ctx.jvm);
    ctx.callback = env->NewGlobalRef(jCallback);
    ctx.onToken  = env->GetMethodID(cbClass, "onToken", "(Ljava/lang/String;)V");
    ctx.onError  = env->GetMethodID(cbClass, "onError", "(Ljava/lang/String;)V");

    dai_llm_generate_stream(
        roles.data(), contents.data(), count,
        (int)maxTokens, temperature, topP, (int)topK, repeatPenalty,
        jni_on_token, nullptr, &ctx
    );

    env->DeleteGlobalRef(ctx.callback);
}

JNIEXPORT void JNICALL
Java_dev_deviceai_llm_engine_LlmJniEngine_nativeCancel(JNIEnv *, jobject) {
    dai_llm_cancel();
}

} // extern "C"
