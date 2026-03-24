package dev.deviceai.core

/**
 * Marks an API as internal to the DeviceAI SDK.
 *
 * These declarations are public only because they are shared across SDK modules
 * (e.g. `core` → `llm`, `speech`). They are **not part of the public API** and
 * may change without notice.
 *
 * Application code must not use anything annotated with `@InternalDeviceAiApi`.
 */
@RequiresOptIn(
    message = "This is an internal DeviceAI SDK API. It may change or be removed without notice.",
    level = RequiresOptIn.Level.ERROR,
)
@Target(AnnotationTarget.CLASS, AnnotationTarget.FUNCTION, AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.BINARY)
annotation class InternalDeviceAiApi
