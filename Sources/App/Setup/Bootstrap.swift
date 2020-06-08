import Vapor

/// Called before your application initializes.
public func bootstrap(_ app: Application) throws {

    // Register routes
    try routes(app)
}
