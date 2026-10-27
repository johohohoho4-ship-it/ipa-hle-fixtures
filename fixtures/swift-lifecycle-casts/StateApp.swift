import SwiftUI
import UIKit
import Darwin

/// One `CAST_` line per event on stdout; the simulator console file is kept by the workflow.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

final class StateHolder {
    deinit { fixtureLog("CAST_DEINIT State") }
}

final class ObservedThing: ObservableObject {
    @Published var value = 0
    deinit { fixtureLog("CAST_DEINIT StateObject") }
}

/// The hosted view whose `@State` and `@StateObject` values must die with the hosting controller.
struct Hosted: View {
    @State private var holder = StateHolder()
    @StateObject private var model = ObservedThing()

    var body: some View {
        Text("hosted")
            .accessibilityIdentifier("cast.hosted")
    }
}

class Base<T> {}
final class Sub: Base<String> {}

final class Harness {
    static let shared = Harness()
    private var window: UIWindow?
    private var hosting: UIHostingController<Hosted>?
    private var started = false

    func start(onDone: @escaping @MainActor () -> Void) {
        guard !started else { return }
        started = true
        let window = UIWindow(frame: UIScreen.main.bounds)
        let hosting = UIHostingController(rootView: Hosted())
        window.rootViewController = hosting
        window.makeKeyAndVisible()
        self.window = window
        self.hosting = hosting
        fixtureLog("CAST_HOST_CREATED")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            fixtureLog("CAST_HOST_TEARDOWN_BEGIN")
            window.isHidden = true
            window.rootViewController = nil
            self.hosting = nil
            self.window = nil
            fixtureLog("CAST_HOST_RELEASED")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            fixtureLog("CAST_HOST_TEARDOWN_END")
            self.runSwiftCasts()
            ipahle_run_cpp_casts()
            fixtureLog("CAST_DONE")
            onDone()
        }
    }

    func runSwiftCasts() {
        let sub = Sub()
        let same = (sub as? Base<String>) != nil
        let other = (sub as? Base<Int>) == nil
        let upcast: Base<String> = sub
        fixtureLog("CAST_SWIFT same=\(same) other=\(other) upcast=\(upcast is Base<String>)")
    }
}

@main
struct LifecycleCastsApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "a", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("CAST_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var phase = "running"
    @State private var didStart = false
    private let trapOnly = ProcessInfo.processInfo.environment["CAST_TRAP_ONLY"] == "1"

    var body: some View {
        Group {
            if trapOnly {
                VStack(spacing: 12) {
                    Text(phase)
                        .accessibilityIdentifier("cast.status")
                    Button("Crash") {
                        Self.trap()
                    }
                    .accessibilityIdentifier("cast.crash")
                }
            } else {
                VStack(spacing: 12) {
                    Text(phase)
                        .accessibilityIdentifier("cast.status")
                    Button("Crash") {
                        Self.trap()
                    }
                    .accessibilityIdentifier("cast.crash")
                }
                .onAppear {
                    guard !didStart else { return }
                    didStart = true
                    Harness.shared.start { phase = "CAST_DONE" }
                }
            }
        }
        .onAppear {
            if trapOnly {
                phase = "TRAP_READY"
            }
        }
    }

    static func trap() {
        let sub = Sub()
        fixtureLog("CAST_SWIFT_TRAP_BEGIN")
        _ = sub as! Base<Int>
        fixtureLog("CAST_SWIFT_TRAP_END")
    }
}
