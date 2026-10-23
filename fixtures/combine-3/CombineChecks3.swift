import Combine
import Foundation

/// E8 fixture: Timer.publish/prefix, receive(on:), debounce completion, delay,
/// throttle latest true/false, NotificationCenter publisher, CombineLatest3,
/// removeDuplicates(by:) and collect(). Each result is one `CMB3_` line; the
/// values are observations, not enforced expectations.
func combineChecks3() -> [String] {
    var lines: [String] = []
    func emit(_ name: String, _ value: String) {
        lines.append("CMB3_\(name)=\(value)")
    }
    func pump(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    // Timer.publish(every:on:in:).autoconnect().prefix(3): count and finished.
    var timerValues: [Date] = []
    var timerFinished = false
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect().prefix(3)
        .sink(receiveCompletion: { completion in
            if case .finished = completion { timerFinished = true }
        }, receiveValue: { date in timerValues.append(date) })
    pump(0.5)
    emit("TIMER", "\(timerValues.count),\(timerFinished)")
    timer.cancel()

    // receive(on: DispatchQueue.main): value and completion, in order.
    let receiveSource = PassthroughSubject<Int, Never>()
    var receiveOrder: [String] = []
    let receive = receiveSource.receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in receiveOrder.append("finished") },
              receiveValue: { receiveOrder.append("\($0)") })
    receiveSource.send(1)
    receiveSource.send(completion: .finished)
    pump(0.2)
    emit("RECEIVE", receiveOrder.joined(separator: ","))
    receive.cancel()

    // debounce: send a value and complete immediately afterwards.
    let debounceSource = PassthroughSubject<Int, Never>()
    var debounceValues: [Int] = []
    var debounceFinished = false
    let debounce = debounceSource.debounce(for: .milliseconds(50), scheduler: RunLoop.main)
        .sink(receiveCompletion: { completion in
            if case .finished = completion { debounceFinished = true }
        }, receiveValue: { debounceValues.append($0) })
    debounceSource.send(7)
    debounceSource.send(completion: .finished)
    pump(0.3)
    emit("DEBOUNCE", "\(debounceValues),\(debounceFinished)")
    debounce.cancel()

    // delay(for:scheduler:).
    var delayed: [Int] = []
    let delay = Just(8).delay(for: .milliseconds(50), scheduler: RunLoop.main)
        .sink { delayed.append($0) }
    pump(0.3)
    emit("DELAY", "\(delayed)")
    delay.cancel()

    // throttle(latest: true) and throttle(latest: false).
    let throttleTrueSource = PassthroughSubject<Int, Never>()
    var throttleTrue: [Int] = []
    let throttleTrueCancel = throttleTrueSource
        .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: true)
        .sink { throttleTrue.append($0) }
    throttleTrueSource.send(1)
    throttleTrueSource.send(2)
    pump(0.2)
    throttleTrueSource.send(3)
    pump(0.2)
    emit("THROTTLE_TRUE", "\(throttleTrue)")
    throttleTrueCancel.cancel()

    let throttleFalseSource = PassthroughSubject<Int, Never>()
    var throttleFalse: [Int] = []
    let throttleFalseCancel = throttleFalseSource
        .throttle(for: .milliseconds(100), scheduler: RunLoop.main, latest: false)
        .sink { throttleFalse.append($0) }
    throttleFalseSource.send(1)
    throttleFalseSource.send(2)
    pump(0.2)
    throttleFalseSource.send(3)
    pump(0.2)
    emit("THROTTLE_FALSE", "\(throttleFalse)")
    throttleFalseCancel.cancel()

    // NotificationCenter publisher with a posted object.
    let notificationName = Notification.Name("CMB3Note")
    var notifications: [Int] = []
    let notification = NotificationCenter.default.publisher(for: notificationName)
        .sink { note in notifications.append(note.object as? Int ?? -1) }
    NotificationCenter.default.post(name: notificationName, object: 3)
    pump(0.1)
    emit("NOTIFICATION", "\(notifications)")
    notification.cancel()

    // CombineLatest3 after each upstream has a value.
    let a = CurrentValueSubject<Int, Never>(1)
    let b = CurrentValueSubject<String, Never>("x")
    let c = CurrentValueSubject<Bool, Never>(true)
    var latest: [String] = []
    let combine = a.combineLatest(b, c).sink { value in
        latest.append("\(value.0)-\(value.1)-\(value.2)")
    }
    b.send("y")
    c.send(false)
    a.send(2)
    emit("COMBINE3", latest.joined(separator: ","))
    combine.cancel()

    // removeDuplicates(by:) removes equal parity, not equal values.
    let duplicateSource = PassthroughSubject<Int, Never>()
    var deduplicated: [Int] = []
    let dedupe = duplicateSource.removeDuplicates(by: { $0 % 2 == $1 % 2 })
        .sink { deduplicated.append($0) }
    [1, 3, 4, 6, 7].forEach { duplicateSource.send($0) }
    emit("REMOVEDUP", "\(deduplicated)")
    dedupe.cancel()

    // collect() buffers the whole sequence.
    var collected: [[Int]] = []
    let collect = [1, 2, 3].publisher.collect().sink { collected.append($0) }
    emit("COLLECT", "\(collected)")
    collect.cancel()

    return lines
}
