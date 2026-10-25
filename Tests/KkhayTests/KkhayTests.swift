import XCTest
import CryptoKit
@testable import Kkhay

final class KkhayTests: XCTestCase {
    func testClientInitialization() {
        let client = KkhayClient(apiKey: "kkhay_live_test_123")
        XCTAssertEqual(client.apiKey, "kkhay_live_test_123")
        XCTAssertEqual(client.baseURL, "https://api.kkhay.com")
        XCTAssertEqual(KkhayClient.version, "1.0.4")

        let custom = KkhayClient(apiKey: "key", baseURL: "https://gateway.internal/")
        XCTAssertEqual(custom.baseURL, "https://gateway.internal")
    }

    func testGetURL() {
        let api = KkhayClient(apiKey: "key", baseURL: "https://api.kkhay.com")
        XCTAssertEqual(api.getURL(path: "/v1/gateway/invoices")?.absoluteString, "https://api.kkhay.com/v1/gateway/invoices")
        XCTAssertEqual(api.getURL(path: "v1/gateway/invoices")?.absoluteString, "https://api.kkhay.com/v1/gateway/invoices")

        let custom = KkhayClient(apiKey: "key", baseURL: "https://gateway.internal")
        XCTAssertEqual(custom.getURL(path: "/v1/gateway/invoices")?.absoluteString, "https://gateway.internal/api/v1/gateway/invoices")
    }

    func testConstantsAndEnums() {
        XCTAssertEqual(InvoiceStatus.waiting.rawValue, "WAITING")
        XCTAssertEqual(InvoiceStatus.paid.rawValue, "PAID")
        XCTAssertEqual(InvoiceStatus.expired.rawValue, "EXPIRED")
        XCTAssertEqual(InvoiceStatus.canceled.rawValue, "CANCELED")

        XCTAssertEqual(InvoiceType.payment.rawValue, "PAYMENT")
        XCTAssertEqual(InvoiceType.donation.rawValue, "DONATION")
        XCTAssertEqual(InvoiceType.subscription.rawValue, "SUBSCRIPTION")

        XCTAssertEqual(WebhookEventType.paymentPaid.rawValue, "payment.paid")
        XCTAssertEqual(WebhookEventType.paymentFinished.rawValue, "payment.finished")
        XCTAssertEqual(WebhookEventType.paymentConfirming.rawValue, "payment.confirming")
        XCTAssertEqual(WebhookEventType.paymentFailed.rawValue, "payment.failed")
        XCTAssertEqual(WebhookEventType.invoiceCanceled.rawValue, "invoice.canceled")
    }

    func testCreateInvoiceRequestNormalization() throws {
        let req = CreateInvoiceRequest(
            amount: 49.99,
            currency: " usd ",
            payNetwork: " BSC ",
            payToken: " usdt ",
            type: .payment,
            orderId: "ORD-99"
        )

        XCTAssertEqual(req.amount, 49.99)
        XCTAssertEqual(req.priceAmount, 49.99)
        XCTAssertEqual(req.currency, "USD")
        XCTAssertEqual(req.priceCurrency, "USD")
        XCTAssertEqual(req.payNetwork, "bsc")
        XCTAssertEqual(req.payToken, "USDT")
        XCTAssertEqual(req.type, .payment)
        XCTAssertEqual(req.orderId, "ORD-99")

        let encoder = JSONEncoder()
        let data = try encoder.encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["amount"] as? Double, 49.99)
        XCTAssertEqual(json?["payNetwork"] as? String, "bsc")
        XCTAssertEqual(json?["payToken"] as? String, "USDT")
    }

    func testInvoiceDecodingWithGatewayId() throws {
        let jsonString = """
        {
            "id": "0192e2b3-5776-791b-8524-77a834164b12",
            "gatewayId": "gw_prod_001",
            "amount": 100.0,
            "currency": "USD",
            "priceAmount": 100.0,
            "priceCurrency": "USD",
            "payAmount": "100.00",
            "payToken": "USDC",
            "payNetwork": "solana",
            "depositAddress": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            "status": "WAITING",
            "feeAmount": "0",
            "netAmount": "100.00",
            "hostedUrl": "https://kkhay.com/gateway/invoice/0192e2b3-5776-791b-8524-77a834164b12",
            "expiresAt": "2026-10-26T00:00:00Z",
            "createdAt": "2026-10-25T18:00:00Z"
        }
        """
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        let invoice = try decoder.decode(Invoice.self, from: data)

        XCTAssertEqual(invoice.id, "0192e2b3-5776-791b-8524-77a834164b12")
        XCTAssertEqual(invoice.gatewayId, "gw_prod_001")
        XCTAssertEqual(invoice.amount, 100.0)
        XCTAssertEqual(invoice.currency, "USD")
        XCTAssertEqual(invoice.status, "WAITING")
        XCTAssertEqual(invoice.payNetwork, "solana")
        XCTAssertEqual(invoice.payToken, "USDC")
    }

    func testWebhookVerification() {
        let secret = "whsec_test_secret_123"
        let jsonString = """
        {"event":"payment.paid","gateway_id":"gw_123","invoice_id":"inv_123","pay_amount":"50.00","pay_token":"USDT"}
        """
        let payload = Data(jsonString.utf8)

        let key = SymmetricKey(data: Data(secret.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let signature = code.map { String(format: "%02hhx", $0) }.joined()

        // Valid Data payload
        XCTAssertTrue(KkhayWebhook.verifySignature(payload: payload, signature: signature, ipnSecret: secret))
        // Valid String payload
        XCTAssertTrue(KkhayWebhook.verifySignature(payload: jsonString, signature: signature, ipnSecret: secret))
        // Valid with whitespace around signature
        XCTAssertTrue(KkhayWebhook.verifySignature(payload: payload, signature: "  \(signature)  \n", ipnSecret: secret))

        // Tampered payload
        let tampered = Data((jsonString + "tampered").utf8)
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: tampered, signature: signature, ipnSecret: secret))

        // Wrong secret
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: payload, signature: signature, ipnSecret: "wrong_secret"))

        // Null signature
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: payload, signature: nil, ipnSecret: secret))

        // Empty signature
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: payload, signature: "", ipnSecret: secret))

        // Empty secret
        XCTAssertFalse(KkhayWebhook.verifySignature(payload: payload, signature: signature, ipnSecret: ""))
    }

    func testWebhookParsing() throws {
        let secret = "whsec_secret"
        let jsonString = """
        {
            "event": "payment.paid",
            "invoice_id": "inv_abc",
            "gateway_id": "gw_prod_777",
            "order_id": "ORD-1",
            "amount": 75.5,
            "currency": "USD",
            "price_amount": 75.5,
            "price_currency": "USD",
            "pay_amount": "75.50",
            "pay_token": "USDT",
            "pay_network": "bsc",
            "deposit_address": "0x123",
            "tx_hash": "0x987654321",
            "status": "PAID",
            "timestamp": "2026-10-25T18:00:00Z"
        }
        """
        let payload = Data(jsonString.utf8)

        let key = SymmetricKey(data: Data(secret.utf8))
        let code = HMAC<SHA256>.authenticationCode(for: payload, using: key)
        let signature = code.map { String(format: "%02hhx", $0) }.joined()

        let event = try KkhayWebhook.parseEvent(rawBody: payload, signature: signature, ipnSecret: secret)
        XCTAssertEqual(event.event, "payment.paid")
        XCTAssertEqual(event.invoiceId, "inv_abc")
        XCTAssertEqual(event.gatewayId, "gw_prod_777")
        XCTAssertEqual(event.amount, 75.5)
        XCTAssertEqual(event.currency, "USD")
        XCTAssertEqual(event.payToken, "USDT")
        XCTAssertEqual(event.status, "PAID")
        XCTAssertEqual(event.txHash, "0x987654321")

        // Throws on invalid signature
        XCTAssertThrowsError(try KkhayWebhook.parseEvent(rawBody: payload, signature: "invalid_sig", ipnSecret: secret))
    }

    func testErrorDescriptions() {
        XCTAssertEqual(KkhayError.invalidAPIKey.errorDescription, "KkhayError: A valid non-empty API key is required.")
        XCTAssertEqual(KkhayError.invalidSignature.errorDescription, "Invalid K Khay webhook signature: Request rejected")
        XCTAssertTrue(KkhayError.api(status: 404, message: "Invoice not found", code: "NOT_FOUND").errorDescription?.contains("HTTP 404") == true)
    }
}
