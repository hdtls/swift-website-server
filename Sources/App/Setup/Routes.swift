import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    try app.register(collection: FilesCollection.init())
}
