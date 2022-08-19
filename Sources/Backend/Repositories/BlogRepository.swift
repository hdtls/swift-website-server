import Vapor
import FluentMySQLDriver

struct BlogRepository: Repository {
        
    var req: Request
    
    init(req: Request) {
        self.req = req
    }
    
    func query() -> QueryBuilder<Blog> {
        Blog.query(on: req.db)
    }
    
    func query(_ id: Blog.IDValue) -> QueryBuilder<Blog> {
        query().filter(\.$id == id)
    }
    
    func create(_ model: Blog) async throws {
        try await req.user.$blog.create(model, on: req.db)
    }

    func owned(_ id: Blog.IDValue) async throws -> Blog {
        let result = try await req.user.$blog.query(on: req.db)
            .filter(\.$id == id)
            .first()
            
        guard let result = result else {
            throw Abort(.notFound)
        }
        return result
    }
    
    func delete(_ id: Blog.IDValue) async throws {
        try await query(id).delete()
    }
    
    func save(_ model: Blog) async throws {
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
    static let blog: RepositoryID = "blog"
}

extension RepositoryFactory {

    var blog: BlogRepository {
        guard let result = repository(.blog) as? BlogRepository else {
            fatalError("Blog repository is not configured")
        }
        return result
    }
}
