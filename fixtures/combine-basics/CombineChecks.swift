import Combine
import Foundation

private final class AssignBox {
    var value = 0
}

private final class PublishedModel {
    @Published var count = 0
}

/// E8 fixture: the Combine basics Opus listed, each result as one CMB_ line.
/// Order and values are fixed; only the debounce and the main-queue hop need
/// a short run-loop turn, and their asserted results do not depend on the host.
func combineChecks() -> [String] {
    var lines: [String] = []
    func emit(_ name: String, _ value: String) {
        lines.append("CMB_\(name)=\(value)")
    }

    // PassthroughSubject and cancellation through AnyCancellable.
    let pass = PassthroughSubject<Int, Never>()
    var passValues: [Int] = []
    let passCancel = pass.sink { passValues.append($0) }
    pass.send(1)
    pass.send(2)
    emit("PASS", "\(passValues)")
    passCancel.cancel()
    pass.send(3)
    emit("CANCEL", "\(passValues)")

    // CurrentValueSubject delivers its current value on subscription.
    let current = CurrentValueSubject<String, Never>("idle")
    var currentValues: [String] = []
    let currentCancel = current.sink { currentValues.append($0) }
    current.send("run")
    emit("CURRENT", "\(currentValues)")
    currentCancel.cancel()

    // map, filter and removeDuplicates in one chain.
    let numbers = PassthroughSubject<Int, Never>()
    var transformed: [Int] = []
    let transformCancel = numbers.map { $0 * 2 }.filter { $0 >= 6 }.removeDuplicates().sink {
        transformed.append($0)
    }
    for number in [1, 2, 3, 3, 4, 4] {
        numbers.send(number)
    }
    emit("MAPFILTER", "\(transformed)")
    transformCancel.cancel()

    // combineLatest pairs the latest values.
    let left = CurrentValueSubject<Int, Never>(1)
    let right = CurrentValueSubject<String, Never>("a")
    var pairs: [String] = []
    let latestCancel = left.combineLatest(right).sink { pair in
        pairs.append("\(pair.0)-\(pair.1)")
    }
    left.send(2)
    right.send("b")
    emit("LATEST", "\(pairs)")
    latestCancel.cancel()

    // assign(to:on:) writes into a plain object.
    let box = AssignBox()
    let assigned = PassthroughSubject<Int, Never>()
    let assignment = assigned.assign(to: \.value, on: box)
    assigned.send(7)
    assigned.send(9)
    emit("ASSIGN", "\(box.value)")
    assignment.cancel()

    // @Published with the projected value's sink.
    let model = PublishedModel()
    var counts: [Int] = []
    let modelCancel = model.$count.sink { counts.append($0) }
    model.count = 1
    model.count = 2
    emit("PUBLISHED", "\(counts)")
    modelCancel.cancel()

    // receive(on:) hands delivery to the main queue, so the first read is empty.
    let hop = PassthroughSubject<Int, Never>()
    var hopped: [Int] = []
    let hopCancel = hop.receive(on: DispatchQueue.main).sink { hopped.append($0) }
    hop.send(1)
    hop.send(2)
    emit("MAINSYNC", "\(hopped)")
    RunLoop.current.run(until: Date().addingTimeInterval(0.3))
    emit("MAIN", "\(hopped)")
    hopCancel.cancel()

    // debounce on RunLoop.main keeps only the last value of a quiet window.
    let debouncedSource = PassthroughSubject<Int, Never>()
    var debounced: [Int] = []
    let debounceCancel = debouncedSource
        .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
        .sink { debounced.append($0) }
    debouncedSource.send(1)
    RunLoop.current.run(until: Date().addingTimeInterval(0.4))
    debouncedSource.send(2)
    debouncedSource.send(3)
    RunLoop.current.run(until: Date().addingTimeInterval(0.4))
    emit("DEBOUNCE", "\(debounced)")
    debounceCancel.cancel()

    return lines
}
