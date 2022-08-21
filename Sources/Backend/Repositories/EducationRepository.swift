import Fluent
import Vapor

struct EducationRepository: Repository {

    typealias Model = Education

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        let query = Model.query(on: request.db)

        if owned {
            try query.filter(\.$user.$id == request.owner.__id)
        }

        return query
    }

    func create(_ model: Model) async throws {
        try await request.owner.$education.create(model, on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let education: RepositoryFactoryKey = "education"
}

extension Request {

    var education: EducationRepository {
        guard let result = registry.repository(.education, self) as? EducationRepository else {
            fatalError("Education repository is not configured")
        }
        return result
    }
}
