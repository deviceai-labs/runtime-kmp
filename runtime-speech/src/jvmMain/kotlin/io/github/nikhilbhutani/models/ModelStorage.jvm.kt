package io.github.nikhilbhutani.models

import java.io.File

@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual object PlatformStorage {

    actual fun getModelsDir(): String =
        File(System.getProperty("user.home"), ".speechkmp/models").absolutePath

    actual fun getTempDir(): String =
        File(System.getProperty("java.io.tmpdir"), "speechkmp_tmp").absolutePath

    actual fun ensureDirectoryExists(path: String): Boolean =
        File(path).let { it.exists() || it.mkdirs() }

    actual fun fileExists(path: String): Boolean =
        File(path).exists()

    actual fun deleteFile(path: String): Boolean =
        File(path).let { if (it.isDirectory) it.deleteRecursively() else it.delete() }

    actual fun moveFile(from: String, to: String): Boolean =
        File(from).renameTo(File(to))

    actual fun fileSize(path: String): Long =
        File(path).let { if (it.exists()) it.length() else -1L }

    actual fun readText(path: String): String? =
        try { File(path).takeIf { it.exists() }?.readText() } catch (_: Exception) { null }

    actual fun writeText(path: String, content: String): Boolean =
        try { File(path).writeText(content); true } catch (_: Exception) { false }
}
