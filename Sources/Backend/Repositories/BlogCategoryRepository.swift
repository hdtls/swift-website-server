import Fluent
import Vapor

struct BlogCategoryRepository: Repository {

    typealias Model = BlogCategory

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        Model.query(on: request.db)
    }
}

extension RepositoryFactoryKey {
    static let blogCategory: RepositoryFactoryKey = "blog_category"
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
