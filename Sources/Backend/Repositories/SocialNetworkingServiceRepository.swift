import Fluent
import Vapor

struct SocialNetworkingServiceRepository: Repository {

    typealias Model = SocialNetworkingService

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        Model.query(on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let socialNetworkingService: RepositoryFactoryKey = "social_networking_service"
}

extension Request {

    var socialNetworkingService: SocialNetworkingServiceRepository {
        guard
            let result = registry.repository(.socialNetworkingService, self)
                as? SocialNetworkingServiceRepository
        else {
            fatalError("Social networking service repository is not configured")
        }
        return result
    }
}
