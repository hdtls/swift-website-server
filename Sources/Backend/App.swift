import Vapor

final public class App {

    public static func main() throws {
        let app = try Application(.detect())
        try LoggingSystem.bootstrap(from: &app.environment)
        defer { app.shutdown() }
        try bootstrap(app)
        try app.run()
    }
}
