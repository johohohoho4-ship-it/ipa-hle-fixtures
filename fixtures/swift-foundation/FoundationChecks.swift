import Foundation

// Built with -Onone (see the project), so calls into the Swift Foundation overlay stay
// visible as imports: Data, URL, Date, Calendar, JSONEncoder/JSONDecoder with Codable,
// and the Swift API of UserDefaults and FileManager (roadmap E6).
// Every printed value is deterministic: fixed dates, UTC or named zones, en_US_POSIX, sorted JSON keys.

struct Address: Codable, Equatable {
    var street: String
    var zip: Int
}

struct Person: Codable, Equatable {
    var name: String
    var age: Int
    var height: Double
    var member: Bool
    var nickname: String?
    var tags: [String]
    var address: Address
    var scores: [String: Int]
}

enum Level: String, Codable {
    case low
    case high
}

struct Settings: Codable, Equatable {
    var level: Level
    var limits: [Int]
    var ratio: Float

    enum CodingKeys: String, CodingKey {
        case level = "lvl"
        case limits
        case ratio
    }
}

struct Strict: Decodable {
    var count: Int
}

struct Event: Codable, Equatable {
    var eventName: String
    var startDate: Date
    var payloadBytes: Data
    var extraInfo: [String: Int]
}

func hex(_ data: Data) -> String {
    data.map { String(format: "%02x", $0) }.joined()
}

/// Runs every check; each result is one line "name=value" so the HLE run and the
/// simulator reference can be compared line by line.
func runFoundationChecks() -> [(String, Bool, String)] {
    var results: [(String, Bool, String)] = []

    func check(_ name: String, _ ok: Bool, _ detail: String) {
        results.append((name, ok, detail))
    }

    // Data: construction, append, subscripts, slices, conversions.
    var data = Data([0x48, 0x69])
    data.append(0x21)
    data.append(contentsOf: [0x00, 0xff])
    check("data_bytes", data.count == 5 && data[0] == 0x48 && data.last == 0xff, hex(data))
    let slice = data[1..<3]
    check("data_slice", slice.count == 2 && slice.first == 0x69 && Data(slice) == Data([0x69, 0x21]), hex(Data(slice)))
    let text = Data("Grüße".utf8)
    check("data_utf8", text.count == 7 && String(data: text, encoding: .utf8) == "Grüße", hex(text))
    let big = Data(repeating: 7, count: 100)
    check("data_large", big.count == 100 && big.allSatisfy { $0 == 7 }, "\(big.count)")
    check("data_base64", text.base64EncodedString() == "R3LDvMOfZQ==" &&
          Data(base64Encoded: "R3LDvMOfZQ==") == text, text.base64EncodedString())
    let sum = data.withUnsafeBytes { raw in raw.reduce(0) { $0 + Int($1) } }
    check("data_unsafe", sum == 0x48 + 0x69 + 0x21 + 0xff, "\(sum)")

    // URL: parsing, components, appending, file URLs.
    let url = URL(string: "https://example.com:8080/a/b.json?q=1&r=two#frag")!
    check("url_parts", url.scheme == "https" && url.host == "example.com" && url.port == 8080 &&
          url.path == "/a/b.json" && url.query == "q=1&r=two" && url.fragment == "frag",
          "\(url.scheme ?? "-")|\(url.host ?? "-")|\(url.path)|\(url.query ?? "-")")
    check("url_file", url.lastPathComponent == "b.json" && url.pathExtension == "json" &&
          url.deletingLastPathComponent().path == "/a",
          url.deletingLastPathComponent().path)
    let appended = URL(string: "https://example.com/base")!.appendingPathComponent("item 1")
    check("url_append", appended.absoluteString == "https://example.com/base/item%201", appended.absoluteString)
    let file = URL(fileURLWithPath: "/tmp/dir/name.txt")
    check("url_fileurl", file.isFileURL && file.path == "/tmp/dir/name.txt" &&
          file.absoluteString == "file:///tmp/dir/name.txt", file.absoluteString)
    var components = URLComponents()
    components.scheme = "https"
    components.host = "example.com"
    components.path = "/search"
    components.queryItems = [URLQueryItem(name: "q", value: "a b"), URLQueryItem(name: "n", value: "2")]
    check("url_components", components.url?.absoluteString == "https://example.com/search?q=a%20b&n=2",
          components.url?.absoluteString ?? "nil")
    check("url_invalid", URL(string: "") == nil, "\(URL(string: "") == nil)")

    // Date and Calendar in UTC with the Gregorian calendar.
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    let later = date.addingTimeInterval(90)
    check("date_interval", later.timeIntervalSince(date) == 90 && later > date &&
          date.timeIntervalSinceReferenceDate == 1_700_000_000 - 978_307_200,
          "\(date.timeIntervalSince1970)")
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .weekday], from: date)
    check("calendar_components", parts.year == 2023 && parts.month == 11 && parts.day == 14 &&
          parts.hour == 22 && parts.minute == 13 && parts.weekday == 3,
          "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0) \(parts.hour ?? 0):\(parts.minute ?? 0) w\(parts.weekday ?? 0)")
    let nextMonth = calendar.date(byAdding: .month, value: 3, to: date)!
    check("calendar_add", calendar.component(.month, from: nextMonth) == 2 &&
          calendar.component(.year, from: nextMonth) == 2024, "\(nextMonth.timeIntervalSince1970)")
    let built = calendar.date(from: DateComponents(year: 2024, month: 2, day: 29, hour: 12))!
    check("calendar_build", built.timeIntervalSince1970 == 1_709_208_000 &&
          calendar.isDate(built, inSameDayAs: built.addingTimeInterval(3600)),
          "\(built.timeIntervalSince1970)")
    let start = calendar.startOfDay(for: date)
    check("calendar_start", start.timeIntervalSince1970 == 1_699_920_000, "\(start.timeIntervalSince1970)")
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    check("date_format", formatter.string(from: date) == "2023-11-14T22:13:20" &&
          formatter.date(from: "2023-11-14T22:13:20") == date, formatter.string(from: date))

    // D7: dateStyle/timeStyle instead of an explicit pattern, in both fixture locales.
    // These rows are measurements: the value after "ok" is the simulator's string.
    let styleDate = Date(timeIntervalSince1970: 1_700_000_000)  // 2023-11-14 22:13:20 UTC
    let styleNames: [(String, DateFormatter.Style)] = [
        ("short", .short), ("medium", .medium), ("long", .long), ("full", .full),
    ]
    for (language, identifier) in [("en", "en_US"), ("de", "de_DE")] {
        for (name, style) in styleNames {
            let dateOnly = DateFormatter()
            dateOnly.locale = Locale(identifier: identifier)
            dateOnly.timeZone = TimeZone(identifier: "UTC")
            dateOnly.dateStyle = style
            dateOnly.timeStyle = .none
            check("date_style_\(language)_\(name)", true, dateOnly.string(from: styleDate))

            let timeOnly = DateFormatter()
            timeOnly.locale = Locale(identifier: identifier)
            timeOnly.timeZone = TimeZone(identifier: "UTC")
            timeOnly.dateStyle = .none
            timeOnly.timeStyle = style
            check("time_style_\(language)_\(name)", true, timeOnly.string(from: styleDate))
        }
        let both = DateFormatter()
        both.locale = Locale(identifier: identifier)
        both.timeZone = TimeZone(identifier: "UTC")
        both.dateStyle = .long
        both.timeStyle = .short
        check("date_time_\(language)_long_short", true, both.string(from: styleDate))
    }


    // Codable through JSON: nested types, optionals, arrays, dictionaries, custom keys.
    let person = Person(name: "Ada", age: 36, height: 1.68, member: true, nickname: nil,
                        tags: ["math", "code"], address: Address(street: "Main St", zip: 12345),
                        scores: ["a": 1, "b": 2])
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    do {
        let json = try encoder.encode(person)
        let string = String(data: json, encoding: .utf8) ?? "nil"
        check("json_encode", string ==
              #"{"address":{"street":"Main St","zip":12345},"age":36,"height":1.68,"member":true,"name":"Ada","scores":{"a":1,"b":2},"tags":["math","code"]}"#,
              string)
        let decoded = try JSONDecoder().decode(Person.self, from: json)
        check("json_roundtrip", decoded == person, decoded.name)
    } catch {
        check("json_encode", false, "\(error)")
    }
    do {
        let input = #"{"lvl":"high","limits":[3,1,2],"ratio":0.5,"ignored":null}"#
        let settings = try JSONDecoder().decode(Settings.self, from: Data(input.utf8))
        check("json_keys", settings == Settings(level: .high, limits: [3, 1, 2], ratio: 0.5),
              "\(settings.level.rawValue)|\(settings.limits)")
        let pretty = JSONEncoder()
        pretty.outputFormatting = [.prettyPrinted, .sortedKeys]
        let output = String(data: try pretty.encode(settings), encoding: .utf8) ?? "nil"
        check("json_pretty", output == "{\n  \"limits\" : [\n    3,\n    1,\n    2\n  ],\n  \"lvl\" : \"high\",\n  \"ratio\" : 0.5\n}",
              output.replacingOccurrences(of: "\n", with: "\\n"))
    } catch {
        check("json_keys", false, "\(error)")
    }
    do {
        _ = try JSONDecoder().decode(Strict.self, from: Data(#"{"count":"seven"}"#.utf8))
        check("json_type_error", false, "decoded")
    } catch DecodingError.typeMismatch(_, let context) {
        check("json_type_error", context.codingPath.map { $0.stringValue } == ["count"],
              context.codingPath.map { $0.stringValue }.joined(separator: "."))
    } catch {
        check("json_type_error", false, "\(error)")
    }
    do {
        _ = try JSONDecoder().decode(Strict.self, from: Data("{}".utf8))
        check("json_missing_key", false, "decoded")
    } catch DecodingError.keyNotFound(let key, _) {
        check("json_missing_key", key.stringValue == "count", key.stringValue)
    } catch {
        check("json_missing_key", false, "\(error)")
    }
    do {
        let dates = JSONEncoder()
        dates.dateEncodingStrategy = .secondsSince1970
        let out = String(data: try dates.encode([date]), encoding: .utf8) ?? "nil"
        check("json_date", out == "[1700000000]", out)
    } catch {
        check("json_date", false, "\(error)")
    }

    // Key and date strategies, Data as Base64 (the default data strategy).
    let event = Event(eventName: "Launch", startDate: date, payloadBytes: Data([1, 2, 255]),
                      extraInfo: ["someKey": 1])
    do {
        let snake = JSONEncoder()
        snake.outputFormatting = [.sortedKeys]
        snake.keyEncodingStrategy = .convertToSnakeCase
        snake.dateEncodingStrategy = .iso8601
        let out = String(data: try snake.encode(event), encoding: .utf8) ?? "nil"
        // The key strategy converts coding keys only; a [String: Int] keeps its own keys.
        check("json_snake_case", out ==
              #"{"event_name":"Launch","extra_info":{"someKey":1},"payload_bytes":"AQL\/","start_date":"2023-11-14T22:13:20Z"}"#,
              out)
        let back = JSONDecoder()
        back.keyDecodingStrategy = .convertFromSnakeCase
        back.dateDecodingStrategy = .iso8601
        let decoded = try back.decode(Event.self, from: Data(out.utf8))
        check("json_snake_roundtrip", decoded == event, decoded.eventName)
    } catch {
        check("json_snake_case", false, "\(error)")
    }
    do {
        let millis = JSONEncoder()
        millis.dateEncodingStrategy = .millisecondsSince1970
        let out = String(data: try millis.encode([date]), encoding: .utf8) ?? "nil"
        check("json_date_millis", out == "[1700000000000]", out)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let seconds = try decoder.decode([Date].self, from: Data("[1700000000.5]".utf8))
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let fromMillis = try decoder.decode([Date].self, from: Data("[1700000000000]".utf8))
        let deferred = try JSONDecoder().decode([Date].self, from: Data("[721692800]".utf8))
        check("json_date_decode", seconds == [date.addingTimeInterval(0.5)] && fromMillis == [date] &&
              deferred == [date], "\(seconds[0].timeIntervalSince1970)")
    } catch {
        check("json_date_decode", false, "\(error)")
    }

    // Named IANA time zones with daylight saving time.
    let summer = Date(timeIntervalSince1970: 1_688_212_800)      // 2023-07-01 12:00 UTC
    if let berlin = TimeZone(identifier: "Europe/Berlin") {
        check("zone_offsets", berlin.secondsFromGMT(for: date) == 3600 && berlin.secondsFromGMT(for: summer) == 7200,
              "\(berlin.identifier) \(berlin.secondsFromGMT(for: date)) \(berlin.secondsFromGMT(for: summer))")
        let local = DateFormatter()
        local.locale = Locale(identifier: "en_US_POSIX")
        local.timeZone = berlin
        local.dateFormat = "yyyy-MM-dd HH:mm"
        check("zone_format", local.string(from: summer) == "2023-07-01 14:00", local.string(from: summer))
    } else {
        check("zone_offsets", false, "nil")
    }
    var newYork = Calendar(identifier: .gregorian)
    newYork.timeZone = TimeZone(identifier: "America/New_York") ?? TimeZone(identifier: "UTC")!
    let ny = newYork.dateComponents([.month, .day, .hour], from: summer)
    check("zone_calendar", ny.month == 7 && ny.day == 1 && ny.hour == 8,
          "\(ny.month ?? 0)-\(ny.day ?? 0) \(ny.hour ?? 0)")
    check("zone_invalid", TimeZone(identifier: "Mars/Olympus") == nil, "\(TimeZone(identifier: "Mars/Olympus") == nil)")

    // UserDefaults through its Swift API.
    let defaults = UserDefaults.standard
    defaults.set(42, forKey: "fixture.int")
    defaults.set("wert", forKey: "fixture.string")
    defaults.set(["x", "y"], forKey: "fixture.array")
    defaults.set(true, forKey: "fixture.bool")
    check("defaults_values", defaults.integer(forKey: "fixture.int") == 42 &&
          defaults.string(forKey: "fixture.string") == "wert" &&
          defaults.stringArray(forKey: "fixture.array") == ["x", "y"] &&
          defaults.bool(forKey: "fixture.bool") && defaults.object(forKey: "fixture.none") == nil,
          defaults.string(forKey: "fixture.string") ?? "nil")
    defaults.removeObject(forKey: "fixture.int")
    check("defaults_remove", defaults.integer(forKey: "fixture.int") == 0, "\(defaults.integer(forKey: "fixture.int"))")

    // FileManager and Data file I/O through URLs.
    let manager = FileManager.default
    let folder = manager.temporaryDirectory.appendingPathComponent("e6-fixture", isDirectory: true)
    do {
        try? manager.removeItem(at: folder)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        let target = folder.appendingPathComponent("person.json")
        try encoder.encode(person).write(to: target, options: .atomic)
        let back = try Data(contentsOf: target)
        let names = try manager.contentsOfDirectory(atPath: folder.path)
        check("file_roundtrip", try JSONDecoder().decode(Person.self, from: back) == person &&
              manager.fileExists(atPath: target.path) && names == ["person.json"],
              names.joined(separator: ","))
        let attributes = try manager.attributesOfItem(atPath: target.path)
        check("file_size", (attributes[.size] as? NSNumber)?.intValue == back.count, "\(back.count)")
        try manager.removeItem(at: folder)
        check("file_remove", !manager.fileExists(atPath: folder.path), "\(manager.fileExists(atPath: folder.path))")
    } catch {
        check("file_roundtrip", false, "\(error)")
    }
    let documents = manager.urls(for: .documentDirectory, in: .userDomainMask)
    check("file_documents", documents.count == 1 && documents[0].lastPathComponent == "Documents",
          documents.first?.lastPathComponent ?? "none")

    return results
}
