import Crypto
import Vapor
import FluentSQLite

/// Creates new users and logs them in.
final class UserController {
    /// Creates a new user.
    func create(_ req: Request) throws -> Future<CreateUserResponse> {
        let crypto = try req.make(Crypto.self)
        
        return try req.content.decode(CreateUserRequest.self).flatMap(to: String.self) { user in
            let hash = try BCrypt.hash(user.password)
            let token = String.random(length: 64)
            
            let email = try crypto.encrypt(user.email)
            let encryptedToken = try crypto.encrypt(token)
            let password = try crypto.encrypt(hash)
            
            return User(email: email, token: encryptedToken, password: password).save(on: req).map { user in
                let decryptedEmail = try crypto.decrypt(user.email)
                print("Decrypted email: \(decryptedEmail)")
                
                return token
            }
        }.map(to: CreateUserResponse.self) { token in
            return CreateUserResponse(token: token)
        }
    }
}

// MARK: Content

/// Data required to create a user.
struct CreateUserRequest: Content {
    var email: String
    var password: String
}

struct CreateUserResponse: Content {
    let token: String
}
