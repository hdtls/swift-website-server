import Vapor
import Fluent

class ExpCollection: RestfulApiCollection {
    typealias T = Experience

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let user = try req.auth.require(User.self)
        let coding = try req.content.decode(T.SerializedObject.self)

        let exp = T.init(content: coding)

        let industries = try _industriesMaker(coding: coding)
        
        exp.$user.id = try user.requireID()

        return exp.save(on: req.db)
            .flatMap({
                exp.$industries.attach(industries, on: req.db)
            })
            .flatMap({
                exp.$industries.get(on: req.db)
            })
            .flatMapThrowing({ _ in
                try exp.reverted()
            })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.SerializedObject]> {
     
        return T.query(on: req.db)
            .with(\.$industries)
            .all()
            .flatMapEachThrowing({ try $0.reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)
        let upgrade = T.init(content: coding)
        let industries = try _industriesMaker(coding: coding)

        return try topLevelQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.merge(upgrade)

                let difference = industries.difference(from: saved.industries) {
                    $0.id == $1.id
                }

                return EventLoopFuture<Void>.andAllSucceed(difference.map({
                    switch $0 {
                    case .insert(offset: _, element: let industry, associatedWith: _):
                        return saved.$industries.attach(industry, on: req.db)
                    case .remove(offset: _, element: let industry, associatedWith: _):
                        return saved.$industries.detach(industry, on: req.db)
                    }
                }), on: req.eventLoop)
                .flatMap({
                    saved.$industries.get(reload: true, on: req.db)
                })
                .flatMap({ _ in
                    saved.update(on: req.db)
                })
                .map({ saved })
            })
            .flatMapThrowing({
                try $0.reverted()
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try topLevelQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort.init(.notFound))
            .flatMap({ exp in
                exp.$industries.detach(exp.industries, on: req.db).flatMap({
                    exp.delete(on: req.db)
                })
            })
            .map({ .ok })
    }

    func queryBuilder(on req: Request) throws -> QueryBuilder<Experience> {
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .with(\.$industries)
    }

    private func _industriesMaker(coding: T.SerializedObject) throws -> [Industry] {
        try coding.industries.map({ coding -> Industry in
            // `Industry.id` is not required by `Industry.__converted(_:)`, but
            // required by create relation of `experience` and `industry`, so we will
            // add additional check to make sure it have `id` to attach with.
            guard coding.id != nil else {
                throw Abort.init(.badRequest, reason: "Value required for key 'Industry.id'")
            }
            return try Industry.init(content: coding)
        })
    }
}
