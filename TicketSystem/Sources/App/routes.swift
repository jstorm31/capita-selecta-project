import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    let appController = AppController()
    try router.register(collection: appController)
}
