import Vapor
import Fluent
import FluentMySQLDriver

/// Called before your application initializes.
public func bootstrap(_ app: Application) throws {

    // JSON configuration
    let encoder = JSONEncoder()

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Middlewares configuration
    app.middleware.use(CORSMiddleware.init())
    app.middleware.use(FileMiddleware.init(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.mysql(
        hostname: Environment.get("MYSQL_HOST") ?? "localhost",
        port: Int(Environment.get("MYSQL_PORT") ?? "3306")!,
        username: Environment.get("MYSQL_USER") ?? "swift",
        password: Environment.get("MYSQL_PASSWORD") ?? "mysql",
        database: Environment.get("MYSQL_DATABASE") ?? "website",
        tlsConfiguration: .forClient(certificateVerification: .none)
    ), as: .mysql)

    app.migrations.add(User.migration)
    app.migrations.add(Token.migration)
    app.migrations.add(Experience.migration)
    app.migrations.add(SocialNetworking.migration)
    app.migrations.add(Industry.migration)
    app.migrations.add(Education.migration)
    app.migrations.add(ExpIndustrySiblings.migration)
    app.migrations.add(SocialNetworkingService.migration)
    app.migrations.add(Skill.migration)
    app.migrations.add(Project.migration)
    app.migrations.add(Blog.migration)
    app.migrations.add(BlogCategory.migration)
    app.migrations.add(BlogCategorySiblings.migration)

    try app.autoMigrate().wait()

    // Register routes
    try routes(app)
}
