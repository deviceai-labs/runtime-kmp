import ComposableArchitecture

@Reducer
struct MainFeature {

    @ObservableState
    struct State: Equatable {
        var selectedTab: Tab = .speech
        var isShowingModels: Bool = false
        var speech = SpeechFeature.State()
        var chat   = ChatFeature.State()
        var modelManager = ModelManagerFeature.State()

        enum Tab: Equatable { case speech, chat }
    }

    enum Action {
        case tabSelected(State.Tab)
        case modelsButtonTapped
        case modelsDismissed
        case speech(SpeechFeature.Action)
        case chat(ChatFeature.Action)
        case modelManager(ModelManagerFeature.Action)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {

            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .modelsButtonTapped:
                state.isShowingModels = true
                return .send(.modelManager(.appeared))

            case .modelsDismissed:
                state.isShowingModels = false
                return .none

            case .modelManager(.delegate(.sttModelSelected(let path))):
                state.speech.modelPath = path
                return .none

            case .modelManager(.delegate(.llmModelSelected(let path))):
                state.chat.modelPath = path
                return .none

            case .speech, .chat, .modelManager:
                return .none
            }
        }
        Scope(state: \.speech,       action: \.speech)       { SpeechFeature() }
        Scope(state: \.chat,         action: \.chat)         { ChatFeature() }
        Scope(state: \.modelManager, action: \.modelManager) { ModelManagerFeature() }
    }
}
