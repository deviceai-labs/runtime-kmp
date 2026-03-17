import SwiftUI
import ComposableArchitecture

struct MainView: View {
    @Bindable var store: StoreOf<MainFeature>

    var body: some View {
        TabView(selection: $store.selectedTab.sending(\.tabSelected)) {

            NavigationStack {
                SpeechView(store: store.scope(state: \.speech, action: \.speech))
                    .toolbar { modelsButton }
            }
            .tabItem {
                Label("Speech", systemImage: store.selectedTab == .speech ? "mic.fill" : "mic")
            }
            .tag(MainFeature.State.Tab.speech)

            NavigationStack {
                ChatView(store: store.scope(state: \.chat, action: \.chat))
                    .toolbar { modelsButton }
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(MainFeature.State.Tab.chat)
        }
        .tint(AppTheme.accent)
        .sheet(isPresented: Binding(
            get: { store.isShowingModels },
            set: { if !$0 { store.send(.modelsDismissed) } }
        )) {
            ModelsView(store: store.scope(state: \.modelManager, action: \.modelManager))
        }
    }

    @ToolbarContentBuilder
    private var modelsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                store.send(.modelsButtonTapped)
            } label: {
                Image(systemName: "cpu")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }
}
