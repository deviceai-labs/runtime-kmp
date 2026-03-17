import ComposableArchitecture
import DeviceAiStt

@Reducer
struct SpeechFeature {

    @ObservableState
    struct State: Equatable {
        /// Set by MainFeature when the user selects an STT model in the Models sheet.
        var modelPath: String? = nil
        var isRecording: Bool = false
        var isTranscribing: Bool = false
        var transcript: String = ""
        var segments: [TranscriptionSegment] = []
        var errorMessage: String? = nil
    }

    struct TranscriptionSegment: Equatable, Identifiable {
        let id = UUID()
        let text: String
        let startMs: Int64
        let endMs: Int64
    }

    enum Action {
        case recordButtonTapped
        case recordingStarted
        case recordingStopped([Float])
        case transcriptionSucceeded(TranscriptionResult)
        case transcriptionFailed(String)
        case clearTapped
    }

    @Dependency(\.speechClient) var speechClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .recordButtonTapped:
                guard let modelPath = state.modelPath else {
                    state.errorMessage = "No STT model selected. Tap the \u{24B8} icon to download one."
                    return .none
                }
                if state.isRecording {
                    state.isRecording = false
                    return .run { send in
                        let samples = await speechClient.stopRecording()
                        await send(.recordingStopped(samples))
                    }
                } else {
                    state.errorMessage = nil
                    state.isRecording  = true
                    return .run { send in
                        await speechClient.startRecording()
                        await send(.recordingStarted)
                    }
                }

            case .recordingStarted:
                return .none

            case .recordingStopped(let samples):
                guard !samples.isEmpty, let modelPath = state.modelPath else { return .none }
                state.isTranscribing = true
                return .run { [modelPath] send in
                    do {
                        let result = try await speechClient.transcribe(samples, modelPath)
                        await send(.transcriptionSucceeded(result))
                    } catch {
                        await send(.transcriptionFailed(error.localizedDescription))
                    }
                }

            case .transcriptionSucceeded(let result):
                state.isTranscribing = false
                state.transcript     = result.text
                state.segments       = result.segments.map {
                    TranscriptionSegment(text: $0.text, startMs: $0.startMs, endMs: $0.endMs)
                }
                return .none

            case .transcriptionFailed(let msg):
                state.isTranscribing = false
                state.errorMessage   = msg
                return .none

            case .clearTapped:
                state.transcript   = ""
                state.segments     = []
                state.errorMessage = nil
                return .none
            }
        }
    }
}
