import Foundation

/// E4 fixture: `_stringCompareWithSmolCheck` as Swift 6.1.2 implements it
/// (`StringComparison.swift`). This app is compiled with `-O` (Release target), so an
/// inlined `String` `==`/`<` whose bits differ calls the standard library's
/// `_stringCompareWithSmolCheck`, exactly as the -O corpus apps do. Two fast UTF-8
/// strings that are both flagged NFC compare their bytes; otherwise a byte prefix is
/// less than the longer string (`_stringCompareFastUTF8Abnormal`); everything else,
/// and a foreign (bridged) string, compares NFC scalars.
///
/// U+0226 (Ȧ) against U+0226 U+0304: the second string's NFC is U+01E0 (Ǡ), a smaller
/// scalar, but its raw bytes start with the first string's bytes. The fast path says
/// "less", the NFC-scalar path says "not less".
func stringCompareChecks() -> [String] {
    var lines: [String] = []

    let dot = "\u{0226}"
    let dotted = "\u{0226}\u{0304}"
    lines.append("SC_DOT_LT=\(dot < dotted)")
    lines.append("SC_DOTTED_LT=\(dotted < dot)")
    lines.append("SC_DOT_EQ=\(dot == dotted)")

    let composed = "é"
    let decomposed = "e\u{0301}"
    lines.append("SC_ACCENT_EQ=\(composed == decomposed)")
    lines.append("SC_ACCENT_LT=\(composed < decomposed)")

    let longLeft = "a String long enough for the heap: " + "b"
    let longRight = "a String long enough for the heap: " + "c"
    lines.append("SC_LONG_LT=\(longLeft < longRight)")
    lines.append("SC_ASCII_LT=\("pen" < "pencil")")

    // An NSString bridged back to String is foreign: the NFC scalars decide.
    let foreign = ("\u{0226}" as NSString) as String
    lines.append("SC_FOREIGN_LT=\(foreign < dotted)")
    lines.append("SC_FOREIGN_DOTTED_LT=\(dotted < foreign)")
    lines.append("SC_FOREIGN_EQ=\(foreign == dot)")

    return lines
}
