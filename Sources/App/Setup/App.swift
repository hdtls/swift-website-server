import Vapor

/// Creates an instance of `Application`. This is called from `main.swift` in the run target.
public func app(_ environment: Environment) throws -> Application {
    var environment = environment

    try LoggingSystem.bootstrap(from: &environment)

    let app = Application(environment)

    try bootstrap(app)

    return app
}
