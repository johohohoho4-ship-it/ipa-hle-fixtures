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
/// "less" (1), the NFC-scalar path says "not less" (0).
///
/// `printf` with a literal format and a `CInt` argument instead of `print`/`puts`: a
/// -O `print` or a returned `[String]` builds an array
/// (`_ArrayBuffer._consumeAndCreateNew` → `_swift_arrayInitWithCopy`) and an
/// interpolated String passed to `puts` uses `String.utf8CString`; neither is
/// implemented in the strict HLE yet, and this E4 comparison must not depend on them.
func stringCompareChecks() {
    let dot = "\u{0226}"
    let dotted = "\u{0226}\u{0304}"
    printf("SC_DOT_LT=%d\n", CInt(dot < dotted ? 1 : 0))
    printf("SC_DOTTED_LT=%d\n", CInt(dotted < dot ? 1 : 0))
    printf("SC_DOT_EQ=%d\n", CInt(dot == dotted ? 1 : 0))

    let composed = "é"
    let decomposed = "e\u{0301}"
    printf("SC_ACCENT_EQ=%d\n", CInt(composed == decomposed ? 1 : 0))
    printf("SC_ACCENT_LT=%d\n", CInt(composed < decomposed ? 1 : 0))

    let longLeft = "a String long enough for the heap: " + "b"
    let longRight = "a String long enough for the heap: " + "c"
    printf("SC_LONG_LT=%d\n", CInt(longLeft < longRight ? 1 : 0))
    printf("SC_ASCII_LT=%d\n", CInt("pen" < "pencil" ? 1 : 0))

    // An NSString bridged back to String is foreign: the NFC scalars decide.
    let foreign = ("\u{0226}" as NSString) as String
    printf("SC_FOREIGN_LT=%d\n", CInt(foreign < dotted ? 1 : 0))
    printf("SC_FOREIGN_DOTTED_LT=%d\n", CInt(dotted < foreign ? 1 : 0))
    printf("SC_FOREIGN_EQ=%d\n", CInt(foreign == dot ? 1 : 0))
}
