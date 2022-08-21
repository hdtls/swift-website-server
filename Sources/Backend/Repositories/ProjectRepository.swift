import Fluent
import Vapor

struct ProjectRepository: Repository {

    typealias Model = Project

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
        try await request.owner.$projects.create(model, on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let project: RepositoryFactoryKey = "project"
}

extension Request {

    var project: ProjectRepository {
        guard let result = registry.repository(.project, self) as? ProjectRepository else {
            fatalError("Project repository is not configured")
        }
        return result
    }
}
