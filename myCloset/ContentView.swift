import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ClosetStore
    @EnvironmentObject private var weather: WeatherService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ClosetView()
                .tabItem { Label("Closet", systemImage: "hanger") }
                .tag(1)

            GeneratorView()
                .tabItem { Label("Generate", systemImage: "sparkles") }
                .tag(2)

            FollowingView()
                .tabItem { Label("Following", systemImage: "person.2.fill") }
                .tag(3)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(4)
        }
        .task {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-resetPrototypeData") {
                store.clearPrototypeData()
            }
            if ProcessInfo.processInfo.arguments.contains("-loadPrototypeSamples") {
                store.loadSamples()
                store.refreshDaily(weather: weather.context, force: true)
            }
            if ProcessInfo.processInfo.arguments.contains("-openPrototypeGenerator") {
                selectedTab = 2
            }
#endif
        }
    }
}
