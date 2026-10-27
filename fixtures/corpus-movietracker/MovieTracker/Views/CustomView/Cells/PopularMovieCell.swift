import UIKit

/// Cell for `UICollectionView` in `PopularMoviesViewController`.
final class PopularMovieCell: UICollectionViewCell {
    static let identifier = String(describing: PopularMovieCell.self)

    // MARK: - UI Components

    private lazy var posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = UIImage(resource: .noPoster)
        imageView.layer.cornerRadius = Layout.cornerRadius
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.titleFont
        label.textColor = .label
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.7
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var yearLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.yearFont
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var addToListButton: UIButton = {
        let button = MTPrimaryButton()
        button.setTitle(
            NSLocalizedString("add_to_watchlist_button_title", comment: "Add to watchlist button title"),
            for: .normal
        )
        return button
    }()

    private lazy var ratingView = RatingLabelView()

    // MARK: - Current Image Loading Task

    private var imageLoadingTask: Task<Void, Never>?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func configure(with movie: PopularMovie) {
        titleLabel.text = movie.title
        yearLabel.text = formatYear(from: movie.releaseDate)
        ratingView.text = String(format: "%.1f", movie.voteAverage)

        loadPosterImage(from: movie.posterPath)
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        resetCell()
    }

    // MARK: - Private Methods

    private func resetCell() {
        titleLabel.text = nil
        yearLabel.text = nil
        ratingView.text = nil
        posterImageView.image = UIImage(resource: .noPoster)

        imageLoadingTask?.cancel()
        imageLoadingTask = nil
    }

    private func formatYear(from date: Date?) -> String {
        guard let date else { return "-" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }

    private func loadPosterImage(from posterPath: String?) {
        imageLoadingTask?.cancel()

        guard let posterPath else {
            posterImageView.image = UIImage(resource: .noPoster)
            return
        }

        imageLoadingTask = Task { [weak self] in
            guard let self else { return }
            let image = await TMDBService.shared.fetchImage(from: posterPath, size: .w342)
            guard !Task.isCancelled else { return }
            posterImageView.image = image ?? UIImage(resource: .noPoster)
        }
    }

    private func setupUI() {
        setupContainerView()
        contentView.addSubviews(posterImageView, titleLabel, yearLabel, addToListButton, ratingView)
    }

    private func setupContainerView() {
        contentView.backgroundColor = Colors.background
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.clipsToBounds = true

        layer.shadowColor = Shadow.color
        layer.shadowOffset = Shadow.offset
        layer.shadowRadius = Shadow.radius
        layer.shadowOpacity = Shadow.opacity
        layer.masksToBounds = false
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Poster
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            posterImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            posterImageView.heightAnchor.constraint(
                equalTo: posterImageView.widthAnchor,
                multiplier: 1 / PosterLayout.aspectRatio
            ),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: Spacing.small),
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Layout.contentInsets.left
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Layout.contentInsets.right
            ),
            titleLabel.heightAnchor.constraint(equalToConstant: TitleLabelLayout.height),

            // Year label
            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Spacing.small),
            yearLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.contentInsets.left),
            yearLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Layout.contentInsets.right
            ),
            yearLabel.heightAnchor.constraint(equalToConstant: YearLabelLayout.height),

            // "Add to list" button
            addToListButton.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: Spacing.medium),
            addToListButton.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Layout.contentInsets.left
            ),
            addToListButton.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Layout.contentInsets.right
            ),
            addToListButton.heightAnchor.constraint(equalToConstant: ButtonLayout.height),

            // Rating view
            ratingView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Layout.ratingInsets.top
            ),
            ratingView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Layout.ratingInsets.right
            )
        ])
    }

    // MARK: - Cell Height Calculation

    static func cellHeight(for cellWidth: CGFloat) -> CGFloat {
        let posterHeight = cellWidth / PosterLayout.aspectRatio
        let totalSpacingHeight = Spacing.small * 3 + Spacing.medium
        return posterHeight + totalSpacingHeight + TitleLabelLayout.height + YearLabelLayout.height + ButtonLayout
            .height
    }
}

// MARK: - Design System Constants

extension PopularMovieCell {
    private enum Layout {
        static let cornerRadius: CGFloat = 8
        static let contentInsets = UIEdgeInsets(top: 0, left: 12, bottom: 12, right: 12)
        static let ratingInsets = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 8)
    }

    private enum ButtonLayout {
        static let height: CGFloat = 44
    }

    private enum TitleLabelLayout {
        static let height: CGFloat = Typography.titleFontSize * Typography.labelHeightModifier
    }

    private enum YearLabelLayout {
        static let height: CGFloat = Typography.yearFontSize * Typography.labelHeightModifier
    }

    private enum PosterLayout {
        static let aspectRatio: CGFloat = 2.0 / 3.0
    }

    private enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }

    private enum Typography {
        static let labelHeightModifier: CGFloat = 1.2

        static let titleFontSize: CGFloat = 16
        static let yearFontSize: CGFloat = 14

        static let titleFont = UIFont.systemFont(ofSize: titleFontSize, weight: .semibold)
        static let yearFont = UIFont.systemFont(ofSize: yearFontSize, weight: .regular)
    }

    private enum Colors {
        static let background = UIColor.secondarySystemBackground
        static let primaryText = UIColor.label
        static let secondaryText = UIColor.secondaryLabel
    }

    private enum Shadow {
        static let color = UIColor.black.cgColor
        static let offset = CGSize(width: 0, height: 2)
        static let radius: CGFloat = 4
        static let opacity: Float = 0.1
    }
}
