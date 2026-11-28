//
//  Typography.swift
//  ToDoListUIkit
//
//  Created by mac on 7/9/25.
// Typography.swift
// A scalable and consistent custom font system for iOS
import UIKit
import Foundation

// MARK: - FontType
enum FontType: String {
    case robotoRegular = "Roboto-Regular"
    case robotoMedium = "Roboto-Medium"
    case robotoBold = "Roboto-Bold"

    var name: String { self.rawValue }
}

// MARK: - FontStyle
enum FontStyle {
    case heading1, heading2, heading3
    case body, secondaryText, caption

    fileprivate var description: FontDescription {
        switch self {
        case .heading1:
            return FontDescription(font: .robotoBold, size: .theme(.heading1), style: .title1)
        case .heading2:
            return FontDescription(font: .robotoMedium, size: .theme(.heading2), style: .title2)
        case .heading3:
            return FontDescription(font: .robotoMedium, size: .theme(.heading3), style: .title3)
        case .body:
            return FontDescription(font: .robotoRegular, size: .theme(.body), style: .body)
        case .secondaryText:
            return FontDescription(font: .robotoRegular, size: .theme(.secondaryText), style: .body)
        case .caption:
            return FontDescription(font: .robotoMedium, size: .theme(.caption), style: .caption1)
        }
    }

    var font: UIFont {
        let desc = description
        guard let customFont = UIFont(name: desc.font.name, size: desc.size.value) else {
            return UIFont.preferredFont(forTextStyle: desc.style)
        }
        return UIFontMetrics(forTextStyle: desc.style).scaledFont(for: customFont)
    }
}

// MARK: - FontSize
enum FontSize {
    case custom(Double)
    case theme(FontStyleSize)

    var value: Double {
        switch self {
        case .custom(let size):
            return size
        case .theme(let styleSize):
            return styleSize.size
        }
    }
}

// MARK: - FontStyleSize
enum FontStyleSize {
    case heading1, heading2, heading3, body, secondaryText, caption

    var size: Double {
        switch self {
        case .heading1: return 32
        case .heading2: return 26
        case .heading3: return 22
        case .body: return 16
        case .secondaryText: return 14
        case .caption: return 12
        }
    }
}

// MARK: - FontDescription
fileprivate struct FontDescription {
    let font: FontType
    let size: FontSize
    let style: UIFont.TextStyle
}

// MARK: - UIFont convenience
extension UIFont {
    static func style(_ style: FontStyle) -> UIFont {
        return style.font
    }

    convenience init(type: FontType, size: FontSize) {
        self.init(name: type.name, size: size.value)!
    }
}
