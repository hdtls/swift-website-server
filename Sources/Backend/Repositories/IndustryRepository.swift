import Fluent
import Vapor

struct IndustryRepository: Repository {

    typealias Model = Industry

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        Model.query(on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let industry: RepositoryFactoryKey = "industry"
}

extension Request {

    var industry: IndustryRepository {
        guard let result = registry.repository(.industry, self) as? IndustryRepository else {
            fatalError("Industry repository is not configured")
        }
        return result
    }
}
