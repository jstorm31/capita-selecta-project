import FluentPostgreSQL
import Vapor

final class User: Codable {
    var id: Int?
    var email: String
    var emailHash: String?
    var ticketToken: String
    var password: String
    var accessToken: String?
    
    init(email: String, emailHash: String? = nil, token: String, password: String) {
        self.email = email
        self.emailHash = emailHash
        self.ticketToken = token
        self.password = password
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
        
        return User(email: email, emailHash: self.emailHash, token: token, password: password)
    }
}

extension User: PostgreSQLModel {}
extension User: Content {}
extension User: Migration {}
