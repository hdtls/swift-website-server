import Fluent
import Vapor

struct EducationRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Education> {
        let query = Education.query(on: req.db)

        if owned {
            try query.filter(\.$user.$id == req.owner.__id)
        }

        return query
    }

    func query(_ id: Education.IDValue, owned: Bool = false) throws -> QueryBuilder<Education> {
        try query(owned: owned).filter(\.$id == id)
    }

    func create(_ model: Education) async throws {
        try await req.owner.$education.create(model, on: req.db)
    }

    func identified(by id: Education.IDValue, owned: Bool = false) async throws -> Education {
        guard let result = try await query(id, owned: owned).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll(owned: Bool = false) async throws -> [Education] {
        try await query(owned: owned).all()
    }

    func update(_ model: Education) async throws {
        try await model.update(on: req.db)
    }

    func delete(_ id: Education.IDValue) async throws {
        try await query(id, owned: true).delete()
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
