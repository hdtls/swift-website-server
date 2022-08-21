import Fluent
import Vapor

struct SkillRepository: Repository {

    typealias Model = Skill

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
        try await request.owner.$skill.create(model, on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let skill: RepositoryFactoryKey = "skill"
}

extension Request {

    var skill: SkillRepository {
        guard let result = registry.repository(.skill, self) as? SkillRepository else {
            fatalError("Skill repository is not configured")
        }
        return result
    }
}
