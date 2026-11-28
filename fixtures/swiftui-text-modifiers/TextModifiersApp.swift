import SwiftUI
import Darwin

/// One `SWM_` line per measured view; the simulator console file keeps stdout.
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
            fixtureLog("SWM_\(name)=\(snapshot[name]!)")
        }
        fixtureLog("SWM_DONE")
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
struct SwiftUITextModifiersApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWM_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// `lineLimit`, `multilineTextAlignment` and `fixedSize` on texts offered less width than their
/// one line needs, and a two-line text per text style (first line plus the style's leading).
struct ContentView: View {
    @ObservedObject private var log = FrameLog.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    // at most one, two or any number of lines at 150 points
                    Text(fox).lineLimit(1).measured("limit1.text")
                        .frame(width: 150).measured("limit1")
                    Text(fox).lineLimit(2).measured("limit2.text")
                        .frame(width: 150).measured("limit2")
                    Text(fox).lineLimit(nil).measured("limitnil.text")
                        .frame(width: 150).measured("limitnil")

                    // the limit reaches the texts of a stack; an inner nil lifts it again
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fox).measured("env.a")
                        Text(fox).lineLimit(nil).measured("env.b")
                    }
                    .lineLimit(1)
                    .frame(width: 150).measured("env")

                    // the alignment moves the lines inside the text, not its frame
                    Text(fox).multilineTextAlignment(.center).measured("center.text")
                        .frame(width: 150).measured("center")
                    Text(fox).multilineTextAlignment(.trailing).measured("trailing.text")
                        .frame(width: 150).measured("trailing")
                }

                // two lines per text style
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ab\nAb").font(.largeTitle).measured("style.largeTitle")
                    Text("Ab\nAb").font(.title).measured("style.title")
                    Text("Ab\nAb").font(.title2).measured("style.title2")
                    Text("Ab\nAb").font(.title3).measured("style.title3")
                    Text("Ab\nAb").font(.headline).measured("style.headline")
                    Text("Ab\nAb").font(.body).measured("style.body")
                    Text("Ab\nAb").font(.callout).measured("style.callout")
                    Text("Ab\nAb").font(.subheadline).measured("style.subheadline")
                    Text("Ab\nAb").font(.footnote).measured("style.footnote")
                    Text("Ab\nAb").font(.caption).measured("style.caption")
                    Text("Ab\nAb").font(.caption2).measured("style.caption2")
                }
            }

            // fixedSize proposes nil along its axes: the ideal width, all lines in a low frame
            Text(fox).fixedSize().measured("fixed.text")
                .frame(width: 150).measured("fixed")
            Text(fox).fixedSize(horizontal: false, vertical: true).measured("fixedv.text")
                .frame(width: 150, height: 30).measured("fixedv")
            Text(fox).fixedSize(horizontal: true, vertical: false).measured("fixedh.text")
                .frame(width: 150, height: 30).measured("fixedh")

            Text(log.done ? "SWM_DONE" : "running")
                .accessibilityIdentifier("modifiers.status")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .measured("root")
    }
}
