import UIKit

final class RatingLabelView: UIView {
    // MARK: - UI Components

    private let label: UILabel = {
        let label = UILabel()
        label.font = Typography.font
        label.textColor = Colors.foregroundColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: SFSymbolNames.starFill)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = Colors.foregroundColor
        return imageView
    }()

    // MARK: - Properties

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }

    // MARK: - Setup

    private func setupView() {
        layer.cornerRadius = Layout.cornerRadius
        backgroundColor = Colors.backgroundColor
        translatesAutoresizingMaskIntoConstraints = false

        addSubviews(starImageView, label)
        NSLayoutConstraint.activate([
            // Star image
            starImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.insets.left),
            starImageView.topAnchor.constraint(equalTo: topAnchor, constant: Layout.insets.top),
            starImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.insets.bottom),
            starImageView.widthAnchor.constraint(equalToConstant: StarLayout.size),
            starImageView.heightAnchor.constraint(equalTo: starImageView.widthAnchor),

            // Label
            label.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: Layout.spacing),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.insets.right),
            label.centerYAnchor.constraint(equalTo: starImageView.centerYAnchor)
        ])
    }
}

// MARK: - Design System Constants

extension RatingLabelView {
    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        static let spacing: CGFloat = 4
    }

    private enum StarLayout {
        static let size: CGFloat = 16
    }

    private enum Typography {
        static let fontSize: CGFloat = 14
        static let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
    }

    private enum Colors {
        static let foregroundColor = UIColor.systemYellow
        static let backgroundColor = UIColor.systemBackground
    }
}
