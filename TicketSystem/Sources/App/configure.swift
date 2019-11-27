import FluentPostgreSQL
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
    let postgresqlDefault = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: "localhost", port: 5432, username: "ticket_system", database: "ticket_system_default", password: "ticketpass"))
    let postgresqlShared = PostgreSQLDatabase(config: PostgreSQLDatabaseConfig(hostname: "localhost", port: 5433, username: "ticket_system", database: "ticket_system_shared", password: "ticketpass"))
    
    var databases = DatabasesConfig()
    databases.add(database: postgresqlDefault, as: .init(stringLiteral: "psqlDefault"))
    databases.add(database: postgresqlShared, as: .psql)
//    databases.enableLogging(on: .psql)
    services.register(databases)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .init(stringLiteral: "psqlDefault"))
    migrations.add(model: Ticket.self, database: .init(stringLiteral: "psqlDefault"))
    migrations.add(model: AvailableTickets.self, database: .psql)
    migrations.add(migration: AddTicketCount.self, database: .psql)
    services.register(migrations)
}
