import SwiftUI

@main
struct MyClosetApp: App {
    @StateObject private var store = ClosetStore()
    @StateObject private var weather = WeatherService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(weather)
                .tint(ClosetTheme.accent)
        }
    }
}
