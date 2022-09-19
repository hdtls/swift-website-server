import FluentMySQLDriver
import Vapor

/// Called before your application initializes.
func bootstrap(_ app: Application) throws {

    // JSON configuration
    let encoder = JSONEncoder()

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // Middlewares configuration
    app.middleware.use(CORSMiddleware.init())
    app.middleware.use(FileMiddleware.init(publicDirectory: app.directory.publicDirectory))

    var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
    tlsConfiguration.certificateVerification = .none

    app.databases.use(
        .mysql(
            hostname: Environment.get("MYSQL_HOST") ?? "localhost",
            port: Int(Environment.get("MYSQL_PORT") ?? "3306")!,
            username: Environment.get("MYSQL_USER") ?? "swift",
            password: Environment.get("MYSQL_PASSWORD") ?? "mysql",
            database: Environment.get("MYSQL_DATABASE") ?? "blog",
            tlsConfiguration: tlsConfiguration
        ),
        as: .mysql
    )

    app.migrations.add(User.migration)
    app.migrations.add(Token.migration)
    app.migrations.add(Experience.migration)
    app.migrations.add(SocialNetworking.migration)
    app.migrations.add(Industry.migration)
    app.migrations.add(Education.migration)
    app.migrations.add(SocialNetworkingService.migration)
    app.migrations.add(Skill.migration)
    app.migrations.add(Project.migration)
    app.migrations.add(Blog.migration)
    app.migrations.add(BlogCategory.migration)
    app.migrations.add(Linker<BlogCategory, Blog>.migration)
    app.migrations.add(Linker<Industry, Experience>.migration)

    app.registry.use(BlogCategoryRepository.init, as: .blogCategory)
    app.registry.use(BlogRepository.init, as: .blog)
    app.registry.use(EducationRepository.init, as: .education)
    app.registry.use(ExperienceRepository.init, as: .experience)
    app.registry.use(IndustryRepository.init, as: .industry)
    app.registry.use(ProjectRepository.init, as: .project)
    app.registry.use(SkillRepository.init, as: .skill)
    app.registry.use(SocialNetworkingRepository.init, as: .socialNetworking)
    app.registry.use(SocialNetworkingServiceRepository.init, as: .socialNetworkingService)
    app.registry.use(UserRepository.init, as: .user)

    try routes(app)
}
