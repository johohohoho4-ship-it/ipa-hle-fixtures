import Foundation

// Built with -Onone (see the project), so the non-inlinable standard library stays
// visible: String storage and bridging to NSString, Array/Dictionary/Set bridging to
// NSArray/NSDictionary/NSSet, hashing of custom keys, print and interpolation (E5).
// Hash seeds are random per process, so no check prints a Set or Dictionary order.

struct Coordinate: Hashable {
    let row: Int
    let column: Int
}

struct Tag: Hashable {
    let name: String
    let weight: Int

    // Custom hashing: only the name counts, as equality below.
    static func == (lhs: Tag, rhs: Tag) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
}

@inline(never)
func roundTrip<T>(_ value: T) -> T {
    value
}

/// Runs every check; each result is one line "name=value" so the HLE run and the
/// simulator reference can be compared line by line.
func runCollectionsChecks() -> [(String, Bool, String)] {
    var results: [(String, Bool, String)] = []

    func check(_ name: String, _ ok: Bool, _ detail: String) {
        results.append((name, ok, detail))
    }

    // String basics: grapheme clusters, UTF-8/UTF-16 views, case mapping.
    let greeting = "Grüße 👋🏽!"
    check("string_counts", greeting.count == 8 && greeting.utf8.count == 17 && greeting.utf16.count == 11,
          "\(greeting.count),\(greeting.utf8.count),\(greeting.utf16.count)")
    check("string_case", greeting.uppercased() == "GRÜSSE 👋🏽!" && "ÄBC".lowercased() == "äbc",
          greeting.uppercased())
    let words = "eins zwei  drei".split(separator: " ")
    check("string_split", words.count == 3 && words[1] == "zwei" && words.joined(separator: "-") == "eins-zwei-drei",
          words.joined(separator: "-"))
    let long = String(repeating: "ab", count: 20)
    check("string_large", long.count == 40 && long.hasPrefix("abab") && long.hasSuffix("ab"), "\(long.count)")
    var built = ""
    for number in 1...5 {
        built += String(number)
    }
    built.append(contentsOf: "…")
    check("string_append", built == "12345…" && built.count == 6, built)
    let chars = Array("Hallo")
    check("string_characters", chars.count == 5 && chars[1] == "a" && String(chars.reversed()) == "ollaH",
          String(chars.reversed()))
    let substring = greeting.prefix(5)
    check("substring", substring == "Grüße" && String(substring).count == 5, String(substring))
    check("string_numbers", Int("42") == 42 && Int("x") == nil && String(3.5) == "3.5" && String(-17) == "-17",
          "\(Int("42") ?? -1),\(String(3.5))")

    // Interpolation of several types.
    let optionalName: String? = "Anna"
    let missing: Int? = nil
    let line = "i=\(7) d=\(2.25) b=\(true) o=\(optionalName ?? "-") n=\(String(describing: missing))"
    check("interpolation", line == "i=7 d=2.25 b=true o=Anna n=nil", line)

    // String <-> NSString bridging.
    let bridged = greeting as NSString
    check("nsstring_bridge", bridged.length == 11 && bridged.substring(to: 5) == "Grüße", "\(bridged.length)")
    let formatted = NSString(format: "%@-%d", "x", 5) as String
    check("nsstring_to_string", formatted == "x-5" && formatted.count == 3, formatted)
    let replaced = "a,b,c".replacingOccurrences(of: ",", with: ";")
    let components = "1/2/3".components(separatedBy: "/")
    check("foundation_string", replaced == "a;b;c" && components == ["1", "2", "3"], replaced)

    // Array <-> NSArray bridging.
    let names = ["Anna", "Ben", "Cem"]
    let nsNames = names as NSArray
    check("array_to_nsarray", nsNames.count == 3 && (nsNames.object(at: 1) as? String) == "Ben", "\(nsNames.count)")
    let fromObjC = NSArray(array: ["x", 1, 2.5]) as? [Any] ?? []
    let back = nsNames as? [String] ?? []
    check("nsarray_to_array", fromObjC.count == 3 && (fromObjC[1] as? Int) == 1 && back == names,
          back.joined(separator: ","))
    let sortedNames = (NSArray(array: ["c", "a", "b"]) as? [String] ?? []).sorted()
    check("array_sorted", sortedNames == ["a", "b", "c"], sortedNames.joined())

    // Dictionary <-> NSDictionary bridging.
    let ages: [String: Int] = ["Anna": 31, "Ben": 27]
    let nsAges = ages as NSDictionary
    check("dictionary_to_nsdictionary", nsAges.count == 2 && (nsAges["Ben"] as? Int) == 27, "\(nsAges.count)")
    let nsBack = NSDictionary(dictionary: ["k": "v", "n": 3]) as? [String: Any] ?? [:]
    check("nsdictionary_to_dictionary", nsBack.count == 2 && (nsBack["k"] as? String) == "v" && (nsBack["n"] as? Int) == 3,
          "\(nsBack.count)")
    let sortedKeys = ages.keys.sorted()
    let total = ages.values.reduce(0, +)
    check("dictionary_keys_values", sortedKeys == ["Anna", "Ben"] && total == 58, "\(sortedKeys.joined(separator: ",")),\(total)")
    var counts: [Character: Int] = [:]
    for char in "banana" {
        counts[char, default: 0] += 1
    }
    check("dictionary_counting", counts["a"] == 3 && counts["n"] == 2 && counts["b"] == 1 && counts.count == 3,
          "\(counts["a"] ?? 0)")
    var removable = ages
    removable["Anna"] = nil
    removable["Cem"] = 40
    check("dictionary_mutation", removable.count == 2 && removable["Anna"] == nil && removable["Cem"] == 40,
          "\(removable.count)")

    // Hashing of custom keys.
    var grid: [Coordinate: String] = [:]
    grid[Coordinate(row: 0, column: 1)] = "A"
    grid[Coordinate(row: 2, column: 3)] = "B"
    grid[Coordinate(row: 0, column: 1)] = "C"
    check("custom_hashable_key", grid.count == 2 && grid[Coordinate(row: 0, column: 1)] == "C", "\(grid.count)")
    let tags = Set([Tag(name: "swift", weight: 1), Tag(name: "swift", weight: 2), Tag(name: "ios", weight: 3)])
    check("custom_hash_into", tags.count == 2 && tags.contains(Tag(name: "ios", weight: 0)), "\(tags.count)")
    check("hash_value_stable", Coordinate(row: 4, column: 5).hashValue == Coordinate(row: 4, column: 5).hashValue
          && "abc".hashValue == ("ab" + "c").hashValue, "stable")

    // Set, including NSSet bridging.
    var letters = Set("mississippi")
    letters.insert("x")
    check("set_basics", letters.count == 5 && letters.contains("s") && !letters.contains("a"),
          String(letters.sorted()))
    let evens: Set = [2, 4, 6, 8]
    let small: Set = [1, 2, 3, 4]
    check("set_algebra", evens.intersection(small) == [2, 4] && evens.union(small).count == 6
          && evens.subtracting(small).sorted() == [6, 8], "\(evens.union(small).count)")
    let nsSet = Set(["a", "b"]) as NSSet
    let setBack = nsSet as? Set<String> ?? []
    check("set_nsset_bridge", nsSet.count == 2 && nsSet.contains("a") && setBack == ["a", "b"], "\(nsSet.count)")

    // Generic round trips keep bridged values intact.
    check("generic_round_trip", roundTrip(names) == names && roundTrip(ages) == ages && roundTrip(greeting) == greeting,
          "ok")

    // print goes through the standard output stream.
    print("PRINT", 1, 2.5, "drei", separator: "|")
    fflush(stdout)
    check("print_returned", true, "PRINT|1|2.5|drei")

    return results
}
