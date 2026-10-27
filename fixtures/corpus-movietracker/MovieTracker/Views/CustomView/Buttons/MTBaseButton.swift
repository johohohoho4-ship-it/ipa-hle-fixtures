import UIKit

/// A base class for generic buttons in the application.
class MTBaseButton: UIButton {
    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    func setupButton() {
        setupAppearance()
        setupBehavior()
    }

    private func setupAppearance() {
        layer.cornerRadius = Layout.cornerRadius
        titleLabel?.font = Typography.font
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupBehavior() {
        addTarget(self, action: #selector(buttonPressed), for: .touchDown)
        addTarget(self, action: #selector(buttonReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    // MARK: - Touch Feedback

    @objc private func buttonPressed() {
        animatePress(pressed: true)
    }

    @objc private func buttonReleased() {
        animatePress(pressed: false)
    }

    private func animatePress(pressed: Bool) {
        UIView.animate(
            withDuration: Animation.duration,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseInOut]
        ) {
            self.transform = pressed ?
                CGAffineTransform(scaleX: Animation.pressedScale, y: Animation.pressedScale) :
                .identity
        }
    }
}

// MARK: - Design System Constants

extension MTBaseButton {
    enum Layout {
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 1
        static let minimumHeight: CGFloat = 44
    }

    enum Typography {
        static let font = UIFont.systemFont(ofSize: 16, weight: .medium)
    }

    enum Animation {
        static let duration: TimeInterval = 0.15
        static let pressedScale: CGFloat = 0.96
    }
}
