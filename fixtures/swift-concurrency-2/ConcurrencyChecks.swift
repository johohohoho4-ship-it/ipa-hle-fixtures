import Foundation

enum Concurrency2Local {
    @TaskLocal static var request = "none"
}

func concurrencyChecks() async -> Bool {
    print("CONC2_START")

    let local = await Concurrency2Local.$request.withValue("abc") {
        Concurrency2Local.request
    }
    print("CONC2_LOCAL value=\(local)")

    let cancelTask = Task { () -> Bool in
        while !Task.isCancelled {
            await Task.yield()
        }
        return Task.isCancelled
    }
    cancelTask.cancel()
    let cancelled = await cancelTask.value
    print("CONC2_CANCEL cancelled=\(cancelled)")

    let checkTask = Task { () -> Bool in
        do {
            try Task.checkCancellation()
            return false
        } catch {
            return true
        }
    }
    checkTask.cancel()
    let checked = await checkTask.value
    print("CONC2_CHECK thrown=\(checked)")

    let sleepTask = Task { () -> Bool in
        do {
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return false
        } catch {
            return true
        }
    }
    sleepTask.cancel()
    let slept = await sleepTask.value
    print("CONC2_SLEEP cancelled=\(slept)")

    let value = await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.01) {
            continuation.resume(returning: 42)
        }
    }
    print("CONC2_CONT value=\(value)")

    var threw = false
    do {
        let _: Int = try await withCheckedThrowingContinuation { continuation in
            continuation.resume(throwing: NSError(domain: "CONC2", code: 7))
        }
    } catch {
        threw = true
    }
    print("CONC2_THROW threw=\(threw)")

    let stream = AsyncStream<Int> { continuation in
        continuation.yield(1)
        continuation.yield(2)
        continuation.finish()
    }
    var sum = 0
    for await number in stream {
        sum += number
    }
    print("CONC2_STREAM sum=\(sum)")

    let nested = await Concurrency2Local.$request.withValue("outer") {
        await Concurrency2Local.$request.withValue("inner") {
            Concurrency2Local.request
        }
    }
    print("CONC2_NESTED value=\(nested)")

    let ok = local == "abc" && cancelled && checked && slept && value == 42 && threw
        && sum == 3 && nested == "inner"
    print(ok ? "CONC2_OK" : "CONC2_BAD")
    print("CONC2_DONE")
    return ok
}
