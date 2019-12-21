import FluentPostgreSQL
import Vapor

final class User: Codable {
    var id: Int?
    var email: String
    var emailHash: String?
    var ticketToken: String
    var password: String
    var accessToken: String?
    var paymentCardType: PaymentCardType
    
    init(email: String, emailHash: String? = nil, token: String, password: String, paymentCardType: PaymentCardType) {
        self.email = email
        self.emailHash = emailHash
        self.ticketToken = token
        self.password = password
        self.paymentCardType = paymentCardType
    }
    
    func encrypt(on req: Request) throws -> User {
        let crypto = try req.make(Crypto.self)

        email = try crypto.encrypt(email)
        ticketToken = try crypto.encrypt(ticketToken)
        password = try crypto.encrypt(password)
        
        return self
    }
    
    func decrypt(on req: Request) throws -> User {
        let crypto = try req.make(Crypto.self)

        let email = try crypto.decrypt(self.email)
        let token = try crypto.decrypt(self.ticketToken)
        let password = try crypto.decrypt(self.password)
        
        return User(email: email, emailHash: self.emailHash, token: token, password: password, paymentCardType: self.paymentCardType)
    }
}

extension User: PostgreSQLModel {}
extension User: Content {}
extension User: Migration {}

enum PaymentCardType: Int, PostgreSQLRawEnum {
    case maestro
    case mastercard
    case visa
    
    static func delay(_ type: Self) -> Int {
        switch type {
        case .maestro:
            // Slow
            return Int.random(in: 2500...5000)
        case .mastercard:
            // Medium
            return Int.random(in: 1500...3500)
        case .visa:
            // Fast
            return Int.random(in: 500...2500)
        }
    }
}
