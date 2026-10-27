import UIKit

/// A generic button type for primary action buttons.
final class MTPrimaryButton: MTBaseButton {
    // MARK: - Setup

    override func setupButton() {
        super.setupButton()

        backgroundColor = Colors.background
        setTitleColor(Colors.textNormal, for: .normal)
        setTitleColor(Colors.textHighlighted, for: .highlighted)
        setTitleColor(Colors.textDisabled, for: .disabled)

        layer.borderWidth = 0
    }
}

// MARK: - Design System Constants

extension MTPrimaryButton {
    enum Colors {
        static let background = UIColor.accent
        static let textNormal = UIColor.white
        static let textHighlighted = UIColor.white.withAlphaComponent(0.7)
        static let textDisabled = UIColor.white.withAlphaComponent(0.5)
    }
}
