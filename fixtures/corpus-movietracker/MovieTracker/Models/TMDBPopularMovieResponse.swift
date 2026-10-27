import Foundation

/// Structure representing TMDB API response for "popular movies" request.
struct TMDBPopularMovieResponse: Codable {
    let page: Int
    let results: [PopularMovie]
    let totalPages: Int
    let totalResults: Int

    // MARK: - Coding

    private enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
