import Foundation

public enum KkhayError: LocalizedError {
    case api(status: Int, message: String, code: String?)
    case network(Error)
    case invalidURL
    case invalidSignature
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .api(let status, let message, let code):
            if let code = code {
                return "KkhayError [HTTP \(status) - \(code)]: \(message)"
            }
            return "KkhayError [HTTP \(status)]: \(message)"
        case .network(let err):
            return "Network error: \(err.localizedDescription)"
        case .invalidURL:
            return "Invalid endpoint URL"
        case .invalidSignature:
            return "Invalid K Khay webhook signature: Request rejected"
        case .decodingError(let err):
            return "JSON decoding error: \(err.localizedDescription)"
        }
    }
}

