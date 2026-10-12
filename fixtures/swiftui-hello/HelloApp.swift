import SwiftUI
import Darwin

/// One `SWU_` line per event on stdout; in the simulator stdout goes to the console file the workflow keeps.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

@main
struct SwiftUIHelloApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWU_HELLO_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Hello, SwiftUI")
                .font(.title)
                .accessibilityIdentifier("hello.title")
            Text("IPA-HLE H1")
                .foregroundColor(.secondary)
                .accessibilityIdentifier("hello.subtitle")
        }
        .padding()
        .onAppear { fixtureLog("SWU_HELLO_APPEAR") }
    }
}
