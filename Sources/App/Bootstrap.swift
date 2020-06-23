import Vapor
import Fluent
import FluentSQLiteDriver

/// Called before your application initializes.
public func bootstrap(_ app: Application) throws {

    // JSON configuration
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Http server settins
    if app.environment == .development {
        app.http.server.configuration.port = 8181
    }

    // Middlewares configuration
    app.middleware.use(CORSMiddleware.init())
    app.middleware.use(FileMiddleware.init(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.memory), as: .sqlite)

    app.migrations.add(UserMigration.init())
    app.migrations.add(TokenMigration.init())

    try app.autoMigrate().wait()

    // Register routes
    try routes(app)
}
