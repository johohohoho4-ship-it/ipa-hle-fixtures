import Foundation

struct Word: Hashable {
    let text: String
}

/// A Hashable class and a subclass instance: the fixture measures whether
/// AnyHashable compares the subclass through the base's `==` (natively it
/// does) or keeps the dynamic type apart.
class Base: Hashable {
    let value: Int
    init(_ value: Int) { self.value = value }
    static func == (left: Base, right: Base) -> Bool { left.value == right.value }
    func hash(into hasher: inout Hasher) { hasher.combine(value) }
}

final class Sub: Base {}

/// An NSObject subclass with its own equality and hash.
final class Obj: NSObject {
    let value: Int
    init(_ value: Int) { self.value = value }
    override func isEqual(_ object: Any?) -> Bool { (object as? Obj)?.value == value }
    override var hash: Int { value.hashValue }
}

func typeName(_ value: Any) -> String {
    String(describing: type(of: value))
}

/// E4 fixture: numeric AnyHashable equality across integer widths and
/// Float/Double, NaN, the dynamic base type, class/subclass and NSObject
/// identity, NSNumber against Int, and a mixed-key dictionary. Only booleans,
/// type names and small integers are printed; raw hashes are seeded.
func hashableChecks2() -> [String] {
    var lines: [String] = []
    func equality(_ left: AnyHashable, _ right: AnyHashable) -> String {
        "\(left == right),\(left.hashValue == right.hashValue)"
    }

    lines.append("HSH2_INT_DOUBLE=\(equality(AnyHashable(1), AnyHashable(1.0)))")
    lines.append("HSH2_INT8_UINT64=\(equality(AnyHashable(Int8(1)), AnyHashable(UInt64(1))))")
    lines.append("HSH2_HALF=\(equality(AnyHashable(Float(0.5)), AnyHashable(Double(0.5))))")
    lines.append("HSH2_TENTH=\(equality(AnyHashable(Float(0.1)), AnyHashable(Double(0.1))))")
    let nan = Double.nan
    lines.append("HSH2_NAN=\(AnyHashable(nan) == AnyHashable(nan)),"
                 + "\(AnyHashable(nan).hashValue == AnyHashable(nan).hashValue)")
    lines.append("HSH2_TYPE_INT=\(typeName(AnyHashable(1).base))")
    lines.append("HSH2_TYPE_DOUBLE=\(typeName(AnyHashable(1.0).base))")

    let base = Base(1)
    lines.append("HSH2_CLASS_SAME=\(equality(AnyHashable(base), AnyHashable(Base(1))))")
    lines.append("HSH2_CLASS_SUB=\(equality(AnyHashable(base), AnyHashable(Sub(1))))")
    lines.append("HSH2_NSOBJECT=\(equality(AnyHashable(Obj(1)), AnyHashable(Obj(1))))")
    lines.append("HSH2_NSNUMBER_INT=\(equality(AnyHashable(NSNumber(value: 1)), AnyHashable(1)))")

    // Individual assignments: a literal with these three keys would trap at
    // runtime because they compare equal ("duplicate keys").
    var dictionary: [AnyHashable: Int] = [:]
    dictionary[AnyHashable(1)] = 10
    dictionary[AnyHashable(1.0)] = 20
    dictionary[AnyHashable(Int8(1))] = 30
    let lookedUp = [
        dictionary[AnyHashable(1)] ?? -1,
        dictionary[AnyHashable(1.0)] ?? -1,
        dictionary[AnyHashable(Int8(1))] ?? -1,
    ]
    lines.append("HSH2_DICT_MIXED=\(dictionary.count):"
                 + lookedUp.map(String.init).joined(separator: ","))

    return lines
}
