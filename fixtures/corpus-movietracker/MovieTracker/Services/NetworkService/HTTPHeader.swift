import Foundation

struct HTTPHeader {
    enum Field: String {
        case authorization = "Authorization"
        case accept
    }

    enum Value {
        case json
        case bearer(apiKey: String)

        var rawValue: String {
            switch self {
            case .json: "application/json"
            case let .bearer(apiKey): "Bearer \(apiKey)"
            }
        }
    }

    let field: Field
    let value: Value
}
