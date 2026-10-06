import XCTest
import CryptoKit
@testable import Kkhay

final class KkhayTests: XCTestCase {
    func testClientInitialization() {
        let client = KkhayClient(apiKey: "kkhay_live_test_123")
        XCTAssertEqual(client.apiKey, "kkhay_live_test_123")
        XCTAssertEqual(client.baseURL, "https://api.kkhay.com")
    }

    func testWebhookVerification() {
        let secret = "whsec_test_secret_123"
        let jsonString = """
        {"event":"payment.finished","invoice_id":"inv_123","pay_amount":"50.00","pay_token":"USDT"}
        """
        let payload = Data(jsonString.utf8)

        let key = SymmetricKey(data: Data(secret.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let signature = code.map { String(format: "%02hhx", $0) }.joined()

        // Valid
        XCTAssertTrue(KkhayWebhook.verifySignature(payload: payload, signature: signature, ipnSecret: secret))

        // Tampered
        let tampered = Data((jsonString + "tampered").utf8)
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: tampered, signature: signature, ipnSecret: secret))

        // Wrong secret
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: payload, signature: signature, ipnSecret: "wrong_secret"))

        // Null signature
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: payload, signature: nil, ipnSecret: secret))
    }

    func testWebhookParsing() throws {
        let secret = "whsec_secret"
        let jsonString = """
        {
            "event": "payment.finished",
            "invoice_id": "inv_abc",
            "order_id": "ORD-1",
            "price_amount": 50.0,
            "price_currency": "USD",
            "pay_amount": "50.00",
            "pay_token": "USDT",
            "pay_network": "bsc",
            "deposit_address": "0x123",
            "status": "paid",
            "timestamp": "2026-10-07T00:00:00Z"
        }
        """
        let payload = Data(jsonString.utf8)

        let key = SymmetricKey(data: Data(secret.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let signature = code.map { String(format: "%02hhx", $0) }.joined()

        let event = try KkhayWebhook.parseEvent(rawBody: payload, signature: signature, ipnSecret: secret)
        XCTAssertEqual(event.event, "payment.finished")
        XCTAssertEqual(event.invoiceId, "inv_abc")
        XCTAssertEqual(event.payToken, "USDT")
    }
}

