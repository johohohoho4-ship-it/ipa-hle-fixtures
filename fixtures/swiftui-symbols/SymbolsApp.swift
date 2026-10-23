import SwiftUI
import Darwin

/// One `SWS_` line per measured view; the simulator console file keeps stdout.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

/// Collects the global frames of all measured views and prints them sorted once
/// the first layout pass is over, so the order does not depend on appearance order.
final class FrameLog: ObservableObject {
    static let shared = FrameLog()
    @Published private(set) var done = false

    private var frames: [String: String] = [:]
    private var scheduled = false
    private let lock = NSLock()

    func record(_ name: String, _ frame: CGRect) {
        let text = String(format: "%.2f,%.2f,%.2f,%.2f",
                          frame.minX, frame.minY, frame.width, frame.height)
        lock.lock()
        frames[name] = text
        let first = !scheduled
        if first { scheduled = true }
        lock.unlock()
        if first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.flush() }
        }
    }

    private func flush() {
        lock.lock()
        let snapshot = frames
        lock.unlock()
        for name in snapshot.keys.sorted() {
            fixtureLog("SWS_\(name)=\(snapshot[name]!)")
        }
        fixtureLog("SWS_DONE")
        done = true
    }
}

struct Measured: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content.background(GeometryReader { proxy in
            Color.clear.onAppear {
                FrameLog.shared.record(name, proxy.frame(in: .global))
            }
        })
    }
}

extension View {
    func measured(_ name: String) -> some View {
        modifier(Measured(name: name))
    }
}

@main
struct SwiftUISymbolsApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWS_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject private var log = FrameLog.shared
    @State private var announcedScreen = false

    private var statusText: String {
        log.done ? "ready" : "running"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "star.fill")
                .measured("image.star.fill")
            Image(systemName: "star.fill")
                .imageScale(.large)
                .measured("image.star.fill.large")
            Image(systemName: "hand.tap")
                .measured("image.hand.tap")
            Image(systemName: "hand.tap")
                .imageScale(.large)
                .measured("image.hand.tap.large")
            Image(systemName: "square")
                .measured("image.square")
            Image(systemName: "square")
                .imageScale(.large)
                .measured("image.square.large")

            Label("Tap", systemImage: "hand.tap")
                .measured("label.tap")
            Label("Tap", systemImage: "hand.tap")
                .labelStyle(.iconOnly)
                .measured("label.tap.iconOnly")
            Label("Tap", systemImage: "hand.tap")
                .labelStyle(.titleOnly)
                .measured("label.tap.titleOnly")
            Label("Standalone", systemImage: "square")
                .measured("label.standalone")
            Label("Standalone", systemImage: "square")
                .labelStyle(.iconOnly)
                .measured("label.standalone.iconOnly")
            Label("Standalone", systemImage: "square")
                .labelStyle(.titleOnly)
                .measured("label.standalone.titleOnly")

            Text("Views")
                .font(.title)
                .measured("text.title")
            Text("Views")
                .font(.title)
                .bold()
                .measured("text.title.bold")

            Text(statusText)
                .accessibilityIdentifier("symbols.status")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .onAppear {
            guard !announcedScreen else { return }
            announcedScreen = true
            let bounds = UIScreen.main.bounds
            fixtureLog(String(format: "SWS_SCREEN=%.2f,%.2f,%.2f,%.2f",
                              bounds.minX, bounds.minY, bounds.width, bounds.height))
        }
        .measured("root")
    }
}
