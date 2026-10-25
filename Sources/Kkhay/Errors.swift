import Foundation

public enum KkhayError: LocalizedError, Sendable {
    case invalidAPIKey
    case invalidInput(String)
    case api(status: Int, message: String, code: String?)
    case network(String)
    case invalidURL
    case invalidSignature
    case decodingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "KkhayError: A valid non-empty API key is required."
        case .invalidInput(let msg):
            return "KkhayError [Invalid Input]: \(msg)"
        case .api(let status, let message, let code):
            if let code = code {
                return "KkhayError [HTTP \(status) - \(code)]: \(message)"
            }
            return "KkhayError [HTTP \(status)]: \(message)"
        case .network(let err):
            return "Network error: \(err)"
        case .invalidURL:
            return "Invalid endpoint URL"
        case .invalidSignature:
            return "Invalid K Khay webhook signature: Request rejected"
        case .decodingError(let err):
            return "JSON decoding error: \(err)"
        }
    }
}
