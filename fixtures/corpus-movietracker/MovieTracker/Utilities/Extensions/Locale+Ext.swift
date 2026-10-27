import Foundation

extension Locale {
    var bcp47Identifier: String {
        identifier.replacingOccurrences(of: "_", with: "-")
    }

    static let englishUnitedStatesPOSIX = Locale(identifier: "en_US_POSIX")
}
