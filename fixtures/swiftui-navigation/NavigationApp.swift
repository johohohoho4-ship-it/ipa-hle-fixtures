import SwiftUI
import Darwin

/// One `NAV_` line per event on stdout; the simulator console file is kept by the workflow.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

func typeLine<V>(_ label: String, _ value: V) -> String {
    "NAV_TYPE \(label) \(String(reflecting: type(of: value)))"
}

/// Generic, not `Any`: `MemoryLayout` of an existential would measure the container, not the view.
func layoutLine<V>(_ label: String, _ value: V) -> String {
    let size = MemoryLayout<V>.size
    let stride = MemoryLayout<V>.stride
    let alignment = MemoryLayout<V>.alignment
    return "NAV_LAYOUT \(label) size=\(size) stride=\(stride) alignment=\(alignment)"
}

func insetsText(_ insets: EdgeInsets) -> String {
    String(format: "top=%.1f left=%.1f bottom=%.1f right=%.1f",
           Double(insets.top), Double(insets.leading), Double(insets.bottom), Double(insets.trailing))
}

func frameText(_ frame: CGRect) -> String {
    String(format: "%.2f,%.2f,%.2f,%.2f",
           Double(frame.minX), Double(frame.minY), Double(frame.width), Double(frame.height))
}

func geometryLine(_ name: String, _ geo: GeometryProxy) -> String {
    "NAV_GEOM \(name) size=\(Int(geo.size.width))x\(Int(geo.size.height)) insets=\(insetsText(geo.safeAreaInsets))"
}

@main
struct NavigationApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("NAV_START")
        measureStaticTypes()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// The navigation shapes apps hand to SwiftUI: both stack initializers, the deprecated
/// `NavigationView`, both link kinds and the three modifiers on the pushed content.
func measureStaticTypes() {
    let stack = NavigationStack {
        Text("r")
    }
    let pathStack = NavigationStack(path: .constant([Int]())) {
        Text("r")
    }
    let navigationView = NavigationView {
        Text("r")
    }
    let link = NavigationLink(destination: Text("d")) {
        Text("l")
    }
    let valueLink = NavigationLink(value: 1) {
        Text("v")
    }
    let titled = Text("t").navigationTitle("T")
    let inline = Text("t").navigationBarTitleDisplayMode(.inline)
    let destination = Text("t").navigationDestination(for: Int.self) { number in
        Text("\(number)")
    }
    fixtureLog(typeLine("stack", stack))
    fixtureLog(layoutLine("stack", stack))
    fixtureLog(typeLine("pathstack", pathStack))
    fixtureLog(layoutLine("pathstack", pathStack))
    fixtureLog(typeLine("navigationview", navigationView))
    fixtureLog(layoutLine("navigationview", navigationView))
    fixtureLog(typeLine("link", link))
    fixtureLog(layoutLine("link", link))
    fixtureLog(typeLine("valuelink", valueLink))
    fixtureLog(layoutLine("valuelink", valueLink))
    fixtureLog(typeLine("title", titled))
    fixtureLog(layoutLine("title", titled))
    fixtureLog(typeLine("inline", inline))
    fixtureLog(layoutLine("inline", inline))
    fixtureLog(typeLine("destination", destination))
    fixtureLog(layoutLine("destination", destination))
}

/// Each name once: a view that appears again (after a pop) keeps its first frame.
final class FrameLog {
    static let shared = FrameLog()
    private var seen = Set<String>()

    func record(_ name: String, _ frame: CGRect) {
        guard !seen.contains(name) else { return }
        seen.insert(name)
        fixtureLog("NAV_FRAME \(name)=\(frameText(frame))")
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

/// The root: a large title, a link with a destination view and a link with a value.
struct RootView: View {
    @State private var reported = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                Text("Root screen")
                    .accessibilityIdentifier("nav.root")
                    .measured("root.text")
                NavigationLink(destination: DetailA()) {
                    Text("Push A")
                }
                .accessibilityIdentifier("nav.link.a")
                .measured("link.a")
                NavigationLink(value: 2) {
                    Text("Push 2")
                }
                .accessibilityIdentifier("nav.link.2")
                .measured("link.2")
            }
            .onAppear {
                guard !reported else { return }
                reported = true
                fixtureLog(geometryLine("root", geo))
            }
        }
        .navigationTitle("Root")
        .onAppear { fixtureLog("NAV_APPEAR root") }
        .onDisappear { fixtureLog("NAV_DISAPPEAR root") }
    }
}

/// Pushed by `NavigationLink(destination:)`; the title display mode stays automatic.
struct DetailA: View {
    @State private var reported = false

    var body: some View {
        GeometryReader { geo in
            Text("Detail A")
                .accessibilityIdentifier("nav.a")
                .measured("a.text")
                .onAppear {
                    guard !reported else { return }
                    reported = true
                    fixtureLog(geometryLine("a", geo))
                }
        }
        .navigationTitle("A")
        .onAppear { fixtureLog("NAV_APPEAR a") }
        .onDisappear { fixtureLog("NAV_DISAPPEAR a") }
    }
}

/// Pushed by `NavigationLink(value:)` through the root's `navigationDestination(for: Int.self)`;
/// number 2 pushes number 3 the same way, so the stack is two values deep. Inline title.
struct NumberView: View {
    let number: Int
    @State private var reported = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                Text("Number \(number)")
                    .accessibilityIdentifier("nav.number.\(number)")
                    .measured("number.\(number).text")
                if number < 3 {
                    NavigationLink(value: number + 1) {
                        Text("Push \(number + 1)")
                    }
                    .accessibilityIdentifier("nav.link.\(number + 1)")
                }
            }
            .onAppear {
                guard !reported else { return }
                reported = true
                fixtureLog(geometryLine("number.\(number)", geo))
            }
        }
        .navigationTitle("Number \(number)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { fixtureLog("NAV_APPEAR number.\(number)") }
        .onDisappear { fixtureLog("NAV_DISAPPEAR number.\(number)") }
    }
}

struct ContentView: View {
    @State private var didMeasure = false

    var body: some View {
        let stack = NavigationStack {
            RootView()
                .navigationDestination(for: Int.self) { number in
                    NumberView(number: number)
                }
        }
        return stack
            .onAppear {
                guard !didMeasure else { return }
                didMeasure = true
                fixtureLog(typeLine("root", stack))
                fixtureLog(layoutLine("root", stack))
            }
    }
}
