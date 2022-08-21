import Fluent
import Vapor

struct BlogRepository: Repository {

    typealias Model = Blog

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        let query = Blog.query(on: request.db).with(\.$categories)

        if owned {
            try query.filter(\.$user.$id == request.owner.__id)
        }

        return query
    }

    func queryAll(owned: Bool = false) throws -> QueryBuilder<Model> {
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

    func create(_ model: Model, categories: [BlogCategory]) async throws {
        try await request.owner.$blog.create(model, on: request.db)

        try await model.$categories.attach(categories, on: request.db)
        try await model.$categories.load(on: request.db)
    }

    func update(_ model: Model, categories: [BlogCategory]) async throws {
        try await model.save(on: request.db)

        try await model.$categories.detachAll(on: request.db)
        try await model.$categories.attach(categories, on: request.db)
        try await model.$categories.load(on: request.db)
    }

    func delete(_ id: Model.IDValue) async throws {
        let saved = try await query(id, owned: true).first()

        try await saved?.$categories.detachAll(on: request.db)

        try await saved?.delete(on: request.db)
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
