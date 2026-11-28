import SwiftUI
import Darwin

/// One `PRS_` line per event on stdout; the simulator console file is kept by the workflow.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

func typeLine<V>(_ label: String, _ value: V) -> String {
    "PRS_TYPE \(label) \(String(reflecting: type(of: value)))"
}

/// Generic, not `Any`: `MemoryLayout` of an existential would measure the container, not the view.
func layoutLine<V>(_ label: String, _ value: V) -> String {
    let size = MemoryLayout<V>.size
    let stride = MemoryLayout<V>.stride
    let alignment = MemoryLayout<V>.alignment
    return "PRS_LAYOUT \(label) size=\(size) stride=\(stride) alignment=\(alignment)"
}

func insetsText(_ insets: EdgeInsets) -> String {
    String(format: "top=%.1f left=%.1f bottom=%.1f right=%.1f",
           Double(insets.top), Double(insets.leading), Double(insets.bottom), Double(insets.trailing))
}

func frameText(_ frame: CGRect) -> String {
    String(format: "%.2f,%.2f,%.2f,%.2f",
           Double(frame.minX), Double(frame.minY), Double(frame.width), Double(frame.height))
}

@main
struct PresentationApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("PRS_START")
        measureStaticTypes()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// The presentation shapes apps hand to SwiftUI: `sheet` with and without `onDismiss`, `alert`
/// with and without a message, `toolbar` with one item, two items and a plain view, the item
/// and its placements, a button with a role and a stack bound to a `NavigationPath`.
func measureStaticTypes() {
    let sheet = Text("t").sheet(isPresented: .constant(false)) {
        Text("s")
    }
    let sheetDismiss = Text("t").sheet(isPresented: .constant(false), onDismiss: {}) {
        Text("s")
    }
    let alert = Text("t").alert("A", isPresented: .constant(false)) {
        Button("OK") {}
    }
    let alertMessage = Text("t").alert("A", isPresented: .constant(false)) {
        Button("OK") {}
    } message: {
        Text("m")
    }
    let item = ToolbarItem(placement: .topBarTrailing) {
        Button("B") {}
    }
    let toolbar = Text("t").toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button("B") {}
        }
    }
    let toolbarTwo = Text("t").toolbar {
        ToolbarItem(placement: .topBarLeading) {
            Button("L") {}
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("R") {}
        }
    }
    let toolbarView = Text("t").toolbar {
        Button("B") {}
    }
    let roleButton = Button("D", role: .destructive) {}
    let pathStack = NavigationStack(path: .constant(NavigationPath())) {
        Text("r")
    }
    fixtureLog(typeLine("sheet", sheet))
    fixtureLog(layoutLine("sheet", sheet))
    fixtureLog(typeLine("sheetdismiss", sheetDismiss))
    fixtureLog(layoutLine("sheetdismiss", sheetDismiss))
    fixtureLog(typeLine("alert", alert))
    fixtureLog(layoutLine("alert", alert))
    fixtureLog(typeLine("alertmessage", alertMessage))
    fixtureLog(layoutLine("alertmessage", alertMessage))
    fixtureLog(typeLine("item", item))
    fixtureLog(layoutLine("item", item))
    fixtureLog(typeLine("toolbar", toolbar))
    fixtureLog(layoutLine("toolbar", toolbar))
    fixtureLog(typeLine("toolbartwo", toolbarTwo))
    fixtureLog(layoutLine("toolbartwo", toolbarTwo))
    fixtureLog(typeLine("toolbarview", toolbarView))
    fixtureLog(layoutLine("toolbarview", toolbarView))
    fixtureLog(typeLine("rolebutton", roleButton))
    fixtureLog(layoutLine("rolebutton", roleButton))
    fixtureLog(layoutLine("placement", ToolbarItemPlacement.topBarTrailing))
    fixtureLog(layoutLine("role", ButtonRole.destructive))
    fixtureLog(typeLine("pathstack", pathStack))
    fixtureLog(layoutLine("pathstack", pathStack))
}

/// Each name once: a view that appears again keeps its first frame.
final class FrameLog {
    static let shared = FrameLog()
    private var seen = Set<String>()

    func record(_ name: String, _ frame: CGRect) {
        guard !seen.contains(name) else { return }
        seen.insert(name)
        fixtureLog("PRS_FRAME \(name)=\(frameText(frame))")
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

/// The root of a stack bound to `path`: a value link (it appends to the path), a button that
/// shows an alert, a toolbar with a leading button that shows a sheet and a trailing one that
/// appends to the path.
struct RootView: View {
    @Binding var path: [Int]
    @State private var showSheet = false
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Root screen")
                .accessibilityIdentifier("prs.root")
            NavigationLink(value: 1) {
                Text("Push 1")
            }
            .accessibilityIdentifier("prs.link.1")
            Button("Alert") {
                fixtureLog("PRS_ACTION alert")
                showAlert = true
            }
            .accessibilityIdentifier("prs.alert")
        }
        .navigationTitle("Root")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Sheet") {
                    fixtureLog("PRS_ACTION sheet")
                    showSheet = true
                }
                .accessibilityIdentifier("prs.sheet.open")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    path.append(path.count + 1)
                    fixtureLog("PRS_ACTION add count=\(path.count)")
                }
                .accessibilityIdentifier("prs.add")
            }
        }
        .sheet(isPresented: $showSheet, onDismiss: {
            fixtureLog("PRS_DISMISS sheet presented=\(showSheet)")
        }) {
            SheetView(isPresented: $showSheet)
        }
        .alert("Delete item?", isPresented: $showAlert) {
            Button("Delete", role: .destructive) {
                fixtureLog("PRS_ALERT delete presented=\(showAlert)")
            }
            Button("Cancel", role: .cancel) {
                fixtureLog("PRS_ALERT cancel presented=\(showAlert)")
            }
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear { fixtureLog("PRS_APPEAR root count=\(path.count)") }
        .onDisappear { fixtureLog("PRS_DISAPPEAR root count=\(path.count)") }
    }
}

/// A pushed value: inline title, a value link one level deeper on the first, and a trailing
/// toolbar button that empties the path (back to the root in one step).
struct NumberView: View {
    let number: Int
    @Binding var path: [Int]

    var body: some View {
        VStack(spacing: 16) {
            Text("Number \(number)")
                .accessibilityIdentifier("prs.number.\(number)")
            if number < 2 {
                NavigationLink(value: number + 1) {
                    Text("Push \(number + 1)")
                }
                .accessibilityIdentifier("prs.link.\(number + 1)")
            }
        }
        .navigationTitle("Number \(number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Pop") {
                    fixtureLog("PRS_ACTION pop count=\(path.count)")
                    path = []
                }
                .accessibilityIdentifier("prs.pop")
            }
        }
        .onAppear { fixtureLog("PRS_APPEAR number.\(number) count=\(path.count)") }
        .onDisappear { fixtureLog("PRS_DISAPPEAR number.\(number) count=\(path.count)") }
    }
}

/// The sheet's content: its geometry once, a text and a button that closes it through the binding.
struct SheetView: View {
    @Binding var isPresented: Bool
    @State private var reported = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                Text("Sheet")
                    .accessibilityIdentifier("prs.sheet")
                    .measured("sheet.text")
                Button("Close") {
                    fixtureLog("PRS_ACTION close")
                    isPresented = false
                }
                .accessibilityIdentifier("prs.sheet.close")
                .measured("sheet.close")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                guard !reported else { return }
                reported = true
                fixtureLog("PRS_GEOM sheet size=\(Int(geo.size.width))x\(Int(geo.size.height)) "
                           + "insets=\(insetsText(geo.safeAreaInsets)) frame=\(frameText(geo.frame(in: .global)))")
            }
        }
        .onAppear { fixtureLog("PRS_APPEAR sheet") }
        .onDisappear { fixtureLog("PRS_DISAPPEAR sheet") }
    }
}

struct ContentView: View {
    @State private var path: [Int] = []
    @State private var didMeasure = false

    var body: some View {
        let stack = NavigationStack(path: $path) {
            RootView(path: $path)
                .navigationDestination(for: Int.self) { number in
                    NumberView(number: number, path: $path)
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
