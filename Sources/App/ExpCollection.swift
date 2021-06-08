import Vapor
import Fluent

class ExpCollection: ApiCollection {
    typealias T = Experience
    
    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(path.components(separatedBy: "/").map(PathComponent.constant))
        
        routes.on(.GET, use: readAll)
        
        routes.on(.GET, .parameter(restfulIDKey), use: read)
        
        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])
        
        trusted.on(.POST, use: create)
        trusted.on(.PUT, .parameter(restfulIDKey), use: update)
        trusted.on(.DELETE, .parameter(restfulIDKey), use: delete)
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.DTO> {
        let userId = try req.auth.require(User.self).requireID()

        return try specifiedIDQueryBuilder(on: req)
            .filter(\.$user.$id == userId)
            .with(\.$industries)
            .first()
            .unwrap(orError: Abort(.notFound))
            .flatMap({
                do {
                    return try self.performUpdate($0, on: req)
                } catch {
                    return req.eventLoop.makeFailedFuture(error)
                }
            })
    }

    func applyingEagerLoaders(_ builder: QueryBuilder<T>) -> QueryBuilder<T> {
        builder.with(\.$industries)
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try specifiedIDQueryBuilder(on: req)
            .with(\.$industries)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMap({ exp in
                exp.$industries.detach(exp.industries, on: req.db).flatMap({
                    exp.delete(on: req.db)
                })
            })
            .map({ .ok })
    }

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.DTO> {
        var serializedObject = try req.content.decode(T.DTO.self)
        serializedObject.userId = try req.auth.require(User.self).requireID()
        
        let industries: [Industry] = try serializedObject.industries.map(Industry.init)

        var upgrade = T.init()

        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try T.init(from: serializedObject)
        }

        return upgrade.save(on: req.db)
            .flatMap({
                let difference = industries.difference(from: upgrade.$industries.value ?? []) {
                    $0.id == $1.id
                }

                return EventLoopFuture<Void>.andAllSucceed(difference.map({
                    switch $0 {
                    case .insert(offset: _, element: let industry, associatedWith: _):
                        return upgrade.$industries.attach(industry, on: req.db)
                    case .remove(offset: _, element: let industry, associatedWith: _):
                        return upgrade.$industries.detach(industry, on: req.db)
                    }
                }), on: req.eventLoop)
                .flatMap({
                    upgrade.$industries.load(on: req.db)
                })
            })
            .flatMapThrowing({ () in
                try upgrade.dataTransferObject()
            })
    }
}
