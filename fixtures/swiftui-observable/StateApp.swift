import SwiftUI
import Observation
import Darwin

/// One `SWO_` line per event on stdout; the simulator console file is kept by the workflow.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

@Observable
@MainActor
final class CounterModel {
    var count = 0
    var showDetail = false
    var rows: [String] = []

    func increment() {
        count += 1
        rows.append("Row \(count)")
    }

    func decrement() {
        count -= 1
        if !rows.isEmpty { rows.removeLast() }
    }
}

@main
struct ObservableApp: App {
    @State private var model = CounterModel()

    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWO_START")
        layoutLine("CounterModel", CounterModel.self)
        layoutLine("ContentView", ContentView.self)
        layoutLine("DetailView", DetailView.self)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
        }
    }
}

func layoutLine<T>(_ name: String, _ type: T.Type) {
    fixtureLog("SWO_LAYOUT \(name) size=\(MemoryLayout<T>.size) stride=\(MemoryLayout<T>.stride) align=\(MemoryLayout<T>.alignment)")
}

struct ContentView: View {
    @Environment(CounterModel.self) private var model

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 12) {
            Text("Count: \(model.count)")
                .font(.title)
                .accessibilityIdentifier("obs.count")
            HStack {
                Button("Decrement") {
                    model.decrement()
                    fixtureLog("SWO_TAP decrement count=\(model.count)")
                }
                .accessibilityIdentifier("obs.decrement")
                Spacer()
                Button("Increment") {
                    model.increment()
                    fixtureLog("SWO_TAP increment count=\(model.count)")
                }
                .accessibilityIdentifier("obs.increment")
            }
            .padding(.horizontal)
            Toggle("Detail", isOn: $model.showDetail)
                .accessibilityIdentifier("obs.toggle")
            if model.showDetail {
                DetailView()
            }
            ForEach(model.rows, id: \.self) { row in
                Text(row)
                    .accessibilityIdentifier("obs.row.\(row)")
            }
            Button("Track") {
                observeCount()
                fixtureLog("SWO_TRACK count=\(model.count)")
            }
            .accessibilityIdentifier("obs.track")
            Button("Finish") {
                fixtureLog("SWO_DONE")
            }
            .accessibilityIdentifier("obs.finish")
        }
        .padding()
        .onAppear {
            fixtureLog("SWO_APPEAR count=\(model.count)")
        }
    }

    private func observeCount() {
        withObservationTracking {
            _ = model.count
        } onChange: {
            // The onChange closure is @Sendable; no main-actor state may be read here.
            fixtureLog("SWO_ONCHANGE")
        }
    }
}

struct DetailView: View {
    @Environment(CounterModel.self) private var model

    var body: some View {
        Text("Detail visible for \(model.count)")
            .accessibilityIdentifier("obs.detail")
    }
}
