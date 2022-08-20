import Fluent
import Vapor

struct IndustryRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query() -> QueryBuilder<Industry> {
        Industry.query(on: req.db)
    }

    func query(_ id: Industry.IDValue) -> QueryBuilder<Industry> {
        query().filter(\.$id == id)
    }

    func save(_ model: Industry) async throws {
        try await model.save(on: req.db)
    }

    func identified(by id: Industry.IDValue) async throws -> Industry {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll() async throws -> [Industry] {
        try await query().all()
    }

    func delete(_ id: Industry.IDValue) async throws {
        try await query(id).delete()
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
