import Vapor

/// In progress
/// admin user request.
class SocialNetworkingServiceCollection: RouteCollection, RestfulApi {
    typealias T = SocialNetworkingService

    func boot(routes: RoutesBuilder) throws {

        let routes = routes.grouped("social", "services")

        let path = PathComponent.parameter(restfulIDKey)

        routes.on(.POST, use: create)
        routes.on(.GET, path, use: read)
        routes.on(.PUT, path, use: update)
        routes.on(.DELETE, path, use: delete)
    }

    func create(_ req: Request) throws -> EventLoopFuture<SocialNetworking.Service.Coding> {
        let coding = try req.content.decode(T.SerializedObject.self)
        guard coding.type != nil else {
            throw Abort.init(.badRequest, reason: "Value required for key 'type'")
        }
        let model = T.init(content: coding)
        return model.save(on: req.db)
            .flatMapThrowing({
                try model.reverted()
            })
    }
}
