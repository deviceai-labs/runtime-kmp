package dev.deviceai.demo

import dev.deviceai.llm.LlmBridge
import dev.deviceai.llm.LlmResult
import dev.deviceai.llm.LlmStream
import dev.deviceai.llm.models.LlmCatalog
import dev.deviceai.llm.models.LlmModelInfo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

// ── LLM loading state ─────────────────────────────────────────────────────────

sealed class LlmState {
    object NotAvailable : LlmState()  // native library not compiled yet
    object Idle : LlmState()          // ready to load a model
    object Loading : LlmState()       // LlmBridge.initLlm() in progress
    object Ready : LlmState()         // model loaded, chat works
    data class Error(val msg: String) : LlmState()
}

// ── Chat message model ────────────────────────────────────────────────────────

enum class Role { USER, ASSISTANT }

data class ChatMessage(
    val role: Role,
    val text: String,
    val isStreaming: Boolean = false,
    val id: Long = 0L
)

// ── ViewModel ─────────────────────────────────────────────────────────────────

class LlmViewModel {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    // Check native availability once at init — catches UnsatisfiedLinkError (extends Throwable)
    private val nativeAvailable: Boolean =
        runCatching { LlmBridge.toString(); true }.getOrElse { false }

    private val _state = MutableStateFlow<LlmState>(
        if (nativeAvailable) LlmState.Idle else LlmState.NotAvailable
    )
    val state: StateFlow<LlmState> = _state.asStateFlow()

    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _isGenerating = MutableStateFlow(false)
    val isGenerating: StateFlow<Boolean> = _isGenerating.asStateFlow()

    val suggestedModel: LlmModelInfo = LlmCatalog.LLAMA_3_2_1B_INSTRUCT_Q4

    private var nextId = 0L
    private fun nextMessageId() = nextId++

    // ── Public API ────────────────────────────────────────────────────────────

    fun loadModel(path: String) {
        scope.launch {
            _state.value = LlmState.Loading
            val ok = runCatching {
                withContext(Dispatchers.IO) { LlmBridge.initLlm(path) }
            }.getOrElse { false }
            _state.value = if (ok) LlmState.Ready
                           else LlmState.Error("Failed to load model. Check the file path.")
        }
    }

    fun sendMessage(text: String) {
        if (_isGenerating.value || text.isBlank()) return

        val userMsg = ChatMessage(role = Role.USER, text = text, id = nextMessageId())
        val assistantMsg = ChatMessage(
            role = Role.ASSISTANT, text = "", isStreaming = true, id = nextMessageId()
        )
        _messages.value = _messages.value + userMsg + assistantMsg
        _isGenerating.value = true

        scope.launch {
            withContext(Dispatchers.IO) {
                runCatching {
                    LlmBridge.generateStream(text, callback = object : LlmStream {
                        override fun onToken(token: String) {
                            val current = _messages.value.toMutableList()
                            val idx = current.indexOfLast { it.role == Role.ASSISTANT && it.isStreaming }
                            if (idx >= 0) {
                                current[idx] = current[idx].copy(text = current[idx].text + token)
                                _messages.value = current
                            }
                        }

                        override fun onComplete(result: LlmResult) {
                            val current = _messages.value.toMutableList()
                            val idx = current.indexOfLast { it.role == Role.ASSISTANT && it.isStreaming }
                            if (idx >= 0) {
                                current[idx] = current[idx].copy(isStreaming = false)
                                _messages.value = current
                            }
                            _isGenerating.value = false
                        }

                        override fun onError(message: String) {
                            val current = _messages.value.toMutableList()
                            val idx = current.indexOfLast { it.role == Role.ASSISTANT && it.isStreaming }
                            if (idx >= 0) {
                                current[idx] = current[idx].copy(
                                    text = "Error: $message", isStreaming = false
                                )
                                _messages.value = current
                            }
                            _isGenerating.value = false
                        }
                    })
                }.onFailure { e ->
                    val current = _messages.value.toMutableList()
                    val idx = current.indexOfLast { it.role == Role.ASSISTANT && it.isStreaming }
                    if (idx >= 0) {
                        current[idx] = current[idx].copy(
                            text = "Error: ${e.message ?: "Unknown error"}", isStreaming = false
                        )
                        _messages.value = current
                    }
                    _isGenerating.value = false
                }
            }
        }
    }

    fun cancelGeneration() {
        runCatching { LlmBridge.cancelGeneration() }
        val current = _messages.value.toMutableList()
        val idx = current.indexOfLast { it.role == Role.ASSISTANT && it.isStreaming }
        if (idx >= 0) {
            current[idx] = current[idx].copy(isStreaming = false)
            _messages.value = current
        }
        _isGenerating.value = false
    }

    fun retry() {
        _state.value = LlmState.Idle
    }
}
