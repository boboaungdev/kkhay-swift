# K Khay Swift SDK 🍎

Official Swift Package for the **[K Khay Sovereign Crypto Payment Gateway](https://kkhay.com)**.

Accept crypto payments (USDT, USDC, BNB, ETH on BSC, Polygon, Arbitrum, Base, Ethereum) in **iOS, macOS, watchOS, and tvOS apps** with async/await and CryptoKit.

---

## 📦 Installation (Swift Package Manager)

In Xcode:
1. Go to **File** > **Add Packages...**
2. Enter repository URL: `https://github.com/boboaungdev/kkhay-swift`
3. Select version `1.0.0` or `Up to Next Major`

Or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/boboaungdev/kkhay-swift.git", from: "1.0.0")
]
```

---

## ⚡ Quick Start

```swift
import Kkhay

let client = KkhayClient(apiKey: "kkhay_live_your_api_key_here")

let request = CreateInvoiceRequest(
    priceAmount: 49.99,
    priceCurrency: "USD",
    payNetwork: "bsc",
    payToken: "USDT",
    orderId: "IOS-8812",
    title: "Pro Subscription",
    redirectUrl: "myapp://payment-complete"
)

do {
    let response = try await client.createInvoice(request)
    print("Invoice ID: \(response.invoice.id)")
    print("Checkout URL: \(response.invoice.hostedUrl)")
} catch {
    print("Failed to create invoice: \(error)")
}
```

---

## 🔐 Webhook / IPN Verification (Vapor Example)

```swift
import Vapor
import Kkhay

func routes(_ app: Application) throws {
    app.post("api", "webhooks", "kkhay") { req async throws -> HTTPStatus in
        guard let signature = req.headers.first(name: "x-kkhay-signature"),
              let bodyData = req.body.data else {
            throw Abort(.badRequest)
        }

        let ipnSecret = Environment.get("KKHAY_IPN_SECRET") ?? ""
        
        do {
            let event = try KkhayWebhook.parseEvent(
                rawBody: Data(bodyData.readableBytesView),
                signature: signature,
                ipnSecret: ipnSecret
            )
            
            if event.event == "payment.finished" {
                print("Paid! Tx: \(event.txHash ?? "")")
            }
            return .ok
        } catch {
            return .unauthorized
        }
    }
}
```

---

## 📄 License

MIT © [K Khay](https://kkhay.com)

