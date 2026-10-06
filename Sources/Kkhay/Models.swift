import Foundation

public struct CreateInvoiceRequest: Codable, Sendable {
    public let priceAmount: Double
    public let priceCurrency: String?
    public let payNetwork: String
    public let payToken: String
    public let orderId: String?
    public let title: String?
    public let customerName: String?
    public let customerEmail: String?
    public let redirectUrl: String?
    public let cancelUrl: String?
    public let ipnCallbackUrl: String?

    public init(
        priceAmount: Double,
        priceCurrency: String? = "USD",
        payNetwork: String,
        payToken: String,
        orderId: String? = nil,
        title: String? = nil,
        customerName: String? = nil,
        customerEmail: String? = nil,
        redirectUrl: String? = nil,
        cancelUrl: String? = nil,
        ipnCallbackUrl: String? = nil
    ) {
        self.priceAmount = priceAmount
        self.priceCurrency = priceCurrency
        self.payNetwork = payNetwork
        self.payToken = payToken
        self.orderId = orderId
        self.title = title
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.redirectUrl = redirectUrl
        self.cancelUrl = cancelUrl
        self.ipnCallbackUrl = ipnCallbackUrl
    }
}

public struct Invoice: Codable, Sendable {
    public let id: String
    public let merchantId: String
    public let orderId: String?
    public let title: String?
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
}

public struct PaymentRecord: Codable, Sendable {
    public let id: String
    public let txHash: String
    public let amountReceived: String
    public let confirmations: Int
    public let status: String
    public let forwardedTxHash: String?
    public let createdAt: String
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

public struct WebhookEvent: Codable, Sendable {
    public let event: String
    public let invoiceId: String
    public let orderId: String?
    public let priceAmount: Double
    public let priceCurrency: String
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
        case orderId = "order_id"
        case priceAmount = "price_amount"
        case priceCurrency = "price_currency"
        case payAmount = "pay_amount"
        case payToken = "pay_token"
        case payNetwork = "pay_network"
        case depositAddress = "deposit_address"
        case txHash = "tx_hash"
        case status
        case timestamp
    }
}

