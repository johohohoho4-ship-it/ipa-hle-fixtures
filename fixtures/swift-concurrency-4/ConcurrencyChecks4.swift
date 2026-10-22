import Foundation

enum Boom4: Error {
    case value
}

actor Counter4 {
    private(set) var value = 0

    func bump() {
        value += 1
    }
}

private func throwingChild4() async throws -> Int {
    throw Boom4.value
}

/// E7 fixture: unsafe continuations, task priority, throwing async let,
/// cancellation of a group child, discarding group, ContinuousClock sleep
/// and an AsyncThrowingStream that finishes with an error.
func concurrencyChecks4() async -> [String] {
    var lines: [String] = []

    let resumed: Int = await withUnsafeContinuation { continuation in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            continuation.resume(returning: 42)
        }
    }
    lines.append("CC4_CONT=\(resumed)")

    var continuationError = "none"
    do {
        let _: Int = try await withUnsafeThrowingContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                continuation.resume(throwing: Boom4.value)
            }
        }
    } catch {
        continuationError = "\(error)"
    }
    lines.append("CC4_THROWCONT=\(continuationError)")

    let highPriority = await Task(priority: .high) { Task.currentPriority }.value
    lines.append("CC4_PRIORITY=\(highPriority >= .high)")

    async let failing: Int = throwingChild4()
    async let sibling: Int = 7
    var asyncLet = "none"
    do {
        _ = try await (failing, sibling)
    } catch {
        asyncLet = "caught"
    }
    lines.append("CC4_ASYNCLET=\(asyncLet)")

    let parent = Task<[Bool], Never> {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                try? await Task.sleep(nanoseconds: 200_000_000)
                return Task.isCancelled
            }
            var values: [Bool] = []
            for await value in group {
                values.append(value)
            }
            return values
        }
    }
    parent.cancel()
    let cancelled = await parent.value
    lines.append("CC4_CANCEL=\(cancelled.first == true)")

    let counter = Counter4()
    await withDiscardingTaskGroup { group in
        for _ in 0..<2 {
            group.addTask { await counter.bump() }
        }
    }
    let counted = await counter.value
    lines.append("CC4_DISCARD=\(counted)")

    try? await Task.sleep(for: .milliseconds(50))
    lines.append("CC4_SLEEP=ok")

    let stream = AsyncThrowingStream<Int, Error> { continuation in
        continuation.yield(1)
        continuation.finish(throwing: Boom4.value)
    }
    var streamValues: [Int] = []
    var streamResult = "none"
    do {
        for try await value in stream {
            streamValues.append(value)
        }
    } catch {
        streamResult = "caught"
    }
    lines.append("CC4_STREAM=\(streamValues.map(String.init).joined(separator: ",")),\(streamResult)")
    lines.append("CC4_DONE")
    return lines
}
