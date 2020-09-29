import Vapor
import Fluent

class SocialNetworkingCollection: RestfulApiCollection {
    typealias T = SocialNetworking

    func queryBuilder(on req: Request) throws -> QueryBuilder<SocialNetworking> {
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.query(on: req.db)
            .filter(\._$id == id)
            .with(\.$service)
    }

    func performUpdate(_ upgrade: SocialNetworking, on req: Request) -> EventLoopFuture<SocialNetworking.Coding> {
        upgrade.save(on: req.db)
        .flatMap({
            // Make sure `$socialNetworkingService` has been eager loaded
            // before try `model.reverted()`.
            upgrade.$service.get(on: req.db)
        })
        .flatMapThrowing({ _ in
            try upgrade.reverted()
        })
    }
}
