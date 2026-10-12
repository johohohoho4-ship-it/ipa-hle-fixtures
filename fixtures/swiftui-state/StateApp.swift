import SwiftUI
import Darwin

/// One `SWU_` line per event on stdout; in the simulator stdout goes to the console file the workflow keeps.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

@main
struct SwiftUIStateApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWU_STATE_START")
        logLayouts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Native sizes of SwiftUI types. Frozen types are laid out inside the app, so the HLE must match them.
func layoutLine<T>(_ name: String, _ type: T.Type) {
    fixtureLog("SWU_LAYOUT \(name) size=\(MemoryLayout<T>.size) stride=\(MemoryLayout<T>.stride) align=\(MemoryLayout<T>.alignment)")
}

func logLayouts() {
    layoutLine("Text", Text.self)
    layoutLine("LocalizedStringKey", LocalizedStringKey.self)
    layoutLine("Font", Font.self)
    layoutLine("Color", Color.self)
    layoutLine("EdgeInsets", EdgeInsets.self)
    layoutLine("HorizontalAlignment", HorizontalAlignment.self)
    layoutLine("Spacer", Spacer.self)
    layoutLine("EmptyView", EmptyView.self)
    layoutLine("VStack<Text>", VStack<Text>.self)
    layoutLine("HStack<Text>", HStack<Text>.self)
    layoutLine("TupleView<(Text,Text)>", TupleView<(Text, Text)>.self)
    layoutLine("ModifiedContent<Text,_PaddingLayout>", ModifiedContent<Text, _PaddingLayout>.self)
    layoutLine("_ConditionalContent<Text,EmptyView>", _ConditionalContent<Text, EmptyView>.self)
    layoutLine("Optional<Text>", Optional<Text>.self)
    layoutLine("Button<Text>", Button<Text>.self)
    layoutLine("ForEach<Range<Int>,Int,Text>", ForEach<Range<Int>, Int, Text>.self)
    layoutLine("State<Int>", State<Int>.self)
    layoutLine("State<Bool>", State<Bool>.self)
    layoutLine("Binding<Bool>", Binding<Bool>.self)
    layoutLine("StateObject<NameModel>", StateObject<NameModel>.self)
    layoutLine("ObservedObject<NameModel>", ObservedObject<NameModel>.self)
    layoutLine("Environment<ColorScheme>", Environment<ColorScheme>.self)
    layoutLine("Published<String>", Published<String>.self)
    layoutLine("ContentView", ContentView.self)
    layoutLine("DetailToggle", DetailToggle.self)
    layoutLine("NameView", NameView.self)
}

/// Reference type state for `@StateObject` and `@ObservedObject` (Combine `@Published`).
final class NameModel: ObservableObject {
    @Published var name = "Ada"
    @Published var renames = 0
}

struct ContentView: View {
    @State private var count = 0
    @State private var showDetail = false
    @StateObject private var model = NameModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 12) {
            Text("Count: \(count)")
                .font(.title)
                .accessibilityIdentifier("state.count")
            HStack {
                Button("Decrement") {
                    count -= 1
                    fixtureLog("SWU_TAP decrement count=\(count)")
                }
                .accessibilityIdentifier("state.decrement")
                Spacer()
                Button("Increment") {
                    count += 1
                    fixtureLog("SWU_TAP increment count=\(count)")
                }
                .accessibilityIdentifier("state.increment")
            }
            .padding(.horizontal)
            DetailToggle(isOn: $showDetail)
            if showDetail {
                Text("Detail visible")
                    .accessibilityIdentifier("state.detail")
            }
            NameView(model: model)
            ForEach(0..<max(count, 0), id: \.self) { index in
                Text("Row \(index)")
                    .accessibilityIdentifier("state.row.\(index)")
            }
        }
        .padding()
        .onAppear {
            fixtureLog("SWU_STATE_APPEAR count=\(count) scheme=\(colorScheme == .dark ? "dark" : "light")")
        }
        .onChange(of: count) { value in
            fixtureLog("SWU_CHANGE count=\(value)")
        }
    }
}

/// `@Binding` into the parent's `@State`.
struct DetailToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(isOn ? "Hide detail" : "Show detail") {
            isOn.toggle()
            fixtureLog("SWU_TAP detail isOn=\(isOn)")
        }
        .accessibilityIdentifier("state.toggle")
    }
}

/// `@ObservedObject` of the parent's `@StateObject`.
struct NameView: View {
    @ObservedObject var model: NameModel

    var body: some View {
        VStack(spacing: 4) {
            Text("Name: \(model.name)")
                .accessibilityIdentifier("state.name")
            Button("Rename") {
                model.name = model.name == "Ada" ? "Grace" : "Ada"
                model.renames += 1
                fixtureLog("SWU_TAP rename name=\(model.name) renames=\(model.renames)")
            }
            .accessibilityIdentifier("state.rename")
        }
    }
}
