import SwiftUI
import Darwin

/// One `SWW_` line per measured view; the simulator console file keeps stdout.
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
            fixtureLog("SWW_\(name)=\(snapshot[name]!)")
        }
        fixtureLog("SWW_DONE")
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

let fox = "The quick brown fox jumps over the lazy dog"

@main
struct SwiftUITextWrapApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWW_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Texts offered less width than their one line needs: they wrap by words (a word wider than
/// the line breaks inside), keep only the lines a proposed height has room for, and share an
/// HStack's width with a shorter text.
struct ContentView: View {
    @ObservedObject private var log = FrameLog.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // three lines at 150 points
            Text(fox).measured("wrap.text")
                .frame(width: 150).measured("wrap")

            // two lines at 320 points; the width tells whether "lazy" moves down to "dog"
            Text(fox).measured("push.text")
                .frame(width: 320).measured("push")

            // the height has room for one line only
            Text(fox).measured("clip.text")
                .frame(width: 150, height: 30).measured("clip")

            // one word wider than the line
            Text("Supercalifragilisticexpialidocious").measured("word.text")
                .frame(width: 120).measured("word")

            // the short text is less flexible and is offered its share first
            HStack(alignment: .top, spacing: 8) {
                Text("OK").measured("pair.short")
                Text("A longer label that has to wrap").measured("pair.long")
            }
            .frame(width: 200).measured("pair")

            // a paragraph in the width the root's stack proposes
            Text("SwiftUI wraps a long text in the width its stack proposes, line after line, until all of its words are shown.")
                .measured("para")

            Text(log.done ? "SWW_DONE" : "running")
                .accessibilityIdentifier("wrap.status")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .measured("root")
    }
}
