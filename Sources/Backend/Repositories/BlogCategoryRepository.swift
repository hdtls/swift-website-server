import Vapor
import FluentMySQLDriver

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
    
    func create(_ model: BlogCategory) async throws {
        try await save(model)
    }

    func read(_ id: BlogCategory.IDValue) async throws -> BlogCategory {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func readAll() async throws -> [BlogCategory] {
        try await query().all()
    }
    
    func update(_ model: BlogCategory) async throws {
        try await save(model)
    }
        
    func delete(_ id: BlogCategory.IDValue) async throws {
        try await query(id).delete()
    }
    
    private func save(_ model: BlogCategory) async throws {
        do {
            try await model.save(on: req.db)
        } catch {
            if case MySQLError.duplicateEntry(let localizedErrorDescription) = error {
                throw Abort.init(.unprocessableEntity, reason: localizedErrorDescription)
            }
            throw error
        }
    }
}

extension RepositoryID {
    static let blogCategory: RepositoryID = "blog_category"
}

extension RepositoryFactory {

    var blogCategory: BlogCategoryRepository {
        guard let result = repository(.blogCategory) as? BlogCategoryRepository else {
            fatalError("Blog category repository is not configured")
        }
        return result
    }
}

