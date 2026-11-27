import Foundation

/// E4 fixture: the seed model of Swift 6.1.2 when hashing is deterministic
/// (`SWIFT_DETERMINISTIC_HASHING=1`, set by the XCUITest's launchEnvironment).
/// The execution seed is then `(0, 0)` (`GlobalObjects.cpp`); `Hasher()` equals
/// `Hasher(_seed: 0)`, `_State(seed:)` XORs the seed into the execution seed's first
/// word (`SipHash.swift`), and a hash table's seed is its scale (`HashTable.swift`,
/// `_HashTable.hashSeed`). The lines print raw `hashValue`s, the iteration order of a
/// `Set` and a `Dictionary`, which follows that seed and the bucket probing.
///
/// Without the environment variable every value and order differs per process, so a
/// run with a different seed must not be compared line by line.
func deterministicHashingChecks() -> [String] {
    var lines: [String] = []

    lines.append("DH_HASH_INT7=\(7.hashValue)")
    lines.append("DH_HASH_INT40=\(40.hashValue)")
    lines.append("DH_HASH_PEN=\(("pen" as String).hashValue)")
    lines.append("DH_HASH_CAFE=\(("café" as String).hashValue)")
    lines.append("DH_HASH_LONG=\(("a string longer than fifteen bytes" as String).hashValue)")

    // A table of five members has scale 3 (eight buckets, load 3/4); its seed is 3.
    let numbers: Set<Int> = [7, 40, 3, 99, 1234]
    lines.append("DH_SET_INT=\(numbers)")
    let words: Set<String> = ["pen", "apple", "café", "a string longer than fifteen bytes"]
    lines.append("DH_SET_STRING=\(words)")

    let byNumber: [Int: String] = [7: "seven", 40: "forty", 3: "three", 99: "ninety-nine"]
    lines.append("DH_DICT_INT=\(byNumber)")
    let byWord: [String: Int] = ["pen": 1, "apple": 2, "café": 3, "a string longer than fifteen bytes": 4]
    lines.append("DH_DICT_STRING=\(byWord)")

    return lines
}
