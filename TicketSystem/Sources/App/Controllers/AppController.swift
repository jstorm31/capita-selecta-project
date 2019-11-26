import Crypto
import FluentSQLite
import Vapor

/// Creates new users and logs them in.
final class AppController: RouteCollection {
    func boot(router: Router) throws {
        let routes = router.grouped("api")

        routes.post(CreateUserRequest.self, at: "register", use: registerHandler)
        routes.post(LoginRequest.self, at: "login", use: loginHandler)
        routes.post(OrderRequest.self, at: "order", use: orderHandler)
    }
    
    /// Creates a new user.
    func registerHandler(_ req: Request, userRequest: CreateUserRequest) throws -> Future<CreateUserResponse> {
        let passwordHash = try BCrypt.hash(userRequest.password)
        let emailHash = try SHA1.hash(userRequest.email).base64EncodedString()
        let token = String.random(length: 64)
        
        let newUser = User(email: userRequest.email, emailHash: emailHash, token: token, password: passwordHash, paymentCardType: userRequest.paymentCardType)
        
        return try newUser.encrypt(on: req).save(on: req).map(to: CreateUserResponse.self) { _ in
            CreateUserResponse(ticketToken: token)
        }
    }
    
    /// Authenticates a user
    func loginHandler(_ req: Request, loginRequest: LoginRequest) throws -> Future<LoginResponse> {
        let emailHash = try SHA1.hash(loginRequest.email).base64EncodedString()
        
        return User.query(on: req).filter(\.emailHash == emailHash).first()
            // Validate
            .flatMap(to: LoginResponse.self) { user in
                guard let user = user,
                    let decryptedUser = try? user.decrypt(on: req),
                    try BCrypt.verify(loginRequest.password, created: decryptedUser.password) else {
                        throw Abort(.badRequest, reason: "Invalid email or password")
                }
                
                guard decryptedUser.ticketToken == loginRequest.ticketToken else {
                    throw Abort(.badRequest, reason: "Invalid ticket token")
                }
                
                // Generate access token
                user.accessToken = String.random(length: 32)
                return user.update(on: req).map { LoginResponse(accessToken: $0.accessToken!) }
        }
    }
    
    /// Makes tickets order
    func orderHandler(_ req: Request, order: OrderRequest) throws -> Future<OrderResponse> {
        guard let bearer = req.http.headers.bearerAuthorization else {
            throw Abort(.unauthorized)
        }
        
        // Auth
        return User.query(on: req).filter(\.accessToken == bearer.token).first()
            .map(to: User.self) { user in
                guard let user = user else {
                    throw Abort(.unauthorized)
                }
                return user
            }
            .flatMap(to: OrderResponse.self) { user in
                let ticketService = try req.make(TicketService.self)
                
                return try ticketService.makeOrder(order, user: user, on: req)
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
    var paymentCardType: PaymentCardType
}

struct CreateUserResponse: Content {
    let ticketToken: String
}

struct LoginRequest: Content {
    let email: String
    let password: String
    let ticketToken: String
}

struct LoginResponse: Content {
    let accessToken: String
}

struct OrderRequest: Content {
    let ticketCount: Int
}

struct OrderResponse: Content {
    let tickets: [String]
}
