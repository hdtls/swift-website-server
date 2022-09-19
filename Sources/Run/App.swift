import Backend

@main
struct App {

    static func main() async throws {
        let app = try Application(.detect())
        try LoggingSystem.bootstrap(from: &app.environment)
        defer { app.shutdown() }
        try bootstrap(app)
        try await app.autoMigrate()
        try app.run()
    }
}
