import FluentPostgreSQL
import Vapor

final class User: Codable {
    var id: Int?
    var email: String
    var token: String
    var password: String
    
    init(email: String, token: String, password: String) {
        self.email = email
        self.token = token
        self.password = password
    }
}

extension User: PostgreSQLModel {}
extension User: Content {}
extension User: Migration {}
