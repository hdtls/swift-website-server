import Vapor
import Fluent

class SocialNetworkingCollection: RestfulApiCollection {

    typealias T = SocialNetworking

    func applyingFields(_ builder: QueryBuilder<SocialNetworking>) -> QueryBuilder<SocialNetworking> {
        builder.with(\.$service)
    }

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<SocialNetworking.Coding> {
        let serializedObject = try req.content.decode(T.SerializedObject.self)

        var upgrade = try T.init(from: serializedObject)
        upgrade.$user.id = try req.auth.require(User.self).requireID()

        if let original = original {
            original.update(with: upgrade)
            upgrade = original
        }

        return upgrade.save(on: req.db)
            .flatMap({
                // Make sure `$socialNetworkingService` has been eager loaded
                // before try `model.dataTransferObject()`.
                upgrade.$service.get(reload: true, on: req.db)
            })
            .flatMapThrowing({ _ in
                try upgrade.dataTransferObject()
            })
    }
}
