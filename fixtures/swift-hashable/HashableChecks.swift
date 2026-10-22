import Foundation

struct Word: Hashable {
    let text: String
}

/// E4 fixture: AnyHashable equality across Int/String/custom Hashable values,
/// a dictionary and a set keyed by AnyHashable, and hashValue stability for
/// equal values. Only booleans and small integers are printed; raw hash values
/// are seeded per process.
func hashableChecks() -> [String] {
    var lines: [String] = []

    let one = AnyHashable(1)
    let anotherOne = AnyHashable(1)
    let oneText = AnyHashable("1")
    lines.append("HSH_INT=\(one == anotherOne):\(one == oneText)")

    let longText = "a string longer than fifteen bytes"
    lines.append("HSH_INLINE=\(AnyHashable(longText) == AnyHashable(longText))")

    let word = Word(text: "ipa")
    lines.append("HSH_STRUCT=\(AnyHashable(word) == AnyHashable(Word(text: "ipa")))")

    var dictionary: [AnyHashable: Int] = [
        AnyHashable(1): 10,
        AnyHashable("one"): 20,
        AnyHashable(word): 30,
    ]
    let lookedUp = [
        dictionary[AnyHashable(1)] ?? -1,
        dictionary[AnyHashable("one")] ?? -1,
        dictionary[AnyHashable(Word(text: "ipa"))] ?? -1,
    ]
    lines.append("HSH_DICT=\(lookedUp.map(String.init).joined(separator: ","))")

    let set: Set<AnyHashable> = [AnyHashable(1), AnyHashable(1), AnyHashable("1"), AnyHashable("1")]
    lines.append("HSH_SET=\(set.count)")

    lines.append("HSH_HASH=\(AnyHashable(1).hashValue == AnyHashable(1).hashValue):\(word.hashValue == Word(text: "ipa").hashValue)")
    lines.append("HSH_DONE")
    return lines
}
