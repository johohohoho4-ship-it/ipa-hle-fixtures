import Foundation

final class SerialQueueExecutor: SerialExecutor, @unchecked Sendable {
    private let queue = DispatchQueue(label: "org.ipahle.fixture.cc3.serial")

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        queue.async {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

actor ExecutorActor {
    nonisolated let executor = SerialQueueExecutor()
    nonisolated var unownedExecutor: UnownedSerialExecutor { executor.asUnownedSerialExecutor() }

    private var count = 0

    func bump() -> Int {
        count += 1
        return count
    }
}

enum Trace {
    @TaskLocal static var origin = "root"
}

enum Boom: Error {
    case value
}

final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false

    func set() {
        lock.lock()
        value = true
        lock.unlock()
    }

    func read() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

/// E7 fixture: custom actor executor, TaskLocal inheritance, throwing task and
/// group, sibling cancellation and `withTaskCancellationHandler`.
func concurrencyChecks3() async -> [String] {
    var lines: [String] = []

    let counterActor = ExecutorActor()
    let bumped = await counterActor.bump()
    lines.append("CC3_EXECUTOR=\(bumped)")

    let inherited = await Trace.$origin.withValue("parent") {
        let direct = await Task { Trace.origin }.value
        let group = await withTaskGroup(of: String.self) { group -> String in
            group.addTask { Trace.origin }
            var values: [String] = []
            for await value in group { values.append(value) }
            return values.joined(separator: ",")
        }
        let detached = await Task.detached { Trace.origin }.value
        return "\(direct)|\(group)|\(detached)"
    }
    lines.append("CC3_LOCAL=\(inherited)")

    let throwing = Task<Int, Error> { throw Boom.value }
    var thrown = "no"
    do {
        _ = try await throwing.value
    } catch {
        thrown = "caught"
    }
    lines.append("CC3_THROW=\(thrown)")

    let cancelledSibling = Flag()
    var groupResult = "no"
    do {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await Task.sleep(nanoseconds: 100_000_000)
                return "first"
            }
            group.addTask {
                throw Boom.value
            }
            group.addTask {
                do {
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    return "late"
                } catch {
                    cancelledSibling.set()
                    return "cancelled"
                }
            }
            for try await _ in group {
                // The throwing child decides the result; values are not asserted.
            }
        }
    } catch {
        groupResult = "caught,\(cancelledSibling.read())"
    }
    lines.append("CC3_GROUP=\(groupResult)")

    let handlerRan = Flag()
    let cancelled = Task<String, Never> {
        await withTaskCancellationHandler {
            do {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return "finished"
            } catch {
                return "cancelled"
            }
        } onCancel: {
            handlerRan.set()
        }
    }
    cancelled.cancel()
    let ended = await cancelled.value
    lines.append("CC3_CANCEL=\(ended),\(handlerRan.read())")

    return lines
}
