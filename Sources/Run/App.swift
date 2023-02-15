import Backend

@main
struct App {

    static func main() async throws {
        let app = try Application(.detect())
        try LoggingSystem.bootstrap(from: &app.environment)
        try app.setUp()
        try await app.autoMigrate()
        try app.run()
        app.shutdown()
    }
}
