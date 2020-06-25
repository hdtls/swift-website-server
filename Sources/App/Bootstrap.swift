import Vapor
import Fluent
import FluentMySQLDriver

typealias Env = Environment

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

    app.databases.use(.mysql(
        hostname: Env.get("DB_HOST") ?? "127.0.0.1",
        username: Env.get("DB_USERNAME") ?? "vapor",
        password: Env.get("DB_PASSWORD") ?? "654321",
        database: Env.get("DB_NAME") ?? "website",
        tlsConfiguration: .none
        ), as: .mysql)

    app.migrations.add(User.migration)
    app.migrations.add(Token.migration)
//    app.migrations.add(JobExp.migration)
//    app.migrations.add(EduExp.migration)
//    app.migrations.add(SocialMedia.migration)

    try app.autoRevert().wait()
    try app.autoMigrate().wait()

    // Register routes
    try routes(app)
}
