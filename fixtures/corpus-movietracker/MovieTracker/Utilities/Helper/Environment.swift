import Foundation

enum Environment {
    enum Keys {
        static let tmdbApiKey = "TMDB_API_KEY"
    }

    private static let infoDictionary: [String: Any] = {
        guard let dictionary = Bundle.main.infoDictionary else {
            fatalError("Info.plist not found")
        }
        return dictionary
    }()

    static let tmdbApiKey: String = {
        guard let apiKeyString = Environment.infoDictionary[Keys.tmdbApiKey] as? String else {
            fatalError("TMDB API key not found in Info.plist")
        }
        return apiKeyString
    }()
}
