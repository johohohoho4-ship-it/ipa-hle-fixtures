import Darwin
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
///
/// `puts` instead of `print`: a -O `print` and the returned `[String]` would make the
/// app build an array (`_ArrayBuffer._consumeAndCreateNew`, `_swift_arrayInitWithCopy`)
/// that the HLE does not implement; the E4 comparison must not depend on that.
func stringCompareChecks() {
    let dot = "\u{0226}"
    let dotted = "\u{0226}\u{0304}"
    puts("SC_DOT_LT=\(dot < dotted)")
    puts("SC_DOTTED_LT=\(dotted < dot)")
    puts("SC_DOT_EQ=\(dot == dotted)")

    let composed = "é"
    let decomposed = "e\u{0301}"
    puts("SC_ACCENT_EQ=\(composed == decomposed)")
    puts("SC_ACCENT_LT=\(composed < decomposed)")

    let longLeft = "a String long enough for the heap: " + "b"
    let longRight = "a String long enough for the heap: " + "c"
    puts("SC_LONG_LT=\(longLeft < longRight)")
    puts("SC_ASCII_LT=\("pen" < "pencil")")

    // An NSString bridged back to String is foreign: the NFC scalars decide.
    let foreign = ("\u{0226}" as NSString) as String
    puts("SC_FOREIGN_LT=\(foreign < dotted)")
    puts("SC_FOREIGN_DOTTED_LT=\(dotted < foreign)")
    puts("SC_FOREIGN_EQ=\(foreign == dot)")
}
