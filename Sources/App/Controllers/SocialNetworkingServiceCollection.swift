import Vapor

/// In progress
/// admin user request.
class SocialNetworkingServiceCollection: RestfulApiCollection {
    typealias T = SocialNetworkingService

    var path: String = SocialNetworking.schema + "/services"

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.Coding> {
        let coding = try req.content.decode(T.SerializedObject.self)
        guard coding.type != nil else {
            throw Abort.init(.badRequest, reason: "Value required for key 'type'")
        }

        var upgrade = T.init(content: coding)

        if let original = original {
            original.update(with: upgrade)
            upgrade = original
        }

        return upgrade.save(on: req.db)
            .flatMapThrowing({
                try upgrade.reverted()
            })
    }
}
