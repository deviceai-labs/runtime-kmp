import ComposableArchitecture
import DeviceAiStt
import DeviceAiLlm

// MARK: - Feature

@Reducer
struct ModelManagerFeature {

    @ObservableState
    struct State: Equatable {
        var sttEntries: IdentifiedArrayOf<SttEntry> = .init(
            uniqueElements: WhisperCatalog.all.map { SttEntry(model: $0) }
        )
        var llmEntries: IdentifiedArrayOf<LlmEntry> = .init(
            uniqueElements: LlmCatalog.all.map { LlmEntry(model: $0) }
        )
        /// ID of the currently selected (in-use) STT model.
        var selectedSttId: String? = nil
        /// ID of the currently selected (in-use) LLM model.
        var selectedLlmId: String? = nil
    }

    // MARK: - Model entries

    struct SttEntry: Identifiable, Equatable {
        var id: String { model.id }
        let model: WhisperModelInfo
        var downloadStatus: ModelDownloadStatus = .notDownloaded
    }

    struct LlmEntry: Identifiable, Equatable {
        var id: String { model.id }
        let model: LlmModelInfo
        var downloadStatus: ModelDownloadStatus = .notDownloaded
    }

    enum ModelDownloadStatus: Equatable {
        case notDownloaded
        case downloading(Double)    // 0.0 – 1.0
        case downloaded
    }

    // MARK: - Actions

    enum Action {
        case appeared
        case sttDownloadTapped(String)
        case llmDownloadTapped(String)
        case sttSelectTapped(String)
        case llmSelectTapped(String)

        // Internal — fed from async tasks
        case _sttStatusChecked(String, Bool)
        case _llmStatusChecked(String, Bool)
        case _sttProgress(String, Double)
        case _sttCompleted(String)
        case _sttFailed(String)
        case _llmProgress(String, Double)
        case _llmCompleted(String)
        case _llmFailed(String)

        // Delegate — consumed by MainFeature
        case delegate(Delegate)
        enum Delegate: Equatable {
            case sttModelSelected(path: String)
            case llmModelSelected(path: String)
        }
    }

    // MARK: - Reducer

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            // ── Check which models are already on disk ──────────────────────

            case .appeared:
                let sttModels = state.sttEntries.map(\.model)
                let llmModels = state.llmEntries.map(\.model)
                return .merge(
                    .run { send in
                        for model in sttModels {
                            let ok = await DeviceAI.stt.modelManager.isDownloaded(model)
                            await send(._sttStatusChecked(model.id, ok))
                        }
                    },
                    .run { send in
                        for model in llmModels {
                            let ok = await DeviceAI.llm.modelManager.isDownloaded(model)
                            await send(._llmStatusChecked(model.id, ok))
                        }
                    }
                )

            case ._sttStatusChecked(let id, let downloaded):
                state.sttEntries[id: id]?.downloadStatus = downloaded ? .downloaded : .notDownloaded
                // Auto-select first downloaded STT model if none selected yet.
                if downloaded, state.selectedSttId == nil {
                    return .send(.sttSelectTapped(id))
                }
                return .none

            case ._llmStatusChecked(let id, let downloaded):
                state.llmEntries[id: id]?.downloadStatus = downloaded ? .downloaded : .notDownloaded
                if downloaded, state.selectedLlmId == nil {
                    return .send(.llmSelectTapped(id))
                }
                return .none

            // ── Downloads ───────────────────────────────────────────────────

            case .sttDownloadTapped(let id):
                guard let entry = state.sttEntries[id: id],
                      entry.downloadStatus == .notDownloaded else { return .none }
                state.sttEntries[id: id]?.downloadStatus = .downloading(0)
                let model = entry.model
                return .run { send in
                    do {
                        for try await progress in DeviceAI.stt.modelManager.download(model) {
                            await send(._sttProgress(id, progress.fraction ?? 0))
                        }
                        await send(._sttCompleted(id))
                    } catch {
                        await send(._sttFailed(id))
                    }
                }
                .cancellable(id: "stt-download-\(id)")

            case .llmDownloadTapped(let id):
                guard let entry = state.llmEntries[id: id],
                      entry.downloadStatus == .notDownloaded else { return .none }
                state.llmEntries[id: id]?.downloadStatus = .downloading(0)
                let model = entry.model
                return .run { send in
                    do {
                        for try await progress in DeviceAI.llm.modelManager.download(model) {
                            await send(._llmProgress(id, progress.fraction ?? 0))
                        }
                        await send(._llmCompleted(id))
                    } catch {
                        await send(._llmFailed(id))
                    }
                }
                .cancellable(id: "llm-download-\(id)")

            case ._sttProgress(let id, let fraction):
                state.sttEntries[id: id]?.downloadStatus = .downloading(fraction)
                return .none

            case ._sttCompleted(let id):
                state.sttEntries[id: id]?.downloadStatus = .downloaded
                // Auto-select if this is the first (or only) downloaded STT model.
                let hasSelection = state.selectedSttId != nil
                if !hasSelection {
                    return .send(.sttSelectTapped(id))
                }
                return .none

            case ._sttFailed(let id):
                state.sttEntries[id: id]?.downloadStatus = .notDownloaded
                return .none

            case ._llmProgress(let id, let fraction):
                state.llmEntries[id: id]?.downloadStatus = .downloading(fraction)
                return .none

            case ._llmCompleted(let id):
                state.llmEntries[id: id]?.downloadStatus = .downloaded
                let hasSelection = state.selectedLlmId == nil
                if hasSelection {
                    return .send(.llmSelectTapped(id))
                }
                return .none

            case ._llmFailed(let id):
                state.llmEntries[id: id]?.downloadStatus = .notDownloaded
                return .none

            // ── Model selection ─────────────────────────────────────────────

            case .sttSelectTapped(let id):
                guard let entry = state.sttEntries[id: id],
                      entry.downloadStatus == .downloaded else { return .none }
                state.selectedSttId = id
                let path = DeviceAI.stt.modelManager.localPath(for: entry.model).path
                return .send(.delegate(.sttModelSelected(path: path)))

            case .llmSelectTapped(let id):
                guard let entry = state.llmEntries[id: id],
                      entry.downloadStatus == .downloaded else { return .none }
                state.selectedLlmId = id
                let path = DeviceAI.llm.modelManager.localPath(for: entry.model).path
                return .send(.delegate(.llmModelSelected(path: path)))

            case .delegate:
                return .none
            }
        }
    }
}
