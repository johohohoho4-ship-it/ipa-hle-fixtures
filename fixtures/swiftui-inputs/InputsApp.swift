import SwiftUI
import UIKit
import Darwin

/// One `SWI5_` line per measured view or state change; the simulator console file keeps stdout.
func fixtureLog(_ line: String) {
    let text = line + "\n"
    _ = text.withCString { write(1, $0, strlen($0)) }
}

/// Collects the global frames of all measured views and prints them sorted once
/// the first layout pass is over, so the order does not depend on appearance order.
/// The initial state lines follow the frames, `SWI5_DONE` closes the start run.
final class FrameLog: ObservableObject {
    static let shared = FrameLog()
    @Published private(set) var done = false

    private var frames: [String: String] = [:]
    private var startLines: [String] = []
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

    /// State of the controls at the start of the run, printed after the frames.
    func setStartLines(_ lines: [String]) {
        lock.lock()
        startLines = lines
        lock.unlock()
    }

    private func flush() {
        lock.lock()
        let snapshot = frames
        let lines = startLines
        lock.unlock()
        for name in snapshot.keys.sorted() {
            fixtureLog("SWI5_\(name)=\(snapshot[name]!)")
        }
        for line in lines {
            fixtureLog(line)
        }
        fixtureLog("SWI5_DONE")
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
struct SwiftUIInputsFixtureApp: App {
    init() {
#if targetEnvironment(simulator)
        let log = NSTemporaryDirectory() + "ipa-hle-console.log"
        log.withCString { _ = freopen($0, "w", stdout) }
        setvbuf(stdout, nil, _IONBF, 0)
#endif
        fixtureLog("SWI5_START")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @ObservedObject private var log = FrameLog.shared
    @State private var flag = false
    @State private var name = ""
    @State private var sliderValue: Double = 0
    @State private var stepperValue = 0
    @State private var pickerIndex = 0
    @State private var date = ContentView.fixedDate
    @State private var secret = ""
    /// Last interaction that finished, shown in `inp.status` for the UI test.
    @State private var phase = "ready"
    @FocusState private var nameFocused: Bool

    /// Fixed start date so the printed value does not depend on the wall clock.
    static let fixedDate = Calendar(identifier: .gregorian)
        .date(from: DateComponents(year: 2020, month: 5, day: 17))
        ?? Date(timeIntervalSince1970: 0)

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var statusText: String {
        log.done ? phase : "running"
    }

    private func stateLine(_ control: String, _ value: String) -> String {
        "SWI5_STATE name=\(control) value=\(value)"
    }

    private var sliderInt: Int { Int(sliderValue.rounded()) }

    private var startLines: [String] {
        [
            stateLine("toggle", flag ? "1" : "0"),
            stateLine("text", name),
            stateLine("slider", "\(sliderInt)"),
            stateLine("stepper", "\(stepperValue)"),
            stateLine("picker", "\(pickerIndex)"),
            stateLine("date", Self.dateFormatter.string(from: date)),
            stateLine("secure", "\(secret.count)")
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(header: Text("Eingaben")) {
                    Toggle(isOn: $flag) {
                        HStack {
                            Text("Toggle")
                            Spacer()
                            Text(flag ? "1" : "0")
                                .accessibilityIdentifier("inp.toggle.value")
                                .measured("toggle.value")
                        }
                    }
                    .accessibilityIdentifier("inp.toggle")
                    .measured("toggle")
                    .onChange(of: flag) { value in
                        fixtureLog(stateLine("toggle", value ? "1" : "0"))
                        phase = "toggled"
                    }

                    HStack {
                        TextField("Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                            .focused($nameFocused)
                            .onSubmit { nameFocused = false }
                            .accessibilityIdentifier("inp.text")
                            .measured("text")
                            .onChange(of: name) { value in
                                fixtureLog(stateLine("text", value))
                                phase = "typed:\(value)"
                            }
                        Text(name.isEmpty ? "-" : name)
                            .accessibilityIdentifier("inp.text.value")
                            .measured("text.value")
                    }

                    HStack {
                        Slider(value: $sliderValue, in: 0...100, step: 1)
                            .accessibilityIdentifier("inp.slider")
                            .measured("slider")
                            .onChange(of: sliderValue) { value in
                                let rounded = Int(value.rounded())
                                fixtureLog(stateLine("slider", "\(rounded)"))
                                phase = "slider:\(rounded)"
                            }
                        Text("\(sliderInt)")
                            .frame(width: 36, alignment: .trailing)
                            .accessibilityIdentifier("inp.slider.value")
                            .measured("slider.value")
                    }

                    Stepper(value: $stepperValue, in: 0...10) {
                        HStack {
                            Text("Stepper")
                            Spacer()
                            Text("\(stepperValue)")
                                .accessibilityIdentifier("inp.stepper.value")
                                .measured("stepper.value")
                        }
                    }
                    .accessibilityIdentifier("inp.stepper")
                    .measured("stepper")
                    .onChange(of: stepperValue) { value in
                        fixtureLog(stateLine("stepper", "\(value)"))
                        phase = "stepper:\(value)"
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Picker("Auswahl", selection: $pickerIndex) {
                            Text("Eins").tag(0)
                            Text("Zwei").tag(1)
                            Text("Drei").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("inp.picker")
                        .measured("picker")
                        .onChange(of: pickerIndex) { value in
                            fixtureLog(stateLine("picker", "\(value)"))
                            phase = "picked:\(value)"
                        }
                        Text("Index \(pickerIndex)")
                            .font(.caption)
                            .accessibilityIdentifier("inp.picker.value")
                            .measured("picker.value")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker("Datum", selection: $date, displayedComponents: .date)
                            .accessibilityIdentifier("inp.date")
                            .measured("date")
                            .onChange(of: date) { _ in
                                let text = Self.dateFormatter.string(from: date)
                                fixtureLog(stateLine("date", text))
                                phase = "date:\(text)"
                            }
                        Text(Self.dateFormatter.string(from: date))
                            .font(.caption)
                            .accessibilityIdentifier("inp.date.value")
                            .measured("date.value")
                    }

                    HStack {
                        SecureField("Passwort", text: $secret)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("inp.secure")
                            .measured("secure")
                            .onChange(of: secret) { value in
                                fixtureLog(stateLine("secure", "\(value.count)"))
                                phase = "secure:\(value.count)"
                            }
                        Text("\(secret.count)")
                            .frame(width: 36, alignment: .trailing)
                            .accessibilityIdentifier("inp.secure.value")
                            .measured("secure.value")
                    }
                }
            }
            .measured("form")

            HStack {
                Text(statusText)
                    .accessibilityIdentifier("inp.status")
                Spacer()
                Text("SWI5")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .measured("root")
        .onAppear {
            log.setStartLines(startLines)
        }
    }
}
