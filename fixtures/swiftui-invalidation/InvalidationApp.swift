import SwiftUI
import Observation
import Darwin

/// One `SWI_` line per event on stdout; the simulator console file is kept by the workflow.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

@Observable
@MainActor
final class SharedModel {
    var value = 0
}

/// Counts body evaluations without touching SwiftUI state, so the counter itself
/// does not invalidate a view.
final class Counters {
    static let shared = Counters()
    private var values = ["A": 0, "B": 0, "C": 0]
    private let lock = NSLock()

    func bump(_ name: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        values[name, default: 0] += 1
        return values[name] ?? 0
    }

    func snapshot() -> String {
        lock.lock()
        defer { lock.unlock() }
        return "A=\(values["A"] ?? 0) B=\(values["B"] ?? 0) C=\(values["C"] ?? 0)"
    }
}

@main
struct InvalidationApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWI_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ChildA: View {
    @Binding var value: Int

    var body: some View {
        let count = Counters.shared.bump("A")
        fixtureLog("SWI_BODY A=\(count) value=\(value)")
        return Text("A \(value)")
            .accessibilityIdentifier("swi.a")
    }
}

struct ChildB: View {
    @Environment(SharedModel.self) private var model

    var body: some View {
        let count = Counters.shared.bump("B")
        fixtureLog("SWI_BODY B=\(count) value=\(model.value)")
        return Text("B \(model.value)")
            .accessibilityIdentifier("swi.b")
    }
}

struct ChildC: View {
    var body: some View {
        let count = Counters.shared.bump("C")
        fixtureLog("SWI_BODY C=\(count) static")
        return Text("C")
            .accessibilityIdentifier("swi.c")
    }
}

struct ContentView: View {
    @State private var value = 0
    @State private var model = SharedModel()
    @State private var phase = "running"
    @State private var didStart = false

    var body: some View {
        VStack(spacing: 12) {
            ChildA(value: $value)
            ChildB()
                .environment(model)
            ChildC()
            Text(phase)
                .accessibilityIdentifier("swi.status")
        }
        .padding()
        .onAppear {
            guard !didStart else { return }
            didStart = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                fixtureLog("SWI_INITIAL \(Counters.shared.snapshot())")
                value += 1
                try? await Task.sleep(for: .milliseconds(400))
                fixtureLog("SWI_AFTER_STATE \(Counters.shared.snapshot())")
                model.value += 1
                try? await Task.sleep(for: .milliseconds(400))
                fixtureLog("SWI_AFTER_MODEL \(Counters.shared.snapshot())")
                fixtureLog("SWI_DONE")
                phase = "SWI_DONE"
            }
        }
    }
}
