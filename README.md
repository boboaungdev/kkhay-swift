<div align="center">

# `kkhay-swift`

**Official Swift Package for K Khay — The Non-Custodial Crypto Payment Gateway**

[![Swift](https://img.shields.io/badge/Swift-5.7+-FA7343.svg?style=flat-square&logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2014+%20%7C%20macOS%2011+%20%7C%20watchOS%207+%20%7C%20tvOS%2014+-blue.svg?style=flat-square)](https://developer.apple.com/swift/)
[![CI](https://github.com/boboaungdev/kkhay-swift/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/boboaungdev/kkhay-swift/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)

Accept cryptocurrency payments across **190+ blockchain networks** and **500+ tokens** (EVM, Bitcoin, Solana, TON, Tron, and XRPL) with **zero custody** and automatic direct-to-wallet settlement. Works natively with **SwiftUI, UIKit, AppKit, and Vapor** using modern `async/await` and Apple `CryptoKit`.

[Gateway Dashboard](https://gateway.kkhay.com) • [API Keys](https://gateway.kkhay.com/dashboard/keys) • [Website](https://kkhay.com)

</div>

---

## ⚡ Key Highlights

- 🛡️ **100% Non-Custodial**: Payments settle directly to your destination blockchain address in seconds. K Khay never holds your private keys or customer funds.
- 🌐 **190+ Networks Supported**: 
  - **EVM Networks**: BNB Smart Chain (`bsc`), Polygon (`polygon`), Arbitrum (`arbitrum`), Base (`base`), Ethereum (`eth`), Optimism (`optimism`), Avalanche (`avalanche`), and 180+ more.
  - **UTXO Networks**: Bitcoin (`btc`), Dogecoin (`doge`), Litecoin (`ltc`), Bitcoin Cash (`bch`).
  - **High-Throughput Chains**: Solana (`sol`), TON (`ton`), Tron (`trx`), XRP Ledger (`xrp`).
- 🪙 **500+ Cryptocurrencies**: Native coins and tokens (USDT, USDC, BTC, ETH, SOL, TON, BNB, DOGE, XRP, TRX, LTC, and more).
- 🔗 **Branded Hosted Checkouts**: Instant hosted checkout URLs with dynamic QR codes, live blockchain polling, and wallet deep links (`UIApplication.shared.open(url)`).
- 🔔 **Cryptographic Webhooks**: Timing-safe HMAC-SHA256 signature verification via Apple `CryptoKit`.
- 🪶 **Zero External Dependencies**: Pure Swift implementation using only Apple system frameworks (`Foundation`, `CryptoKit`).
- ⚡ **Swift Concurrency Ready**: Modern `async/await` architecture with full `Sendable` compliance across all types.

---

## 📦 Installation (Swift Package Manager)

### In Xcode

1. Go to **File** > **Add Package Dependencies...**
2. Enter the repository URL:
   ```text
   https://github.com/boboaungdev/kkhay-swift.git
   ```
3. Set the Dependency Rule to **Up to Next Major Version** starting from `1.0.4`.

### In `Package.swift`

Add `Kkhay` to your package dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/boboaungdev/kkhay-swift.git", from: "1.0.4")
]
```

And add `Kkhay` to your target dependencies:

```swift
.target(
    name: "MyTarget",
    dependencies: [
        .product(name: "Kkhay", package: "kkhay-swift")
    ]
)
```

---

## 🚀 Quickstart

### 1. Initialize the Client

Obtain your API Key from the [K Khay Gateway Dashboard](https://gateway.kkhay.com/dashboard/keys).

```swift
import Kkhay

let client = KkhayClient(apiKey: "kkhay_live_your_api_key_here")
```

Custom base URL and URLSession configuration can also be specified:

```swift
let client = KkhayClient(
    apiKey: "kkhay_live_your_api_key_here",
    baseURL: "https://api.kkhay.com",
    session: .shared
)
```

---

### 2. Create a Crypto Payment Invoice

```swift
import Kkhay

let request = CreateInvoiceRequest(
    amount: 49.99,
    currency: "USD",
    payNetwork: "bsc",       // or "polygon", "solana", "bitcoin", "tron", etc.
    payToken: "USDT",        // or "USDC", "BTC", "ETH", "SOL", "TON", etc.
    type: .payment,
    orderId: "IOS-8821",
    title: "Pro Tier Membership",
    customerEmail: "customer@example.com",
    redirectUrl: "myapp://payment-complete",
    cancelUrl: "myapp://cart"
)

do {
    let response = try await client.createInvoice(request)
    let invoice = response.invoice
    
    print("Invoice ID: \(invoice.id)")
    print("Deposit Address: \(invoice.depositAddress)")
    print("Checkout URL: \(invoice.hostedUrl)")
    
    // Open in Safari or SafariServices
    if let url = URL(string: invoice.hostedUrl) {
        #if canImport(UIKit)
        await UIApplication.shared.open(url)
        #endif
    }
} catch {
    print("Invoice creation failed: \(error)")
}
```

---

### 3. Query Invoice Status & Confirmations

```swift
do {
    let response = try await client.getInvoice(id: "0192e2b3-5776-791b-8524-77a834164b12")
    let invoice = response.invoice
    
    print("Status: \(invoice.status)") // WAITING, PAID, EXPIRED, CANCELED
    
    for payment in response.payments {
        print("Received \(payment.amountReceived) on tx \(payment.txHash)")
        print("Confirmations: \(payment.confirmations)")
    }
} catch {
    print("Failed to query invoice: \(error)")
}
```

---

### 4. List & Paginate Invoices

```swift
do {
    let result = try await client.listInvoices(
        page: 1,
        limit: 20,
        status: InvoiceStatus.paid.rawValue
    )
    
    print("Total settled: \(result.totalCount)")
    for inv in result.items {
        print("- \(inv.id): $\(inv.amount) \(inv.currency) (\(inv.status))")
    }
} catch {
    print("Failed to list invoices: \(error)")
}
```

---

### 5. Check API Health

```swift
let health = try await client.checkHealth()
print("Gateway API Status: \(health.status)")
```

---

## 🔐 Webhook / IPN Verification (Vapor Example)

K Khay cryptographically signs incoming webhook notifications with an HMAC-SHA256 signature passed in the `x-kkhay-signature` HTTP header.

```swift
import Vapor
import Kkhay

func routes(_ app: Application) throws {
    app.post("api", "webhooks", "kkhay") { req async throws -> HTTPStatus in
        guard let signature = req.headers.first(name: "x-kkhay-signature"),
              let bodyBuffer = req.body.data else {
            throw Abort(.badRequest)
        }

        let rawBytes = Data(bodyBuffer.readableBytesView)
        let ipnSecret = Environment.get("KKHAY_IPN_SECRET") ?? "whsec_your_secret_key"

        do {
            let event = try KkhayWebhook.parseEvent(
                rawBody: rawBytes,
                signature: signature,
                ipnSecret: ipnSecret
            )

            switch event.event {
            case WebhookEventType.paymentPaid.rawValue, WebhookEventType.paymentFinished.rawValue:
                print("Payment received for order \(event.orderId ?? "")!")
                print("Transaction Hash: \(event.txHash ?? "")")
                // Fulfill order in database
            default:
                break
            }

            return .ok
        } catch {
            return .unauthorized
        }
    }
}
```

---

## 📚 Constants & Enums

### Invoice Status (`InvoiceStatus`)

Matches PostgreSQL schema enum values:

| Enum Case | Raw Value | Description |
| :--- | :--- | :--- |
| `InvoiceStatus.waiting` | `'WAITING'` | Awaiting customer payment on blockchain |
| `InvoiceStatus.paid` | `'PAID'` | Transaction confirmed and settled |
| `InvoiceStatus.expired` | `'EXPIRED'` | Payment window closed without full payment |
| `InvoiceStatus.canceled` | `'CANCELED'` | Invoice explicitly voided or canceled |

### Invoice Type (`InvoiceType`)

| Enum Case | Raw Value | Description |
| :--- | :--- | :--- |
| `InvoiceType.payment` | `'PAYMENT'` | Standard e-commerce payment |
| `InvoiceType.donation` | `'DONATION'` | Open-amount contribution |
| `InvoiceType.subscription` | `'SUBSCRIPTION'` | Recurring subscription billing |

### Webhook Event Types (`WebhookEventType`)

| Enum Case | Raw Value | Description |
| :--- | :--- | :--- |
| `WebhookEventType.paymentPaid` | `'payment.paid'` | Payment confirmed on blockchain |
| `WebhookEventType.paymentFinished` | `'payment.finished'` | Invoice completed and finalized |
| `WebhookEventType.paymentConfirming` | `'payment.confirming'` | Transaction detected, awaiting confirmations |
| `WebhookEventType.paymentFailed` | `'payment.failed'` | Transaction failed on-chain |
| `WebhookEventType.invoiceCanceled` | `'invoice.canceled'` | Invoice was canceled |

---

## 🌐 Supported Blockchains (190+ Networks)

| Network | Code | Type | Popular Tokens |
| :--- | :--- | :--- | :--- |
| **BNB Smart Chain** | `bsc` | EVM | USDT, USDC, BNB, DAI |
| **Polygon** | `polygon` | EVM | USDT, USDC, POL, WETH |
| **Arbitrum One** | `arbitrum` | EVM (L2) | USDT, USDC, ARB, ETH |
| **Base** | `base` | EVM (L2) | USDC, ETH, DAI |
| **Ethereum** | `eth` | EVM (L1) | USDT, USDC, ETH, DAI |
| **Solana** | `solana` / `sol` | High-Throughput | SOL, USDT, USDC |
| **TON Network** | `ton` | High-Throughput | TON, USDT |
| **Tron** | `tron` / `trx` | TRC-20 | TRX, USDT, USDC |
| **Bitcoin** | `bitcoin` / `btc`| UTXO | BTC |
| **XRP Ledger** | `xrpl` / `xrp` | Ledger | XRP |
| **Dogecoin** | `dogecoin` / `doge`| UTXO | DOGE |
| **Litecoin** | `litecoin` / `ltc` | UTXO | LTC |

*And 180+ additional networks dynamically routed through K Khay.*

---

## 📄 License

MIT © [K Khay](https://kkhay.com)
