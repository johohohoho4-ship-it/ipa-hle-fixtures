import Foundation

// Built with -Onone (see the project), so generic code stays generic and needs the
// Swift runtime's generic metadata: swift_getGenericMetadata, value witness tables of
// Box<T>/Pair<A, B>/Optional<T>/Array<T>, and type lookup by mangled name.

struct Box<T> {
    var value: T
    var count: Int
}

struct Pair<A, B> {
    let first: A
    let second: B
}

struct Point: Equatable {
    var x: Int
    var y: Int
}

indirect enum Tree<T> {
    case leaf(T)
    case node(Tree<T>, Tree<T>)
}

final class Stack<Element> {
    private var items: [Element] = []

    func push(_ item: Element) {
        items.append(item)
    }

    func pop() -> Element? {
        items.popLast()
    }

    var count: Int { items.count }
}

protocol Shape {
    func area() -> Int
}

struct Square: Shape {
    let side: Int
    func area() -> Int { side * side }
}

struct Rect: Shape {
    let width: Int
    let height: Int
    func area() -> Int { width * height }
}

@inline(never)
func sumLeaves(_ tree: Tree<Int>) -> Int {
    switch tree {
    case .leaf(let value):
        return value
    case .node(let left, let right):
        return sumLeaves(left) + sumLeaves(right)
    }
}

@inline(never)
func boxed<T>(_ value: T, count: Int) -> Box<T> {
    Box(value: value, count: count)
}

@inline(never)
func typeName<T>(_ value: T) -> String {
    String(describing: type(of: value))
}

@inline(never)
func firstOrNil<T>(_ values: [T]) -> T? {
    values.first
}

/// Runs every check; each result is one line "name=value" so the HLE run and the
/// simulator reference can be compared line by line.
func runGenericsChecks() -> [(String, Bool, String)] {
    var results: [(String, Bool, String)] = []

    func check(_ name: String, _ ok: Bool, _ detail: String) {
        results.append((name, ok, detail))
    }

    let intBox = boxed(42, count: 1)
    let stringBox = boxed("Hallo", count: 2)
    check("box_int", intBox.value == 42 && intBox.count == 1, "\(intBox.value),\(intBox.count)")
    check("box_string", stringBox.value == "Hallo" && stringBox.count == 2, "\(stringBox.value),\(stringBox.count)")
    check("box_string_size", MemoryLayout<Box<String>>.size == 24, "\(MemoryLayout<Box<String>>.size)")
    check("box_int_size", MemoryLayout<Box<Int>>.size == 16, "\(MemoryLayout<Box<Int>>.size)")

    let maybeBox: Box<Int>? = firstOrNil([intBox])
    let noBox: Box<Int>? = firstOrNil([Box<Int>]())
    check("optional_box", maybeBox?.value == 42 && noBox == nil, "\(maybeBox?.value ?? -1),\(noBox == nil)")
    check("optional_int_size", MemoryLayout<Int?>.size == 9, "\(MemoryLayout<Int?>.size)")
    check("optional_string_size", MemoryLayout<String?>.size == 16, "\(MemoryLayout<String?>.size)")

    let points = [Point(x: 1, y: 2), Point(x: 3, y: 4), Point(x: 5, y: 6)]
    let sumX = points.reduce(0) { $0 + $1.x }
    let sumY = points.map { $0.y }.reduce(0, +)
    check("array_of_structs", sumX == 9 && sumY == 12 && points.contains(Point(x: 3, y: 4)), "\(sumX),\(sumY)")

    let pair = Pair(first: 7, second: Optional("sieben"))
    let emptyPair = Pair<Int, String?>(first: 0, second: nil)
    check("pair_optional", pair.second == "sieben" && emptyPair.second == nil, "\(pair.first),\(pair.second ?? "nil")")

    let stack = Stack<String>()
    stack.push("a")
    stack.push("b")
    stack.push("c")
    let popped = stack.pop()
    check("generic_class", popped == "c" && stack.count == 2, "\(popped ?? "nil"),\(stack.count)")

    let tree: Tree<Int> = .node(.leaf(1), .node(.leaf(2), .leaf(3)))
    check("indirect_enum", sumLeaves(tree) == 6, "\(sumLeaves(tree))")

    var table: [String: [Int]] = [:]
    table["gerade", default: []].append(2)
    table["gerade", default: []].append(4)
    table["ungerade", default: []].append(1)
    check("dictionary_of_arrays", table["gerade"] == [2, 4] && table["ungerade"] == [1], "\(table.count)")

    let shapes: [any Shape] = [Square(side: 3), Rect(width: 2, height: 5)]
    let area = shapes.reduce(0) { $0 + $1.area() }
    check("existentials", area == 19, "\(area)")

    let name = typeName(intBox)
    let pairName = typeName(pair)
    check("type_names", name == "Box<Int>" && pairName == "Pair<Int, Optional<String>>", "\(name);\(pairName)")

    let tuple = (count: 3, label: "drei")
    let tupleBox = boxed(tuple, count: 1)
    check("tuple_payload", tupleBox.value.count == 3 && tupleBox.value.label == "drei", "\(tupleBox.value.label)")

    return results
}
