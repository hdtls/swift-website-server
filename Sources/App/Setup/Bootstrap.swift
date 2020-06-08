import Vapor

/// Called before your application initializes.
public func bootstrap(_ app: Application) throws {

    app.middleware.use(CORSMiddleware.init())
    app.middleware.use(FileMiddleware.init(publicDirectory: app.directory.publicDirectory))

    // Register routes
    try routes(app)
}
