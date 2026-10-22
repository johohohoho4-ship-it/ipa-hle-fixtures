import Foundation
import UIKit

protocol Describable {
    var label: String { get }
}

protocol Countable {
    var count: Int { get }
}

protocol Container {
    associatedtype Element
    var first: Element? { get }
    var summary: String { get }
}

struct Tag: Describable {
    let label: String
}

struct Item: Describable, Countable {
    let label: String
    let count: Int
}

// Conditional conformance: only arrays of describable elements are describable.
extension Array: Describable where Element: Describable {
    var label: String { "list(" + map { $0.label }.joined(separator: ",") + ")" }
}

struct StringBox: Container {
    let first: String?
    var summary: String { first ?? "none" }
}

final class Holder<Element>: Container {
    let first: Element?
    init(_ value: Element?) {
        first = value
    }
    var summary: String { first.map { "\($0)" } ?? "none" }
}

class BaseClass {
    let name = "base"
}

final class DerivedClass: BaseClass {
    override init() {
        super.init()
    }
}

func makeBox() -> some Container {
    StringBox(first: "some")
}

/// E4 fixture: protocol existentials, casts and conditional conformance.
func protocolChecks() -> [String] {
    var lines: [String] = []
    func emit(_ name: String, _ value: String) {
        lines.append("PRT_\(name)=\(value)")
    }

    let things: [Any] = [Tag(label: "tag"), Item(label: "item", count: 2)]

    // any P and any P & Q, as? and is.
    let describables = things.compactMap { $0 as? any Describable }
    emit("ANY", describables.map { $0.label }.joined(separator: ","))
    emit("IS", things.map { $0 is any Describable ? "true" : "false" }.joined(separator: ","))
    if let both = things[1] as? any Describable & Countable {
        emit("COMPOSED", "\(both.label):\(both.count)")
    } else {
        emit("COMPOSED", "none")
    }

    // Forced cast on a class and a would-be protocol cast that must fail.
    let item = things[1] as! Item
    emit("FORCED", item.label)
    emit("FAILEDCAST", (things[0] as? any Countable) == nil ? "nil" : "value")

    // Conditional conformance of Array.
    let items = [Item(label: "a", count: 1), Item(label: "b", count: 2)]
    emit("COND", items.label)
    let tags = [Tag(label: "x"), Tag(label: "y")]
    emit("CONDTAG", tags.label)

    // A protocol with an associated type behind some and a generic class witness.
    let box = makeBox()
    emit("SOME", box.summary)
    let holder = Holder<String>("holder")
    emit("GENERIC", holder.summary)
    let many: [any Container] = [StringBox(first: "existential")]
    emit("ANYSOME", "\(many.count),\(many[0].summary)")

    // AnyHashable and AnyObject casts.
    let hashed: AnyHashable = AnyHashable(42)
    let unboxed = hashed.base as? Int
    let mixed: [AnyHashable] = [AnyHashable(42), AnyHashable("text")]
    emit("HASH", "\(unboxed ?? -1),\(mixed.count)")

    let object: AnyObject = NSMutableString(string: "boxed")
    let asString = object as? String
    let asView = object as? UIView
    emit("ANYOBJECT", "\(asString ?? "nil"),\(asView == nil ? "nil" : "view")")

    // Class casts with is/as?/as!.
    let base: BaseClass = DerivedClass()
    let down = base as? DerivedClass
    let derived = DerivedClass() as BaseClass
    emit("CLASS", "\(base is DerivedClass),\(down != nil),\(derived is BaseClass),\(derived is DerivedClass)")

    return lines
}
