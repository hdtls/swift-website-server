import Fluent
import Vapor

struct SocialNetworkingRepository: Repository {

    typealias Model = SocialNetworking

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        let query = Model.query(on: request.db).with(\.$service)

        if owned {
            try query.filter(\.$user.$id == request.owner.__id)
        }

        return query
    }

    func create(_ model: Model) async throws {
        try await request.owner.$social.create(model, on: request.db)
        try await model.$service.load(on: request.db)
    }

    func update(_ model: Model) async throws {
        try await model.save(on: request.db)
        try await model.$service.load(on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let socialNetworking: RepositoryFactoryKey = "social_networking"
}

extension Request {

    var socialNetworking: SocialNetworkingRepository {
        guard
            let result = registry.repository(.socialNetworking, self) as? SocialNetworkingRepository
        else {
            fatalError("Social networking repository is not configured")
        }
        return result
    }
}
