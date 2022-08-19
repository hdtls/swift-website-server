import Fluent
import Vapor

struct ExperienceRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Experience> {
        let query = Experience.query(on: req.db).with(\.$industries)

        if owned {
            try query.filter(\.$user.$id == req.uid)
        }

        return query
    }

    func query(_ id: Experience.IDValue, owned: Bool = false) throws -> QueryBuilder<Experience> {
        try query(owned: owned).filter(\.$id == id)
    }

    func create(_ model: Experience, industries: [Industry]) async throws {
        try await req.user.$experiences.create(model, on: req.db)

        try await model.$industries.attach(industries, on: req.db)
        try await model.$industries.load(on: req.db)
    }

    func identified(by id: Experience.IDValue, owned: Bool = false) async throws -> Experience {
        guard let result = try await query(id, owned: owned).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll(owned: Bool = false) async throws -> [Experience] {
        try await query(owned: owned).all()
    }

    func update(_ model: Experience, industries: [Industry]) async throws {
        try await model.save(on: req.db)

        try await model.$industries.detachAll(on: req.db)
        try await model.$industries.attach(industries, on: req.db)
        try await model.$industries.load(on: req.db)
    }

    func delete(_ id: Experience.IDValue) async throws {
        let saved = try await query(id, owned: true).first()

        try await saved?.$industries.detachAll(on: req.db)

        try await saved?.delete(on: req.db)
    }
}

extension RepositoryID {
    static let experience: RepositoryID = "experience"
}

extension RepositoryFactory {

    var experience: ExperienceRepository {
        guard let result = repository(.experience) as? ExperienceRepository else {
            fatalError("Experience repository is not configured")
        }
        return result
    }
}
