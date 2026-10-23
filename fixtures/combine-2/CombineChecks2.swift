import Combine
import Foundation

/// E8 fixture: Just/Fail/Future, a typed error with both completions, tryMap/catch/replaceError,
/// a subscriber with a limited demand, flatMap(maxPublishers:), merge, zip, scan, prefix/dropFirst
/// and share with two sinks. Each result is one `CMB2_` line; the values are fixed.
enum CMB2Error: Error, CustomStringConvertible {
    case boom

    var description: String {
        switch self {
        case .boom:
            return "boom"
        }
    }
}

/// Subscribes with demand `.max(2)` only; a third value must not arrive.
private final class DemandBox: Subscriber {
    typealias Input = Int
    typealias Failure = Never

    private var subscription: Subscription?
    private(set) var received: [Int] = []

    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(2))
    }

    func receive(_ input: Int) -> Subscribers.Demand {
        received.append(input)
        return .none
    }

    func receive(completion: Subscribers.Completion<Never>) {
        subscription = nil
    }
}

func combineChecks2() -> [String] {
    var lines: [String] = []
    func emit(_ name: String, _ value: String) {
        lines.append("CMB2_\(name)=\(value)")
    }

    // Just delivers its value and finishes.
    var justValues: [Int] = []
    let justCancel = Just(42).sink { value in justValues.append(value) }
    emit("JUST", "\(justValues)")
    justCancel.cancel()

    // A finished completion.
    var finished = "none"
    let finishedCancel = Just(5).sink(receiveCompletion: { completion in
        if case .finished = completion {
            finished = "finished"
        }
    }, receiveValue: { _ in })
    emit("FINISHED", finished)
    finishedCancel.cancel()

    // Fail never emits a value and completes with the app's error case.
    var failCompletion = "none"
    var failValues: [Int] = []
    let failCancel = Fail<Int, CMB2Error>(error: .boom).sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
            failCompletion = "failure:" + error.description
        case .finished:
            failCompletion = "finished"
        }
    }, receiveValue: { value in failValues.append(value) })
    emit("FAIL", "\(failCompletion),\(failValues)")
    failCancel.cancel()

    // Future resolves its promise synchronously when subscribed.
    var futureValues: [Int] = []
    var futureCompletion = "none"
    let futureCancel = Future<Int, Never> { promise in
        promise(.success(7))
    }.sink(receiveCompletion: { completion in
        if case .finished = completion {
            futureCompletion = "finished"
        }
    }, receiveValue: { value in futureValues.append(value) })
    emit("FUTURE", "\(futureValues),\(futureCompletion)")
    futureCancel.cancel()

    // tryMap stops the chain with the thrown error.
    let trySource = PassthroughSubject<Int, Never>()
    var tryValues: [Int] = []
    var tryCompletion = "none"
    let tryCancel = trySource.tryMap { value -> Int in
        if value == 2 {
            throw CMB2Error.boom
        }
        return value
    }.sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
            tryCompletion = "failure:" + ((error as? CMB2Error)?.description ?? "other")
        case .finished:
            tryCompletion = "finished"
        }
    }, receiveValue: { value in tryValues.append(value) })
    trySource.send(1)
    trySource.send(2)
    trySource.send(3)
    emit("TRYMAP", "\(tryValues),\(tryCompletion)")
    tryCancel.cancel()

    // catch replaces the failing publisher with a value publisher of the same failure type.
    let catchSource = PassthroughSubject<Int, CMB2Error>()
    var caughtValues: [Int] = []
    let catchCancel = catchSource.catch { _ in
        Just(99).setFailureType(to: CMB2Error.self)
    }.sink(receiveCompletion: { _ in }, receiveValue: { value in caughtValues.append(value) })
    catchSource.send(1)
    catchSource.send(completion: .failure(.boom))
    emit("CATCH", "\(caughtValues)")
    catchCancel.cancel()

    // replaceError substitutes a value for the failure.
    let replaceSource = PassthroughSubject<Int, CMB2Error>()
    var replacedValues: [Int] = []
    let replaceCancel = replaceSource.replaceError(with: -1).sink { value in replacedValues.append(value) }
    replaceSource.send(1)
    replaceSource.send(completion: .failure(.boom))
    emit("REPLACE", "\(replacedValues)")
    replaceCancel.cancel()

    // A custom subscriber that asks for two values only.
    let demandBox = DemandBox()
    let demandSource = PassthroughSubject<Int, Never>()
    demandSource.subscribe(demandBox)
    demandSource.send(1)
    demandSource.send(2)
    demandSource.send(3)
    emit("DEMAND", "\(demandBox.received)")

    // flatMap(maxPublishers: .max(1)) runs one inner publisher at a time.
    let innerA = PassthroughSubject<Int, Never>()
    let innerB = PassthroughSubject<Int, Never>()
    var flattened: [Int] = []
    let flatCancel = [1, 2].publisher
        .flatMap(maxPublishers: .max(1)) { key -> PassthroughSubject<Int, Never> in
            return key == 1 ? innerA : innerB
        }
        .sink { value in flattened.append(value) }
    innerA.send(10)
    innerA.send(11)
    innerA.send(completion: .finished)
    innerB.send(20)
    innerB.send(completion: .finished)
    emit("FLATMAP", "\(flattened)")
    flatCancel.cancel()

    // merge interleaves in send order.
    let mergeA = PassthroughSubject<Int, Never>()
    let mergeB = PassthroughSubject<Int, Never>()
    var merged: [Int] = []
    let mergeCancel = mergeA.merge(with: mergeB).sink { value in merged.append(value) }
    mergeA.send(1)
    mergeB.send(2)
    mergeA.send(3)
    emit("MERGE", "\(merged)")
    mergeCancel.cancel()

    // zip pairs the oldest unused values.
    let zipA = PassthroughSubject<Int, Never>()
    let zipB = PassthroughSubject<String, Never>()
    var zipped: [String] = []
    let zipCancel = zipA.zip(zipB).sink { pair in zipped.append("\(pair.0)-\(pair.1)") }
    zipA.send(1)
    zipB.send("a")
    zipA.send(2)
    zipA.send(3)
    zipB.send("b")
    emit("ZIP", "\(zipped)")
    zipCancel.cancel()

    // scan accumulates from zero.
    let scanSource = PassthroughSubject<Int, Never>()
    var scanned: [Int] = []
    let scanCancel = scanSource.scan(0) { $0 + $1 }.sink { value in scanned.append(value) }
    for number in [1, 2, 3] {
        scanSource.send(number)
    }
    emit("SCAN", "\(scanned)")
    scanCancel.cancel()

    // dropFirst(2) then prefix(2) keeps the third and fourth value.
    let counted = PassthroughSubject<Int, Never>()
    var sliced: [Int] = []
    let sliceCancel = counted.dropFirst(2).prefix(2).sink { value in sliced.append(value) }
    for number in 1...6 {
        counted.send(number)
    }
    emit("SLICE", "\(sliced)")
    sliceCancel.cancel()

    // share feeds two independent sinks from one upstream subscription.
    let sharedSource = PassthroughSubject<Int, Never>()
    let shared = sharedSource.share()
    var first: [Int] = []
    var second: [Int] = []
    let firstCancel = shared.sink { value in first.append(value) }
    let secondCancel = shared.sink { value in second.append(value) }
    sharedSource.send(5)
    emit("SHARE", "\(first)|\(second)")
    firstCancel.cancel()
    secondCancel.cancel()

    return lines
}
