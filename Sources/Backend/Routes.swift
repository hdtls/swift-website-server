import Vapor

/// Register your application's routes here.
func routes(_ app: Application) throws {

    try app.routes.register(collection: FileCollection.init(type: .file))
    try app.routes.register(collection: FileCollection.init(type: .image))
    try app.routes.register(collection: UserCollection.init())
    try app.routes.register(collection: EducationCollection.init())
    try app.routes.register(collection: ExpCollection.init())
    try app.routes.register(collection: LogCollection.init())
    try app.routes.register(collection: SocialNetworkingServiceCollection.init())
    try app.routes.register(collection: SocialNetworkingCollection.init())
    try app.routes.register(collection: IndustryCollection.init())
    try app.routes.register(collection: SkillCollection.init())
    try app.routes.register(collection: ProjectCollection.init())
    try app.routes.register(collection: BlogCollection.init())
    try app.routes.register(collection: BlogCategoryCollection.init())
}
