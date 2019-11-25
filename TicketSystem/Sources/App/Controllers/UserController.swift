import Crypto
import Vapor
import FluentSQLite

/// Creates new users and logs them in.
final class UserController {
    /// Creates a new user.
    func create(_ req: Request) throws -> Future<CreateUserResponse> {
        return try req.content.decode(CreateUserRequest.self).flatMap(to: String.self) { user in
            let passwordHash = try BCrypt.hash(user.password)
            let emailHash = try SHA1.hash(user.email).base64EncodedString()
            let token = String.random(length: 64)
            
            return try User(email: user.email, emailHash: emailHash, token: token, password: passwordHash)
                .encrypt(on: req)
                .save(on: req)
                .map { _ in token }
        }.map(to: CreateUserResponse.self) { token in
            return CreateUserResponse(token: token)
        }
    }
    
    func order(_ req: Request) throws -> Future<OrderResponse> {
        return try req.content.decode(OrderRequest.self).flatMap(to: (OrderRequest, Int).self) { order in
            let emailHash = try SHA1.hash(order.email).base64EncodedString()
            
            return User.query(on: req).filter(\.emailHash == emailHash).first()
                // Validate
                .map { user in
                    guard let user = user,
                        let decryptedUser = try? user.decrypt(on: req),
                        try BCrypt.verify(order.password, created: decryptedUser.password) else {
                            throw Abort(.badRequest, reason: "Invalid email or password")
                    }
                    
                    guard decryptedUser.token == order.token else {
                        throw Abort(.badRequest, reason: "Invalid token")
                    }
                    
                    return (order, try user.requireID())
            }
        }
        .flatMap(to: OrderResponse.self ) { arg in
            let (order, userId) = arg
            let ticketService = try req.make(TicketService.self)
            return try ticketService.makeOrder(order, userId: userId, on: req)
                .map(to: OrderResponse.self) { tickets in
                    OrderResponse(tickets: try tickets.map { try $0.requireID().uuidString })
                }
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

struct OrderRequest: Content {
    let email: String
    let password: String
    let token: String
    let ticketCount: Int
}

struct OrderResponse: Content {
    let tickets: [String]
}
