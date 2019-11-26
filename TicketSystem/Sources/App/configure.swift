import FluentPostgreSQL
import FluentMongo
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())
//    try services.register(FluentMongoProvider())

    services.register(Crypto.self)
    services.register(TicketService.self)
    
    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(SessionsMiddleware.self) // Enables sessions.
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    /// Register the configured PostgreSQL database to the database config.
    let postgresql = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: "localhost", username: "ticket_system", database: "ticket_system", password: "ticketpass"))
    let mongodb = MongoDatabase(config: try MongoDatabaseConfig(user: "ticket_system", password: "ticketpass", host: "localhost", database: "ticket_system"))
    
    var databases = DatabasesConfig()
    databases.add(database: postgresql, as: .psql)
    databases.add(database: mongodb, as: .mongo)
    databases.enableLogging(on: .psql)
    services.register(databases)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: AvailableTickets.self, database: .psql)
    migrations.add(model: Ticket.self, database: .psql)
    services.register(migrations)
}
