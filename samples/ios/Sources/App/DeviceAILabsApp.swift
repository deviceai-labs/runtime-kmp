import SwiftUI
import ComposableArchitecture
import DeviceAiCore

@main
struct DeviceAILabsApp: App {
    let store = Store(initialState: MainFeature.State()) { MainFeature() }

    init() {
        DeviceAI.configure { $0.environment = .staging(apiKey: "demo") }
    }

    var body: some Scene {
        WindowGroup {
            MainView(store: store)
        }
    }
}
