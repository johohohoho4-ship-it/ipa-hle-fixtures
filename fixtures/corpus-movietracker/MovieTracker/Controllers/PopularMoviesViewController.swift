import UIKit

final class PopularMoviesViewController: UIViewController {
    private var isLoading = false
    private var nextPage: Int = 1
    private var totalPages: Int = 1
    private var movies: [PopularMovie] = []
    private var fetchTask: Task<Void, Never>?
    private var dataSource: DataSource?

    // MARK: - UI Components

    private lazy var collectionView: UICollectionView = {
        let layout = makeCollectionLayout()
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(PopularMovieCell.self, forCellWithReuseIdentifier: PopularMovieCell.identifier)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    // MARK: - Initialization

    init() {
        super.init(nibName: nil, bundle: nil)
        title = NSLocalizedString("popular_movies_screen_title", comment: "Popular movies screen title")
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented.")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        configureDataSource()
        fetchData()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeCollectionLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Layout.spacing
        layout.minimumInteritemSpacing = Layout.spacing

        let insets = UIEdgeInsets(
            top: Layout.padding,
            left: Layout.padding,
            bottom: Layout.padding,
            right: Layout.padding
        )
        layout.sectionInset = insets

        let totalHorizontalSpacing = insets.left + insets.right + Layout.spacing * CGFloat(Layout.columnCount - 1)
        let itemWidth = (UIScreen.main.bounds.width - totalHorizontalSpacing) / CGFloat(Layout.columnCount)
        layout.itemSize = CGSize(width: itemWidth, height: PopularMovieCell.cellHeight(for: itemWidth))

        return layout
    }

    // MARK: - Data Fetching

    private func fetchData() {
        guard nextPage <= totalPages, !isLoading else { return }

        isLoading = true
        fetchTask?.cancel()

        fetchTask = Task { [weak self] in
            guard let self else { return }
            defer { isLoading = false }

            do {
                let response = try await TMDBService.shared.fetchPopularMovies(page: nextPage)
                guard !Task.isCancelled else { return }
                handleResponse(response)
            } catch {
                presentErrorAlert(for: error)
            }
        }
    }

    private func handleResponse(_ response: TMDBPopularMovieResponse) {
        nextPage = response.page + 1
        totalPages = response.totalPages

        let existingIds = Set(movies.map(\.id))
        let uniqueNewMovies = response.results.filter { !existingIds.contains($0.id) }
        movies.append(contentsOf: uniqueNewMovies)

        updateSnapshot()
    }
}

// MARK: - Diffable DataSource

extension PopularMoviesViewController {
    enum Section { case main }

    typealias DataSource = UICollectionViewDiffableDataSource<Section, PopularMovie>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PopularMovie>

    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, movie in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PopularMovieCell.identifier,
                for: indexPath
            ) as? PopularMovieCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: movie)
            return cell
        })
    }

    private func updateSnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(movies)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - UICollectionViewDelegate

extension PopularMoviesViewController: UICollectionViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate _: Bool) {
        let hasMorePages = nextPage <= totalPages
        guard hasMorePages, !isLoading else { return }

        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        if offsetY > contentHeight - height * 2 {
            fetchData()
        }
    }
}

// MARK: - Design System Constants

extension PopularMoviesViewController {
    private enum Layout {
        static let padding: CGFloat = 12
        static let spacing: CGFloat = 12
        static let columnCount: Int = 2
    }
}
