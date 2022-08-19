import FluentMySQLDriver
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

    func create(_ model: Industry) async throws {
        try await save(model)
    }

    func save(_ model: Industry) async throws {
        do {
            try await model.save(on: req.db)
        } catch {
            if case MySQLError.duplicateEntry(let localizedErrorDescription) = error {
                throw Abort.init(.unprocessableEntity, reason: localizedErrorDescription)
            }
            throw error
        }
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

    func update(_ model: Industry) async throws {
        try await save(model)
    }

    func delete(_ id: Industry.IDValue) async throws {
        try await query(id).delete()
    }
}

extension RepositoryID {
    static let industry: RepositoryID = "industry"
}

extension RepositoryFactory {

    var industry: IndustryRepository {
        guard let result = repository(.industry) as? IndustryRepository else {
            fatalError("Industry repository is not configured")
        }
        return result
    }
}
