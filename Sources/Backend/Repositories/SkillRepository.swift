import Fluent
import Vapor

struct SkillRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Skill> {
        let query = Skill.query(on: req.db)

        if owned {
            try query.filter(\.$user.$id == req.owner.__id)
        }

        return query
    }

    func query(_ id: Skill.IDValue, owned: Bool = false) throws -> QueryBuilder<Skill> {
        try query(owned: owned).filter(\.$id == id)
    }

    func create(_ model: Skill) async throws {
        try await req.owner.$skill.create(model, on: req.db)
    }

    func identified(by id: Skill.IDValue, owned: Bool = false) async throws -> Skill {
        guard let result = try await query(id, owned: owned).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll(owned: Bool = false) async throws -> [Skill] {
        try await query(owned: owned).all()
    }

    func update(_ model: Skill) async throws {
        try await model.update(on: req.db)
    }

    func delete(_ id: Skill.IDValue) async throws {
        try await query(id, owned: true).delete()
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
