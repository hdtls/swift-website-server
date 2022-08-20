import Fluent
import Vapor

struct BlogCategoryRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query() -> QueryBuilder<BlogCategory> {
        BlogCategory.query(on: req.db)
    }

    func query(_ id: BlogCategory.IDValue) -> QueryBuilder<BlogCategory> {
        query().filter(\.$id == id)
    }

    func save(_ model: BlogCategory) async throws {
        try await model.save(on: req.db)
    }

    func identified(by id: BlogCategory.IDValue) async throws -> BlogCategory {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll() async throws -> [BlogCategory] {
        try await query().all()
    }

    func delete(_ id: BlogCategory.IDValue) async throws {
        try await query(id).delete()
    }
}

extension RepositoryID {
    static let blogCategory: RepositoryID = "blog_category"
}

extension Request {

    var blogCategory: BlogCategoryRepository {
        guard let result = registry.repository(.blogCategory, self) as? BlogCategoryRepository
        else {
            fatalError("Blog category repository is not configured")
        }
        return result
    }
}
