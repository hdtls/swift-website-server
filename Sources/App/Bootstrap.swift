import Vapor
import Fluent
import FluentMySQLDriver

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
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tlsConfiguration: .forClient(certificateVerification: .none)
        ), as: .mysql)

    app.migrations.add(User.migration)
    app.migrations.add(Token.migration)
    app.migrations.add(WorkExp.migration)
    app.migrations.add(SocialNetworking.migration)
    app.migrations.add(Industry.migration)
    app.migrations.add(EducationalExp.migration)
    app.migrations.add(WorkExpIndustrySiblings.migration)
    app.migrations.add(SocialNetworkingService.migration)
    app.migrations.add(Skill.migration)
    app.migrations.add(Project.migration)

    try app.autoMigrate().wait()

    // Register routes
    try routes(app)
}
