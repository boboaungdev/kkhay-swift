import Foundation
import CryptoKit

public enum KkhayWebhook {
    /// Verifies the HMAC-SHA256 signature sent with incoming K Khay IPN webhooks.
    public static func verifySignature(payload: Data, signature: String?, ipnSecret: String) -> Bool {
        guard let signature = signature?.trimmingCharacters(in: .whitespacesAndNewlines),
              !signature.isEmpty,
              !ipnSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        let key = SymmetricKey(data: Data(ipnSecret.trimmingCharacters(in: .whitespacesAndNewlines).utf8))
        let authenticationCode = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let expectedHex = authenticationCode.map { String(format: "%02hhx", $0) }.joined()

        // Constant time comparison
        return constantTimeCompare(expectedHex.lowercased(), signature.lowercased())
    }

    /// Validates signature and parses JSON payload into a typed WebhookEvent.
    public static func parseEvent(rawBody: Data, signature: String?, ipnSecret: String) throws -> WebhookEvent {
        guard verifySignature(payload: rawBody, signature: signature, ipnSecret: ipnSecret) else {
            throw KkhayError.invalidSignature
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WebhookEvent.self, from: rawBody)
        } catch {
            throw KkhayError.decodingError(error)
        }
    }

    private static func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        let aBytes = Array(a.utf8)
        let bBytes = Array(b.utf8)
        guard aBytes.count == bBytes.count else { return false }

        var result: UInt8 = 0
        for i in 0..<aBytes.count {
            result |= aBytes[i] ^ bBytes[i]
        }
        return result == 0
    }
}

