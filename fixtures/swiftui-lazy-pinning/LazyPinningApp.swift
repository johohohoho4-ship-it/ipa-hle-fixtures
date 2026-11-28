import SwiftUI
import UIKit
import Darwin

/// One `SWLP_` line per measured view or value; the simulator console file keeps stdout.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

/// A small raw value as text without generic integer formatting.
func rawText(_ value: UInt32) -> String {
    if value == 0 { return "0" }
    if value == 1 { return "1" }
    if value == 2 { return "2" }
    if value == 3 { return "3" }
    return "other"
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
            fixtureLog("SWLP_\(name)=\(text(snapshot[name]!))")
        }
        fixtureLog("SWLP_DONE")
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
struct SwiftUILazyPinningApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWLP_START")
        // The public flags by value: the static getters, the array literal
        // (SetAlgebra.init(arrayLiteral:)), the type's own raw initializer and the
        // empty set (OptionSet.init()).
        let headers = PinnedScrollableViews.sectionHeaders
        let footers = PinnedScrollableViews.sectionFooters
        let both: PinnedScrollableViews = [.sectionHeaders, .sectionFooters]
        let raw = PinnedScrollableViews(rawValue: 2)
        let empty = PinnedScrollableViews()
        fixtureLog("SWLP_RAW_HEADERS=" + rawText(headers.rawValue))
        fixtureLog("SWLP_RAW_FOOTERS=" + rawText(footers.rawValue))
        fixtureLog("SWLP_RAW_BOTH=" + rawText(both.rawValue))
        fixtureLog("SWLP_RAW_INIT=" + rawText(raw.rawValue))
        fixtureLog("SWLP_RAW_EMPTY=" + rawText(empty.rawValue))
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
            Text(log.done ? "ready" : "running")
                .accessibilityIdentifier("pin.status")

            // Header flag alone (static getter), no Section: a lazy stack like the others.
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                    ForEach(0..<6, id: \.self) { index in
                        Text("Head \(index)")
                            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                            .measured("headers.row.\(index)")
                    }
                }
            }
            .frame(height: 70)
            .measured("headers")

            // Both flags (array literal) on an outer stack without a Section of its own,
            // around a scroll view whose unpinned lazy stack has one.
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders, .sectionFooters]) {
                    Text("Outer")
                        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                        .measured("outer.row")
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            Section(header: Text("Inner header").measured("inner.header")) {
                                ForEach(0..<3, id: \.self) { index in
                                    Text("Inner \(index)")
                                        .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                                        .measured("inner.row.\(index)")
                                }
                            }
                        }
                    }
                    .frame(height: 60)
                    .measured("inner")
                }
            }
            .frame(height: 100)
            .measured("outer")

            // No column alignment, the grid aligned leading, the footer flag: the flexible
            // columns fill the width, so only a cell alignment moves the narrow tiles.
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                      alignment: .leading, spacing: 8, pinnedViews: .sectionFooters) {
                ForEach(0..<4, id: \.self) { index in
                    Color.blue.opacity(0.3)
                        .frame(width: 40, height: index % 2 == 0 ? 20 : 36)
                        .measured("nil.tile.\(index)")
                }
            }
            .measured("nilGrid")

            // Fixed columns with explicit alignments (and one without), mixed heights,
            // the grid aligned trailing and narrower than its parent: the grid's frame
            // and the tiles' frames separate the grid's place from the cell alignment.
            LazyVGrid(columns: [GridItem(.fixed(100), alignment: .leading),
                                GridItem(.fixed(100), alignment: .bottomTrailing),
                                GridItem(.fixed(60))],
                      alignment: .trailing, spacing: 8, pinnedViews: [.sectionHeaders]) {
                ForEach(0..<6, id: \.self) { index in
                    Color.blue.opacity(0.5)
                        .frame(width: 30, height: index % 3 == 1 ? 40 : 20)
                        .measured("aligned.tile.\(index)")
                }
            }
            .measured("alignedGrid")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white)
    }
}
