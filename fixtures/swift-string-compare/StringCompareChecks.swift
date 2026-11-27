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
/// "less" (true), the NFC-scalar path says "not less" (false).
///
/// `withCString` + `puts` instead of `print`: a -O `print` or a returned `[String]`
/// builds an array (`_ArrayBuffer._consumeAndCreateNew` → `_swift_arrayInitWithCopy`)
/// and an implicitly converted String uses `String.utf8CString`; neither is
/// implemented in the strict HLE yet. Every line is longer than 15 UTF-8 bytes, so it
/// is a native, zero-terminated String and `withCString` takes its fast path.
func stringCompareChecks() {
    let dot = "\u{0226}"
    let dotted = "\u{0226}\u{0304}"
    report("SC_STRING_COMPARE_DOT_LT=\(dot < dotted)")
    report("SC_STRING_COMPARE_DOTTED_LT=\(dotted < dot)")
    report("SC_STRING_COMPARE_DOT_EQ=\(dot == dotted)")

    let composed = "é"
    let decomposed = "e\u{0301}"
    report("SC_STRING_COMPARE_ACCENT_EQ=\(composed == decomposed)")
    report("SC_STRING_COMPARE_ACCENT_LT=\(composed < decomposed)")

    let longLeft = "a String long enough for the heap: " + "b"
    let longRight = "a String long enough for the heap: " + "c"
    report("SC_STRING_COMPARE_LONG_LT=\(longLeft < longRight)")
    report("SC_STRING_COMPARE_ASCII_LT=\("pen" < "pencil")")

    // An NSString bridged back to String is foreign: the NFC scalars decide.
    let foreign = ("\u{0226}" as NSString) as String
    report("SC_STRING_COMPARE_FOREIGN_LT=\(foreign < dotted)")
    report("SC_STRING_COMPARE_FOREIGN_DOTTED_LT=\(dotted < foreign)")
    report("SC_STRING_COMPARE_FOREIGN_EQ=\(foreign == dot)")
}

private func report(_ line: String) {
    line.withCString { puts($0) }
}
