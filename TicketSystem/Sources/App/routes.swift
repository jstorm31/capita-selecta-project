import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // public routes
    let userController = UserController()
    router.post("users", use: userController.create)
}
