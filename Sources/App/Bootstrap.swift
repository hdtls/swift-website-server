import Vapor
import Fluent
import FluentMySQLDriver

typealias Env = Environment

/// Called before your application initializes.
public func bootstrap(_ app: Application) throws {

    app.http.server.configuration.port = 8181
    
    // JSON configuration
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Middlewares configuration
    app.middleware.use(CORSMiddleware.init())
    app.middleware.use(FileMiddleware.init(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.mysql(
        hostname: "127.0.0.1",
        port: app.environment == .testing ? 3308 : (app.environment == .development ? 3307 : 3306),
        username: "vapor",
        password: "vapor.mysql",
        database: "website",
        tlsConfiguration: .none
        ), as: .mysql)

    app.migrations.add(User.migration)
    app.migrations.add(Token.migration)
    app.migrations.add(EduExp.migration)
    app.migrations.add(JobExp.migration)
    app.migrations.add(WebLink.migration)
    app.migrations.add(SocialMedia.migration)
    app.migrations.add(WebLinkSocialMediaSiblings.migration)

    // Register routes
    try routes(app)
}
