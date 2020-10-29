import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    if app.environment != .production {
        try app.register(collection: ApiCollection.init())
    }
    
    try app.register(collection: FileCollection.init(type: .files))
    try app.register(collection: FileCollection.init(type: .images))
    try app.register(collection: UserCollection.init())
    try app.register(collection: DefaultOwnableApiImpl<Education>.init())
    try app.register(collection: ExpCollection.init())
    try app.register(collection: LogCollection.init())
    try app.register(collection: SocialNetworkingServiceCollection.init())
    try app.register(collection: SocialNetworkingCollection.init())
    try app.register(collection: IndustryCollection.init())
    try app.register(collection: DefaultOwnableApiImpl<Skill>.init())
    try app.register(collection: DefaultOwnableApiImpl<Project>.init())
    try app.register(collection: BlogCollection.init())
}
