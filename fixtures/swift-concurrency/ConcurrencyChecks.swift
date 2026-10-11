import Foundation

actor Counter {
    var value = 0
    func add(_ increment: Int) -> Int { value += increment; return value }
}

func concurrencyChecks() async -> Bool {
    let counter = Counter()
    let detached = Task.detached { await counter.add(4) }
    let first = await detached.value
    print("CN detached=\(first)")
    async let next = counter.add(3)
    let second = await next
    print("CN asynclet=\(second)")
    let third = await withTaskGroup(of: Int.self) { group in
        group.addTask { _ = await counter.add(5); return 5 }
        group.addTask { _ = await counter.add(6); return 6 }
        var result = 0
        for await value in group { result += value }
        return result
    }
    let count = await counter.add(0)
    print("CN group=\(third) count=\(count)")
    await withTaskGroup(of: Int.self) { group in
        group.addTask { await counter.add(1) }
    }
    let joined = await counter.add(0)
    print("CN join=\(joined)")
    let textTask = Task.detached { "detached result from actor \(await counter.add(0))" }
    let text = await textTask.value
    print("CN string=\(text)")
    let main = await MainActor.run { Thread.isMainThread }
    print("CN main=\(main ? 1 : 0)")
    return first == 4 && second == 7 && third == 11 && count == 18 && joined == 19
        && text == "detached result from actor 19" && main
}
