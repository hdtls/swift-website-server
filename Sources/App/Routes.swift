import Vapor

/// Register your application's routes here.
public func routes(_ app: Application) throws {

    try app.register(collection: FileCollection.init())
    try app.register(collection: ResumeCollection.init())
    try app.register(collection: UserCollection.init())
    try app.register(collection: DefaultUserChildCollection<JobExp>.init(path: "exp", "jobs"))
    try app.register(collection: DefaultUserChildCollection<EduExp>.init(path: "exp", "edu"))
    try app.register(collection: LogCollection.init())
}
