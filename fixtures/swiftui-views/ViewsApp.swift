import SwiftUI
import Darwin

/// One `SWV_` line per measured view; the simulator console file keeps stdout.
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
            fixtureLog("SWV_\(name)=\(snapshot[name]!)")
        }
        fixtureLog("SWV_DONE")
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
struct SwiftUIViewsApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWV_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject private var log = FrameLog.shared
    @State private var tapped = false

    private var statusText: String {
        if !log.done {
            return "running"
        }
        return tapped ? "SWV_DONE" : "ready"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Views")
                .font(.title)
                .bold()
                .foregroundColor(.blue)
                .measured("text")

            Image(systemName: "star.fill")
                .imageScale(.large)
                .frame(width: 40, height: 40)
                .measured("image")

            Button(action: {
                tapped = true
                fixtureLog("SWV_TAP=1")
            }) {
                Label("Tap", systemImage: "hand.tap")
            }
            .accessibilityIdentifier("views.button")
            .measured("button")

            Label("Standalone", systemImage: "square")
                .measured("label")

            Text("Badge")
                .padding(8)
                .background(Color.yellow)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.red, lineWidth: 2))
                .measured("overlay")

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green)
                .frame(width: 80, height: 40)
                .measured("rounded")

            Circle()
                .fill(Color.orange)
                .frame(width: 50, height: 50)
                .measured("circle")

            Text("Corner")
                .frame(width: 120, height: 40)
                .background(Color.purple)
                .cornerRadius(8)
                .measured("corner")

            Text("Clip")
                .frame(width: 120, height: 40)
                .background(Color.teal)
                .clipShape(Circle())
                .measured("clip")

            Text(tapped ? "tapped" : "idle")
                .accessibilityIdentifier("views.state")

            Text(statusText)
                .accessibilityIdentifier("views.status")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .measured("root")
    }
}
