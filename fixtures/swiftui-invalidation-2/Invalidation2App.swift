import SwiftUI
import Darwin

/// One `SWI2_` line per event on stdout; the simulator console file is kept by the workflow.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

/// Counts body evaluations without touching SwiftUI state, so the counter itself
/// does not invalidate a view.
final class Counters {
    static let shared = Counters()
    private var values = ["D": 0, "E": 0, "F": 0]
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
        return "D=\(values["D"] ?? 0) E=\(values["E"] ?? 0) F=\(values["F"] ?? 0)"
    }
}

final class PublishedModel: ObservableObject {
    @Published var value = 0
}

/// A child with a non-POD value (`String`): the parent passes an equal title again.
struct ChildD: View {
    let title: String

    var body: some View {
        let count = Counters.shared.bump("D")
        fixtureLog("SWI2_BODY D=\(count) title=\(title)")
        return Text("D \(title)")
            .accessibilityIdentifier("swi2.d")
    }
}

/// A child that subscribes to one `@Published` property through `@ObservedObject`.
struct ChildE: View {
    @ObservedObject var model: PublishedModel

    var body: some View {
        let count = Counters.shared.bump("E")
        fixtureLog("SWI2_BODY E=\(count) value=\(model.value)")
        return Text("E \(model.value)")
            .accessibilityIdentifier("swi2.e")
    }
}

/// A static child that does not subscribe to anything.
struct ChildF: View {
    var body: some View {
        let count = Counters.shared.bump("F")
        fixtureLog("SWI2_BODY F=\(count) static")
        return Text("F")
            .accessibilityIdentifier("swi2.f")
    }
}

@main
struct Invalidation2App: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWI2_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var value = 0
    @StateObject private var model = PublishedModel()
    @State private var phase = "running"
    @State private var didStart = false

    /// Non-POD child value: equal text with a new heap buffer for the first change (longer than the
    /// small-string limit), a different text for the second.
    private var title: String {
        value < 2 ? String(repeating: "x", count: 24)
                  : "changed-" + String(repeating: "y", count: 16) + "-\(value)"
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("value \(value)")
                .accessibilityIdentifier("swi2.value")
            ChildD(title: title)
            ChildE(model: model)
            ChildF()
            Text(phase)
                .accessibilityIdentifier("swi2.status")
        }
        .padding()
        .onChange(of: value) { oldValue, newValue in
            fixtureLog("SWI2_ONCHANGE \(oldValue)->\(newValue)")
        }
        .onAppear {
            guard !didStart else { return }
            didStart = true
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(400))
                fixtureLog("SWI2_INITIAL \(Counters.shared.snapshot())")
                value += 1
                try? await Task.sleep(for: .milliseconds(400))
                fixtureLog("SWI2_AFTER_STATE \(Counters.shared.snapshot())")
                value += 1
                try? await Task.sleep(for: .milliseconds(400))
                fixtureLog("SWI2_AFTER_STATE2 \(Counters.shared.snapshot())")
                model.value += 1
                try? await Task.sleep(for: .milliseconds(400))
                fixtureLog("SWI2_AFTER_PUBLISHED \(Counters.shared.snapshot())")
                fixtureLog("SWI2_DONE")
                phase = "SWI2_DONE"
            }
        }
    }
}
