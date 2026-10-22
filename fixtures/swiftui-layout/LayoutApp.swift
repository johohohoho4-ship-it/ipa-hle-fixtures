import SwiftUI
import Darwin

/// One `SWL_` line per measured view; the simulator console file keeps stdout.
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
            fixtureLog("SWL_\(name)=\(snapshot[name]!)")
        }
        fixtureLog("SWL_DONE")
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

/// A custom `Layout`: its two subviews side by side, vertically centred.
struct SideBySide: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = sizes.reduce(0) { $0 + $1.width }
            + spacing * CGFloat(max(0, subviews.count - 1))
        return CGSize(width: proposal.width ?? width, height: sizes.map(\.height).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            subview.place(at: CGPoint(x: x, y: bounds.midY - size.height / 2),
                          proposal: ProposedViewSize(size))
            x += size.width + spacing
        }
    }
}

@main
struct SwiftUILayoutApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWL_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject private var log = FrameLog.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layout")
                .font(.title)
                .measured("title")

            HStack(alignment: .top, spacing: 8) {
                Text("A").frame(width: 100, height: 30).measured("hstack.a")
                Text("B").frame(width: 120, height: 30, alignment: .trailing).measured("hstack.b")
                Spacer()
            }
            .padding(8)
            .measured("hstack")

            ZStack(alignment: .bottomTrailing) {
                Color.gray.frame(width: 160, height: 60)
                Text("Z").padding(4).measured("zstack.text")
            }
            .measured("zstack")

            Text("Padded")
                .padding(10)
                .offset(x: 12, y: 4)
                .measured("offset")

            GeometryReader { proxy in
                Text("Geo")
                    .measured("geometry.text")
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .frame(width: 200, height: 50)
            .measured("geometry")

            SideBySide(spacing: 10) {
                Text("L").measured("custom.left")
                Text("R").measured("custom.right")
            }
            .frame(width: 240, height: 40)
            .measured("custom")

            Text(log.done ? "SWL_DONE" : "running")
                .accessibilityIdentifier("layout.status")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
        .measured("root")
    }
}
