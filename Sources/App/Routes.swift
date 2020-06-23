import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    try app.register(collection: FileCollection.init())
    try app.register(collection: ResumeCollection.init())
    try app.register(collection: UserCollection.init())
}
