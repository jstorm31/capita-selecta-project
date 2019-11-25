import Crypto
import Vapor
import FluentSQLite

/// Creates new users and logs them in.
final class UserController {
    /// Creates a new user.
    func create(_ req: Request) throws -> Future<CreateUserResponse> {
        // decode request content
        return try req.content.decode(CreateUserRequest.self).flatMap(to: User.self) { user in
            let hash = try BCrypt.hash(user.password)
            let token = UUID().uuidString
            
            return User(email: user.email, token: token, password: hash).save(on: req)
        }.map(to: CreateUserResponse.self) { user in
            return CreateUserResponse(token: user.token)
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
