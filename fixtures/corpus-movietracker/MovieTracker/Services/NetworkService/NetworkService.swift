import Foundation

/// Protocol defining a service for performing network requests.
protocol NetworkServiceProtocol {
    /// Sends a request and decodes the response into a `Codable` type.
    func request<T: Codable>(
        endpoint: String,
        type: T.Type,
        method: HTTPMethod,
        headers: [HTTPHeader]?
    ) async throws -> T

    /// Loads raw data from a URL string.
    func loadData(
        from urlString: String,
        headers: [HTTPHeader]?
    ) async throws -> Data
}

/// A concrete implementation of `NetworkServiceProtocol` using `URLSession`.
final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()

    /// Sends a request and decodes the response into a `Codable` type.
    func request<T: Codable>(
        endpoint: String,
        type: T.Type = T.self,
        method: HTTPMethod = .get,
        headers: [HTTPHeader]? = nil
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let headers {
            for header in headers {
                request.setValue(header.value.rawValue, forHTTPHeaderField: header.field.rawValue)
            }
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.networkUnavailable
        }

        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        try NetworkService.checkResponse(httpResponse)

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }

    /// Loads raw data from a URL string.
    func loadData(
        from urlString: String,
        headers: [HTTPHeader]? = nil
    ) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)

        if let headers {
            for header in headers {
                request.setValue(header.value.rawValue, forHTTPHeaderField: header.field.rawValue)
            }
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw NetworkError.networkUnavailable
        }

        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        try NetworkService.checkResponse(httpResponse)

        return data
    }

    /// Checks HTTP response status codes and throws a respective `NetworkError` if necessary.
    private static func checkResponse(_ httpResponse: HTTPURLResponse) throws {
        switch httpResponse.statusCode {
        case 200 ... 299:
            break
        case 400:
            throw NetworkError.badRequest
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500 ... 599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }
    }
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case badRequest // 400
    case unauthorized // 401
    case forbidden // 403
    case notFound // 404
    case serverError(Int) // 500+
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("invalid_url_error_description", comment: "Invalid URL error")
        case .noData:
            return NSLocalizedString("no_data_error_description", comment: "No data error")
        case .decodingError:
            return NSLocalizedString("decoding_error_description", comment: "Decoding error")
        case .badRequest:
            return NSLocalizedString("bad_request_error_description", comment: "400 error")
        case .unauthorized:
            return NSLocalizedString("unauthorized_error_description", comment: "401 error")
        case .forbidden:
            return NSLocalizedString("forbidden_error_description", comment: "403 error")
        case .notFound:
            return NSLocalizedString("not_found_error_description", comment: "404 error")
        case let .serverError(code):
            let format = NSLocalizedString("server_error_description", comment: "Server error with code")
            return String(format: format, code)
        case .networkUnavailable:
            return NSLocalizedString("network_unavailable_error_description", comment: "Network error")
        }
    }
}
