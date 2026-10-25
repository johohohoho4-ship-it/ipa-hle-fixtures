import Combine
import Foundation

enum MyError: Error, Equatable {
    case boom
}

private final class TimerSubscriptions {
    var first: AnyCancellable?
    var second: AnyCancellable?
}

/// E8 fixture for the remaining Combine operators: merge/combineLatest/zip with a
/// failing input behind replaceError, an autoconnect timer that is cancelled and
/// re-subscribed, throttle with an immediate completion, and a connectable timer.
/// Each case is one `CMB4_` line; the values are observations, not enforced
/// expectations.
func combineChecks4() -> [String] {
    var lines: [String] = []
    func emit(_ name: String, _ value: String) {
        lines.append("CMB4_\(name)=\(value)")
    }
    func pump(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    // (1) merge of two failing subjects behind replaceError(99): does the value
    // from the other input still arrive after the failure, and when is finished?
    let mergeLeft = PassthroughSubject<Int, MyError>()
    let mergeRight = PassthroughSubject<Int, MyError>()
    var mergeValues: [Int] = []
    var mergeCompletion = "none"
    let merge = mergeLeft.merge(with: mergeRight)
        .replaceError(with: 99)
        .sink(receiveCompletion: { completion in
            if case .finished = completion { mergeCompletion = "finished" }
        }, receiveValue: { mergeValues.append($0) })
    mergeLeft.send(1)
    mergeRight.send(2)
    mergeLeft.send(completion: .failure(.boom))
    mergeRight.send(9)
    pump(0.05)
    emit("MERGE", "values=\(mergeValues),completion=\(mergeCompletion)")
    merge.cancel()

    // (2) combineLatest with the same failure; the tuple becomes a string so that
    // replaceError can emit the literal 99.
    let latestLeft = PassthroughSubject<Int, MyError>()
    let latestRight = PassthroughSubject<Int, MyError>()
    var latestValues: [String] = []
    var latestCompletion = "none"
    let latest = latestLeft.combineLatest(latestRight)
        .map { "\($0.0)/\($0.1)" }
        .replaceError(with: "99")
        .sink(receiveCompletion: { completion in
            if case .finished = completion { latestCompletion = "finished" }
        }, receiveValue: { latestValues.append($0) })
    latestRight.send(1)
    latestLeft.send(2)
    latestLeft.send(completion: .failure(.boom))
    latestRight.send(9)
    pump(0.05)
    emit("COMBINELATEST", "values=\(latestValues),completion=\(latestCompletion)")
    latest.cancel()

    // (3) zip with the same failure.
    let zipLeft = PassthroughSubject<Int, MyError>()
    let zipRight = PassthroughSubject<Int, MyError>()
    var zipValues: [String] = []
    var zipCompletion = "none"
    let zip = zipLeft.zip(zipRight)
        .map { "\($0.0)/\($0.1)" }
        .replaceError(with: "99")
        .sink(receiveCompletion: { completion in
            if case .finished = completion { zipCompletion = "finished" }
        }, receiveValue: { zipValues.append($0) })
    zipLeft.send(2)
    zipRight.send(1)
    zipLeft.send(completion: .failure(.boom))
    zipRight.send(9)
    pump(0.05)
    emit("ZIP", "values=\(zipValues),completion=\(zipCompletion)")
    zip.cancel()

    // (4) autoconnect timer: the first sink cancels after its first value and a
    // second sink subscribes immediately on the same publisher variable.
    let autoconnect = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    var firstTimerValues = 0
    var secondTimerValues = 0
    let timers = TimerSubscriptions()
    timers.first = autoconnect.sink { _ in
        firstTimerValues += 1
        if firstTimerValues == 1 {
            timers.first?.cancel()
            timers.second = autoconnect.sink { _ in secondTimerValues += 1 }
        }
    }
    pump(0.3)
    emit("AUTOCONNECT", "first=\(firstTimerValues),second=\(secondTimerValues)")
    timers.first?.cancel()
    timers.second?.cancel()

    // (5) throttle with a value and an immediate completion, latest true/false.
    func throttleCheck(latest: Bool) -> String {
        let source = PassthroughSubject<Int, Never>()
        var values: [Int] = []
        var finished = false
        let cancellable = source
            .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: latest)
            .sink(receiveCompletion: { completion in
                if case .finished = completion { finished = true }
            }, receiveValue: { values.append($0) })
        source.send(1)
        source.send(completion: .finished)
        pump(0.3)
        cancellable.cancel()
        return "values=\(values),finished=\(finished)"
    }
    emit("THROTTLE_TRUE", throttleCheck(latest: true))
    emit("THROTTLE_FALSE", throttleCheck(latest: false))

    // (6) connectable timer without autoconnect: subscribe, connect, then cancel
    // the subscription while the connection stays active.
    let connectable = Timer.publish(every: 0.05, on: .main, in: .common)
    var connectedValues = 0
    let connection = connectable.sink { _ in connectedValues += 1 }
    let connector = connectable.connect()
    pump(0.2)
    let afterConnect = connectedValues
    connection.cancel()
    pump(0.2)
    emit("CONNECT", "afterConnect=\(afterConnect),afterCancel=\(connectedValues)")
    connector.cancel()

    return lines
}
