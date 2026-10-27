import SwiftUI
import Darwin

/// One `TAB_` line per event on stdout; the simulator console file is kept by the workflow.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

func typeLine<V>(_ label: String, _ value: V) -> String {
    "TAB_TYPE \(label) \(String(reflecting: type(of: value)))"
}

/// Generic, not `Any`: `MemoryLayout` of an existential would measure the container, not the view.
func layoutLine<V>(_ label: String, _ value: V) -> String {
    let size = MemoryLayout<V>.size
    let stride = MemoryLayout<V>.stride
    let alignment = MemoryLayout<V>.alignment
    return "TAB_LAYOUT \(label) size=\(size) stride=\(stride) alignment=\(alignment)"
}

func insetsText(_ insets: EdgeInsets) -> String {
    String(format: "top=%.1f left=%.1f bottom=%.1f right=%.1f",
           Double(insets.top), Double(insets.leading), Double(insets.bottom), Double(insets.trailing))
}

@main
struct TabViewApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("TAB_START")
        measureStaticTypes()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// The shapes ExpenseTracker hands to `UIHostingController.rootView:` — a tab item whose label is
/// a `VStack` of `Text` and `Image(systemName:)`, tagged 0/1, inside a `TabView(selection:)`.
func measureStaticTypes() {
    let tabItem = Text("x").tabItem {
        VStack {
            Text("x")
            Image(systemName: "star")
        }
    }
    let tag = Text("x").tag(0)
    let whole = TabView(selection: .constant(0)) {
        Text("a").tabItem { Text("a") }.tag(0)
        Text("b").tabItem { Text("b") }.tag(1)
    }
    fixtureLog(typeLine("tabitem", tabItem))
    fixtureLog(layoutLine("tabitem", tabItem))
    fixtureLog(typeLine("tag", tag))
    fixtureLog(layoutLine("tag", tag))
    fixtureLog(typeLine("tabview", whole))
    fixtureLog(layoutLine("tabview", whole))
}

struct TabOne: View {
    @State private var reported = false

    var body: some View {
        GeometryReader { geo in
            Text("One")
                .accessibilityIdentifier("tab.one")
                .onAppear {
                    guard !reported else { return }
                    reported = true
                    fixtureLog("TAB_GEOM one size=\(Int(geo.size.width))x\(Int(geo.size.height)) insets=\(insetsText(geo.safeAreaInsets))")
                }
        }
        .onAppear { fixtureLog("TAB_APPEAR one") }
    }
}

struct TabTwo: View {
    @State private var reported = false

    var body: some View {
        GeometryReader { geo in
            Text("Two")
                .accessibilityIdentifier("tab.two")
                .onAppear {
                    guard !reported else { return }
                    reported = true
                    fixtureLog("TAB_GEOM two size=\(Int(geo.size.width))x\(Int(geo.size.height)) insets=\(insetsText(geo.safeAreaInsets))")
                }
        }
        .onAppear { fixtureLog("TAB_APPEAR two") }
    }
}

struct ContentView: View {
    @State private var selection = 0
    @State private var didMeasure = false

    var body: some View {
        let tab = TabView(selection: $selection) {
            TabOne()
                .tabItem {
                    VStack {
                        Text("One")
                        Image(systemName: "1.circle")
                    }
                }
                .tag(0)
            TabTwo()
                .tabItem {
                    VStack {
                        Text("Two")
                        Image(systemName: "2.circle")
                    }
                }
                .tag(1)
        }
        return tab
            .overlay(alignment: .top) {
                Text("TAB_SELECTION \(selection)")
                    .accessibilityIdentifier("tab.status")
                    .padding(4)
            }
            .onAppear {
                guard !didMeasure else { return }
                didMeasure = true
                fixtureLog(typeLine("root", tab))
                fixtureLog(layoutLine("root", tab))
                fixtureLog("TAB_INITIAL selection=\(selection)")
            }
            .onChange(of: selection) { _oldValue, newValue in
                fixtureLog("TAB_SELECTION \(newValue)")
                if newValue == 1 {
                    fixtureLog("TAB_DONE")
                }
            }
    }
}
