import App
import Vapor

let app = try Application(.detect())
try LoggingSystem.bootstrap(from: &app.environment)
defer { app.shutdown() }
try bootstrap(app)
try app.run()
