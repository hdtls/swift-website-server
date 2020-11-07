import Vapor

/// In progress
/// admin user request.
class SocialNetworkingServiceCollection: RestfulApiCollection {
    typealias T = SocialNetworkingService

    func boot(routes: RoutesBuilder) throws {

        let routes = routes.grouped(.constant(SocialNetworking.schema), "services")

        let path = PathComponent.parameter(restfulIDKey)

        routes.on(.POST, use: create)
        routes.on(.GET, path, use: read)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.Coding> {
        let coding = try req.content.decode(T.SerializedObject.self)
        guard coding.type != nil else {
            throw Abort.init(.badRequest, reason: "Value required for key 'type'")
        }

        var upgrade = T.init(content: coding)

        if let original = original {
            original.merge(upgrade)
            upgrade = original
        }

        return upgrade.save(on: req.db)
            .flatMapThrowing({
                try upgrade.reverted()
            })
    }
}
