import Vapor
import Fluent

class ResumeCollection: RouteCollection {

    let restfulIDKey = "id"

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped("users", .parameter(restfulIDKey), "resume")
        routes.on(.GET, use: read)
    }

    func read(_ req: Request) throws -> EventLoopFuture<User.Coding> {
        let queryBuilder = User.query(on: req.db)
        // Support for `id` and `username` check.
        if let id = req.parameters.get(restfulIDKey, as: User.IDValue.self) {
            queryBuilder.filter(\._$id == id)
        } else if let id = req.parameters.get(restfulIDKey) {
            queryBuilder.filter(User.FieldKeys.username.rawValue, .equal, id)
        } else {
            throw Abort(.notFound)
        }
        return queryBuilder
            .with(\.$projects)
            .with(\.$eduExps)
            .with(\.$workExps) {
                $0.with(\.$industry)
            }
            .with(\.$social) {
                $0.with(\.$service)
            }
            .with(\.$skill)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({
                try $0.reverted()
            })
    }
}
