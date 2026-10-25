import Foundation

/// Status of a K Khay invoice matching the PostgreSQL gateway_invoice_status enum.
public enum InvoiceStatus: String, Codable, Sendable {
    case waiting = "WAITING"
    case paid = "PAID"
    case expired = "EXPIRED"
    case canceled = "CANCELED"
}

/// Type of invoice matching the PostgreSQL gateway_invoice_type enum.
public enum InvoiceType: String, Codable, Sendable {
    case payment = "PAYMENT"
    case donation = "DONATION"
    case subscription = "SUBSCRIPTION"
}

/// Webhook event types dispatched by K Khay IPN webhooks.
public enum WebhookEventType: String, Codable, Sendable {
    case paymentPaid = "payment.paid"
    case paymentFinished = "payment.finished"
    case paymentConfirming = "payment.confirming"
    case paymentFailed = "payment.failed"
    case invoiceCanceled = "invoice.canceled"
}

/// Request parameters to generate a new crypto payment invoice.
public struct CreateInvoiceRequest: Codable, Sendable {
    public let amount: Double
    public let priceAmount: Double
    public let currency: String
    public let priceCurrency: String
    public let payNetwork: String
    public let payToken: String
    public let type: InvoiceType
    public let orderId: String?
    public let title: String?
    public let customerName: String?
    public let customerEmail: String?
    public let redirectUrl: String?
    public let cancelUrl: String?
    public let ipnCallbackUrl: String?

    public init(
        amount: Double? = nil,
        priceAmount: Double? = nil,
        currency: String? = nil,
        priceCurrency: String? = "USD",
        payNetwork: String,
        payToken: String,
        type: InvoiceType = .payment,
        orderId: String? = nil,
        title: String? = nil,
        customerName: String? = nil,
        customerEmail: String? = nil,
        redirectUrl: String? = nil,
        cancelUrl: String? = nil,
        ipnCallbackUrl: String? = nil
    ) {
        let amt = amount ?? priceAmount ?? 0.0
        let cur = (currency ?? priceCurrency ?? "USD").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        self.amount = amt
        self.priceAmount = amt
        self.currency = cur
        self.priceCurrency = cur
        self.payNetwork = payNetwork.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.payToken = payToken.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.type = type
        self.orderId = orderId
        self.title = title
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.redirectUrl = redirectUrl
        self.cancelUrl = cancelUrl
        self.ipnCallbackUrl = ipnCallbackUrl
    }
}

/// Model representing a sovereign K Khay payment invoice.
public struct Invoice: Codable, Sendable {
    public let id: String
    public let gatewayId: String
    public let amount: Double
    public let currency: String
    public let priceAmount: Double
    public let priceCurrency: String
    public let payAmount: String
    public let payToken: String
    public let payNetwork: String
    public let depositAddress: String
    public let status: String
    public let feeAmount: String
    public let netAmount: String
    public let hostedUrl: String
    public let expiresAt: String
    public let createdAt: String
    public let type: String?
    public let orderId: String?
    public let title: String?
    public let customerName: String?
    public let customerEmail: String?
    public let settlementMode: String?
    public let paymentMethod: String?
    public let payoutAddress: String?
    public let redirectUrl: String?
    public let cancelUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case gatewayId
        case gateway_id
        case amount
        case currency
        case priceAmount
        case priceCurrency
        case payAmount
        case payToken
        case payNetwork
        case depositAddress
        case status
        case feeAmount
        case netAmount
        case hostedUrl
        case expiresAt
        case createdAt
        case type
        case orderId
        case title
        case customerName
        case customerEmail
        case settlementMode
        case paymentMethod
        case payoutAddress
        case redirectUrl
        case cancelUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        gatewayId = try container.decodeIfPresent(String.self, forKey: .gatewayId)
            ?? container.decodeIfPresent(String.self, forKey: .gateway_id)
            ?? ""

        let decodedPriceAmount = try container.decodeIfPresent(Double.self, forKey: .priceAmount)
        let decodedAmount = try container.decodeIfPresent(Double.self, forKey: .amount)
        let resolvedAmount = decodedAmount ?? decodedPriceAmount ?? 0.0

        let decodedPriceCurrency = try container.decodeIfPresent(String.self, forKey: .priceCurrency)
        let decodedCurrency = try container.decodeIfPresent(String.self, forKey: .currency)
        let resolvedCurrency = decodedCurrency ?? decodedPriceCurrency ?? "USD"

        amount = resolvedAmount
        priceAmount = resolvedAmount
        currency = resolvedCurrency
        priceCurrency = resolvedCurrency

        payAmount = try container.decodeIfPresent(String.self, forKey: .payAmount) ?? "0"
        payToken = try container.decodeIfPresent(String.self, forKey: .payToken) ?? ""
        payNetwork = try container.decodeIfPresent(String.self, forKey: .payNetwork) ?? ""
        depositAddress = try container.decodeIfPresent(String.self, forKey: .depositAddress) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? InvoiceStatus.waiting.rawValue
        feeAmount = try container.decodeIfPresent(String.self, forKey: .feeAmount) ?? "0"
        netAmount = try container.decodeIfPresent(String.self, forKey: .netAmount) ?? "0"
        hostedUrl = try container.decodeIfPresent(String.self, forKey: .hostedUrl) ?? ""
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt) ?? ""
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""

        type = try container.decodeIfPresent(String.self, forKey: .type)
        orderId = try container.decodeIfPresent(String.self, forKey: .orderId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        customerName = try container.decodeIfPresent(String.self, forKey: .customerName)
        customerEmail = try container.decodeIfPresent(String.self, forKey: .customerEmail)
        settlementMode = try container.decodeIfPresent(String.self, forKey: .settlementMode)
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod)
        payoutAddress = try container.decodeIfPresent(String.self, forKey: .payoutAddress)
        redirectUrl = try container.decodeIfPresent(String.self, forKey: .redirectUrl)
        cancelUrl = try container.decodeIfPresent(String.self, forKey: .cancelUrl)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gatewayId, forKey: .gatewayId)
        try container.encode(amount, forKey: .amount)
        try container.encode(currency, forKey: .currency)
        try container.encode(priceAmount, forKey: .priceAmount)
        try container.encode(priceCurrency, forKey: .priceCurrency)
        try container.encode(payAmount, forKey: .payAmount)
        try container.encode(payToken, forKey: .payToken)
        try container.encode(payNetwork, forKey: .payNetwork)
        try container.encode(depositAddress, forKey: .depositAddress)
        try container.encode(status, forKey: .status)
        try container.encode(feeAmount, forKey: .feeAmount)
        try container.encode(netAmount, forKey: .netAmount)
        try container.encode(hostedUrl, forKey: .hostedUrl)
        try container.encode(expiresAt, forKey: .expiresAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(orderId, forKey: .orderId)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(customerName, forKey: .customerName)
        try container.encodeIfPresent(customerEmail, forKey: .customerEmail)
        try container.encodeIfPresent(settlementMode, forKey: .settlementMode)
        try container.encodeIfPresent(paymentMethod, forKey: .paymentMethod)
        try container.encodeIfPresent(payoutAddress, forKey: .payoutAddress)
        try container.encodeIfPresent(redirectUrl, forKey: .redirectUrl)
        try container.encodeIfPresent(cancelUrl, forKey: .cancelUrl)
    }
}

/// Blockchain transaction payment record.
public struct PaymentRecord: Codable, Sendable {
    public let id: String
    public let txHash: String
    public let amountReceived: String
    public let confirmations: Int
    public let status: String
    public let forwardedTxHash: String?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case txHash
        case tx_hash
        case amountReceived
        case amount_received
        case confirmations
        case status
        case forwardedTxHash
        case forwarded_tx_hash
        case createdAt
        case created_at
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        txHash = try container.decodeIfPresent(String.self, forKey: .txHash)
            ?? container.decodeIfPresent(String.self, forKey: .tx_hash)
            ?? ""
        amountReceived = try container.decodeIfPresent(String.self, forKey: .amountReceived)
            ?? container.decodeIfPresent(String.self, forKey: .amount_received)
            ?? "0"
        confirmations = try container.decodeIfPresent(Int.self, forKey: .confirmations) ?? 0
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        forwardedTxHash = try container.decodeIfPresent(String.self, forKey: .forwardedTxHash)
            ?? container.decodeIfPresent(String.self, forKey: .forwarded_tx_hash)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
            ?? container.decodeIfPresent(String.self, forKey: .created_at)
            ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(txHash, forKey: .txHash)
        try container.encode(amountReceived, forKey: .amountReceived)
        try container.encode(confirmations, forKey: .confirmations)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(forwardedTxHash, forKey: .forwardedTxHash)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

public struct CreateInvoiceResponse: Codable, Sendable {
    public let ok: Bool
    public let invoice: Invoice
}

public struct GetInvoiceResponse: Codable, Sendable {
    public let ok: Bool
    public let invoice: Invoice
    public let payments: [PaymentRecord]
}

public struct ListInvoicesResponse: Codable, Sendable {
    public let ok: Bool
    public let items: [Invoice]
    public let totalCount: Int
    public let totalPages: Int
    public let currentPage: Int
    public let limit: Int
}

public struct HealthResponse: Codable, Sendable {
    public let status: String
}

/// Instant Payment Notification (IPN) webhook payload.
public struct WebhookEvent: Codable, Sendable {
    public let event: String
    public let invoiceId: String
    public let gatewayId: String?
    public let amount: Double
    public let currency: String
    public let priceAmount: Double
    public let priceCurrency: String
    public let orderId: String?
    public let payAmount: String
    public let payToken: String
    public let payNetwork: String
    public let depositAddress: String
    public let txHash: String?
    public let status: String
    public let timestamp: String

    enum CodingKeys: String, CodingKey {
        case event
        case invoiceId = "invoice_id"
        case gatewayId = "gateway_id"
        case amount
        case currency
        case priceAmount = "price_amount"
        case priceCurrency = "price_currency"
        case orderId = "order_id"
        case payAmount = "pay_amount"
        case payToken = "pay_token"
        case payNetwork = "pay_network"
        case depositAddress = "deposit_address"
        case txHash = "tx_hash"
        case status
        case timestamp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(String.self, forKey: .event)
        invoiceId = try container.decode(String.self, forKey: .invoiceId)
        gatewayId = try container.decodeIfPresent(String.self, forKey: .gatewayId)

        let decodedPriceAmount = try container.decodeIfPresent(Double.self, forKey: .priceAmount)
        let decodedAmount = try container.decodeIfPresent(Double.self, forKey: .amount)
        let resolvedAmount = decodedAmount ?? decodedPriceAmount ?? 0.0

        let decodedPriceCurrency = try container.decodeIfPresent(String.self, forKey: .priceCurrency)
        let decodedCurrency = try container.decodeIfPresent(String.self, forKey: .currency)
        let resolvedCurrency = (decodedCurrency ?? decodedPriceCurrency ?? "USD").uppercased()

        amount = resolvedAmount
        priceAmount = resolvedAmount
        currency = resolvedCurrency
        priceCurrency = resolvedCurrency

        orderId = try container.decodeIfPresent(String.self, forKey: .orderId)
        payAmount = try container.decodeIfPresent(String.self, forKey: .payAmount) ?? "0"
        payToken = try container.decodeIfPresent(String.self, forKey: .payToken) ?? ""
        payNetwork = try container.decodeIfPresent(String.self, forKey: .payNetwork) ?? ""
        depositAddress = try container.decodeIfPresent(String.self, forKey: .depositAddress) ?? ""
        txHash = try container.decodeIfPresent(String.self, forKey: .txHash)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? InvoiceStatus.waiting.rawValue
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp) ?? ""
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encode(invoiceId, forKey: .invoiceId)
        try container.encodeIfPresent(gatewayId, forKey: .gatewayId)
        try container.encode(amount, forKey: .amount)
        try container.encode(currency, forKey: .currency)
        try container.encode(priceAmount, forKey: .priceAmount)
        try container.encode(priceCurrency, forKey: .priceCurrency)
        try container.encodeIfPresent(orderId, forKey: .orderId)
        try container.encode(payAmount, forKey: .payAmount)
        try container.encode(payToken, forKey: .payToken)
        try container.encode(payNetwork, forKey: .payNetwork)
        try container.encode(depositAddress, forKey: .depositAddress)
        try container.encodeIfPresent(txHash, forKey: .txHash)
        try container.encode(status, forKey: .status)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
