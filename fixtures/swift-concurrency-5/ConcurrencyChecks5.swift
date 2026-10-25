import Foundation

final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

func concurrencyChecks5() async -> [String] {
    var lines: [String] = []
    lines.append("CC5_START")

    var taskBefore = false, taskAfter = false
    await withTaskGroup(of: Void.self) { group in
        taskBefore = group.isCancelled
        group.cancelAll()
        taskAfter = group.isCancelled
    }
    lines.append("CC5_TASKGROUP=before=\(taskBefore),after=\(taskAfter)")

    var throwingBefore = false, throwingAfter = false
    try? await withThrowingTaskGroup(of: Void.self) { group in
        throwingBefore = group.isCancelled
        group.cancelAll()
        throwingAfter = group.isCancelled
    }
    lines.append("CC5_THROWING=before=\(throwingBefore),after=\(throwingAfter)")

    var discardingBefore = false, discardingAfter = false
    await withDiscardingTaskGroup { group in
        discardingBefore = group.isCancelled
        group.cancelAll()
        discardingAfter = group.isCancelled
    }
    lines.append("CC5_DISCARDING=before=\(discardingBefore),after=\(discardingAfter)")

    var throwingDiscardingBefore = false, throwingDiscardingAfter = false
    try? await withThrowingDiscardingTaskGroup { group in
        throwingDiscardingBefore = group.isCancelled
        group.cancelAll()
        throwingDiscardingAfter = group.isCancelled
    }
    lines.append("CC5_THROWING_DISCARDING=before=\(throwingDiscardingBefore),after=\(throwingDiscardingAfter)")

    let cancelled = Task { () -> String in
        while !Task.isCancelled {
            await Task.yield()
        }
        var before = false, after = false
        await withTaskGroup(of: Void.self) { group in
            before = group.isCancelled
            group.cancelAll()
            after = group.isCancelled
        }
        return "before=\(before),after=\(after)"
    }
    cancelled.cancel()
    let cancelledResult = await cancelled.value
    lines.append("CC5_CANCELLED_TASK=\(cancelledResult)")

    let beforeCounter = Counter()
    let afterCounter = Counter()
    var beforeAdd = false, afterAdd = false
    await withTaskGroup(of: Void.self) { group in
        beforeAdd = group.addTaskUnlessCancelled { beforeCounter.increment() }
        group.cancelAll()
        afterAdd = group.addTaskUnlessCancelled { afterCounter.increment() }
    }
    lines.append("CC5_ADD=before=\(beforeAdd),after=\(afterAdd),ranBefore=\(beforeCounter.count),ranAfter=\(afterCounter.count)")
    return lines
}
