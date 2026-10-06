import Foundation

public final class KkhayClient: Sendable {
    public let apiKey: String
    public let baseURL: String
    public let session: URLSession

    public init(
        apiKey: String,
        baseURL: String = "https://api.kkhay.com",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.session = session
    }

    private func getURL(path: String) -> URL? {
        let cleanPath = path.hasPrefix("/") ? path : "/\(path)"
        let fullPath: String
        if baseURL.hasSuffix("/api") || baseURL.contains("api.") {
            fullPath = "\(baseURL)\(cleanPath)"
        } else {
            fullPath = "\(baseURL)/api\(cleanPath)"
        }
        return URL(string: fullPath)
    }

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        guard let url = getURL(path: path) else {
            throw KkhayError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("kkhay-swift/1.0.0", forHTTPHeaderField: "User-Agent")

        if let body = body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = body
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw KkhayError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KkhayError.api(status: 500, message: "Invalid server response", code: nil)
        }

        if httpResponse.statusCode >= 400 {
            var message = "Request failed with status \(httpResponse.statusCode)"
            var code: String? = nil

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let msg = json["message"] as? String ?? json["error"] as? String {
                    message = msg
                }
                code = json["code"] as? String
            }

            throw KkhayError.api(status: httpResponse.statusCode, message: message, code: code)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw KkhayError.decodingError(error)
        }
    }

    /// Create a new crypto invoice.
    public func createInvoice(_ request: CreateInvoiceRequest) async throws -> CreateInvoiceResponse {
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        return try await self.request(path: "/v1/merchant/invoices", method: "POST", body: data)
    }

    /// Retrieve an invoice and its blockchain payments by ID.
    public func getInvoice(id: String) async throws -> GetInvoiceResponse {
        let cleanId = id.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await self.request(path: "/v1/merchant/invoices/\(cleanId)", method: "GET")
    }

    /// List merchant invoices with optional pagination.
    public func listInvoices(page: Int = 1, limit: Int = 20, status: String? = nil) async throws -> ListInvoicesResponse {
        var components = URLComponents(string: "/v1/merchant/invoices")
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        components?.queryItems = queryItems
        let path = components?.string ?? "/v1/merchant/invoices"

        return try await self.request(path: path, method: "GET")
    }
}

