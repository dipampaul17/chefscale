import SwiftUI

@main
struct ChefScaleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NSApplication.shared.setActivationPolicy(.regular)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultSize(width: 400, height: 300)
    }
} 