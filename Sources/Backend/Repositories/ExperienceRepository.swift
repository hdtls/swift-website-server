import Fluent
import Vapor

struct ExperienceRepository: Repository {

    typealias Model = Experience

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        let query = Model.query(on: request.db).with(\.$industries)

        if owned {
            try query.filter(\.$user.$id == request.owner.__id)
        }

        return query
    }

    func create(_ model: Model, industries: [Industry]) async throws {
        try await request.owner.$experiences.create(model, on: request.db)

        try await model.$industries.attach(industries, on: request.db)
        try await model.$industries.load(on: request.db)
    }

    func update(_ model: Model, industries: [Industry]) async throws {
        try await model.save(on: request.db)

        try await model.$industries.detachAll(on: request.db)
        try await model.$industries.attach(industries, on: request.db)
        try await model.$industries.load(on: request.db)
    }

    func delete(_ id: Model.IDValue) async throws {
        let saved = try await query(id, owned: true).first()

        try await saved?.$industries.detachAll(on: request.db)

        try await saved?.delete(on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let experience: RepositoryFactoryKey = "experience"
}

extension Request {

    var experience: ExperienceRepository {
        guard let result = registry.repository(.experience, self) as? ExperienceRepository else {
            fatalError("Experience repository is not configured")
        }
        return result
    }
}
