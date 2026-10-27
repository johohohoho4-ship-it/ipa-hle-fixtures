import UIKit

/// A protocol defining an interface for fetching movie data and images from TMDB (The Movie Database).
protocol TMDBServiceProtocol {
    /// Fetches a paginated list of popular movies from TMDB.
    func fetchPopularMovies(page: Int) async throws -> TMDBPopularMovieResponse

    /// Fetches a movie-related image from TMDB.
    func fetchImage(from path: String, size: TMDBImageSize) async -> UIImage?
}

/// A service responsible for communicating with TMDB (The Movie Database) API.
final class TMDBService: TMDBServiceProtocol {
    static let shared = TMDBService()

    private static let apiKey = Environment.tmdbApiKey

    private static let headers: [HTTPHeader] = [
        .init(field: .authorization, value: .bearer(apiKey: apiKey)),
        .init(field: .accept, value: .json)
    ]

    /// Fetches a paginated list of popular movies from TMDB.
    func fetchPopularMovies(page: Int = 1) async throws -> TMDBPopularMovieResponse {
        let endpoint = Endpoint.MovieList.popular(page: page)
        return try await NetworkService.shared.request(
            endpoint: endpoint,
            headers: TMDBService.headers
        )
    }

    /// Fetches a movie-related image from TMDB’s image CDN.
    func fetchImage(from path: String, size: TMDBImageSize = .original) async -> UIImage? {
        let endpoint = Endpoint.Image.get(from: path, size: size)
        return await ImageService.shared.loadImage(from: endpoint)
    }
}

// swiftlint:disable nesting
extension TMDBService {
    /// Represents HTTP endpoints for `TMDBService`.
    private enum Endpoint {
        private static let baseUrl = "https://api.themoviedb.org/3"

        enum MovieList {
            static let base = "\(baseUrl)/movie"

            static func popular(page: Int) -> String {
                "\(base)/popular?language=\(Locale.current.bcp47Identifier)&page=\(page)"
            }
        }

        enum Image {
            static let base = "https://image.tmdb.org/t/p"

            static func get(from path: String, size: TMDBImageSize = .original) -> String {
                "\(base)/\(size.rawValue)\(path)"
            }
        }
    }
}

// swiftlint:enable nesting

/// Represents the available TMDB image sizes.
enum TMDBImageSize: String {
    case w92, w154, w185, w342, w500, w780, original
}
