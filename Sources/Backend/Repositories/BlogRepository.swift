import Fluent
import Vapor

struct BlogRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Blog> {
        let query = Blog.query(on: req.db).with(\.$categories)

        if owned {
            try query.filter(\.$user.$id == req.owner.__id)
        }

        return query
    }

    func queryAll(owned: Bool = false) throws -> QueryBuilder<Blog> {
        try query(owned: owned)
            .field(\.$id)
            .field(\.$alias)
            .field(\.$title)
            .field(\.$artworkUrl)
            .field(\.$excerpt)
            .field(\.$tags)
            .field(\.$createdAt)
            .field(\.$updatedAt)
            .field(\.$user.$id)
    }

    func query(_ id: Blog.IDValue, owned: Bool = false) throws -> QueryBuilder<Blog> {
        try query(owned: owned).filter(\.$id == id)
    }

    func create(_ model: Blog, categories: [BlogCategory]) async throws {
        try await req.owner.$blog.create(model, on: req.db)

        try await model.$categories.attach(categories, on: req.db)
        try await model.$categories.load(on: req.db)
    }

    func identified(by id: Blog.IDValue, owned: Bool = false) async throws -> Blog {
        guard let result = try await query(id, owned: owned).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll(owned: Bool = false) async throws -> [Blog] {
        try await queryAll(owned: owned).all()
    }

    func update(_ model: Blog, categories: [BlogCategory]) async throws {
        try await model.save(on: req.db)

        try await model.$categories.detachAll(on: req.db)
        try await model.$categories.attach(categories, on: req.db)
        try await model.$categories.load(on: req.db)
    }

    func delete(_ id: Blog.IDValue) async throws {
        let saved = try await query(id, owned: true).first()

        try await saved?.$categories.detachAll(on: req.db)

        try await saved?.delete(on: req.db)
    }
}

extension RepositoryFactoryKey {
    static let blog: RepositoryFactoryKey = "blog"
}

extension Request {

    var blog: BlogRepository {
        guard let result = registry.repository(.blog, self) as? BlogRepository else {
            fatalError("Blog repository is not configured")
        }
        return result
    }
}
