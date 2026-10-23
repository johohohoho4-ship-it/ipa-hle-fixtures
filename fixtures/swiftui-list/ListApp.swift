import SwiftUI
import Darwin

/// One `SWLI_` line per measured view; the simulator console file keeps stdout.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

/// Collects the global frames of all measured views and prints them sorted once
/// the first layout pass is over, so the order does not depend on appearance order.
final class FrameLog: ObservableObject {
    static let shared = FrameLog()
    @Published private(set) var done = false

    private var frames: [String: CGRect] = [:]
    private var scheduled = false
    private let lock = NSLock()

    func record(_ name: String, _ frame: CGRect) {
        lock.lock()
        frames[name] = frame
        let first = !scheduled
        if first { scheduled = true }
        lock.unlock()
        if first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.flush() }
        }
    }

    private func text(_ frame: CGRect) -> String {
        String(format: "%.2f,%.2f,%.2f,%.2f",
               frame.minX, frame.minY, frame.width, frame.height)
    }

    private func flush() {
        lock.lock()
        let snapshot = frames
        lock.unlock()
        for name in snapshot.keys.sorted() {
            fixtureLog("SWLI_\(name)=\(text(snapshot[name]!))")
        }
        fixtureLog("SWLI_DONE")
        done = true
    }

    /// Prints the first list row that is inside the list's visible frame after the swipe.
    func flushAfter() {
        lock.lock()
        let snapshot = frames
        lock.unlock()
        guard let list = snapshot["list"] else { return }
        let rows = snapshot
            .filter { $0.key.hasPrefix("list.row.") && $0.value.minY >= list.minY - 1 && $0.value.minY < list.maxY }
            .sorted { $0.value.minY < $1.value.minY }
        if let first = rows.first {
            fixtureLog("SWLI_AFTER_\(first.key)=\(text(first.value))")
        }
        fixtureLog("SWLI_AFTER_DONE")
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
struct SwiftUIListApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWLI_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject private var log = FrameLog.shared
    @State private var after = false

    private var statusText: String {
        if !log.done { return "running" }
        return after ? "after" : "ready"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("AfterScroll") {
                    log.flushAfter()
                    after = true
                }
                .accessibilityIdentifier("list.after")
                Text(statusText)
                    .accessibilityIdentifier("list.status")
            }

            List {
                ForEach(0..<30, id: \.self) { index in
                    Text("Row \(index)")
                        .frame(height: 36, alignment: .leading)
                        .measured("list.row.\(index)")
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {} label: { Text("Delete") }
                        }
                }
            }
            .listStyle(.plain)
            .frame(height: 180)
            .measured("list")

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { index in
                        Text("Stack \(index)")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .measured("stack.row.\(index)")
                    }
                }
            }
            .frame(height: 130)
            .measured("scrollVStack")

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<20, id: \.self) { index in
                        Text("Lazy \(index)")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .measured("lazy.row.\(index)")
                    }
                }
            }
            .frame(height: 130)
            .measured("lazyVStack")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(0..<8, id: \.self) { index in
                    Text("Tile \(index)")
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(Color.blue.opacity(0.2))
                        .measured("grid.tile.\(index)")
                }
            }
            .frame(height: 160)
            .measured("grid")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }
}
