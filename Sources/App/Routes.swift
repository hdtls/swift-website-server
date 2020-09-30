import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    try app.register(collection: FileCollection.init(path: "static"))
    try app.register(collection: FileCollection.init(path: "images"))
    try app.register(collection: ResumeCollection.init())
    try app.register(collection: UserCollection.init())
    try app.register(collection: DefaultOwnableApiImpl<Education>.init())
    try app.register(collection: ExpCollection.init())
    try app.register(collection: LogCollection.init())
    try app.register(collection: SocialNetworkingServiceCollection.init())
    try app.register(collection: SocialNetworkingCollection.init())
    try app.register(collection: IndustryCollection.init())
    try app.register(collection: DefaultOwnableApiImpl<Skill>.init())
    try app.register(collection: ProjCollection.init())
    try app.register(collection: BlogCollection.init())
}
