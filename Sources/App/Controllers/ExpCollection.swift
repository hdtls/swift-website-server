import Vapor
import Fluent

class ExpCollection: RestfulApiCollection {
    typealias T = Experience

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let userId = try req.auth.require(User.self).requireID()

        return try specifiedIDQueryBuilder(on: req)
            .filter(T.uidFieldKey, .equal, userId)
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

    func applyingEagerLoaders(_ builder: QueryBuilder<Experience>) -> QueryBuilder<Experience> {
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

    func performUpdate(_ original: Experience?, on req: Request) throws -> EventLoopFuture<Experience.Coding> {

        let serializedObject = try req.content.decode(T.SerializedObject.self)

        let industries: [Industry] = try serializedObject.industries.map({
            // Model's `id` field is optional by default, but
            // required by create relation of `experience` and `industry`, so we will
            // add additional check to make sure it have `id` to attach with.
            guard $0.id != nil else {
                throw Abort(.badRequest, reason: "Value required for key: 'industries.id'")
            }
            return try .init(from: $0)
        })

        var upgrade = T.init()

        if let original = original {
            upgrade = try original.update(with: serializedObject)
        } else {
            upgrade = try T.init(from: serializedObject)
        }
        upgrade.$user.id = try req.auth.require(User.self).requireID()

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
