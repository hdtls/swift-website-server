import Fluent
import Vapor

struct UserRepository: Repository {

    typealias Model = User

    var request: Request

    init(request: Request) {
        self.request = request
    }

    func query(owned: Bool = false) throws -> QueryBuilder<Model> {
        Model.query(on: request.db)
    }

    func identified(by id: Model.IDValue, queries: Model.Queries) async throws -> Model {
        guard let result = try await query(id).applyQueries(queries).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func identified(by name: String) async throws -> Model {
        let query = try query().filter(\.$username == name)
        guard let result = try await query.first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func identified(by name: String, queries: Model.Queries) async throws -> Model {
        let query = try query().filter(\.$username == name).applyQueries(queries)
        guard let result = try await query.first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func readAll(queries: Model.Queries) async throws -> [Model] {
        try await queryAll().applyQueries(queries).all()
    }
}

extension QueryBuilder where Model == User {

    fileprivate func applyQueries(_ queries: Model.Queries) throws -> QueryBuilder<Model> {
        if queries.includeExperience {
            with(\.$experiences) {
                $0.with(\.$industries)
            }
        }

        if queries.includeEducation {
            with(\.$education)
        }

        if queries.includeSNS {
            with(\.$social) {
                $0.with(\.$service)
            }
        }

        if queries.includeProjects {
            with(\.$projects)
        }

        if queries.includeSkill {
            with(\.$skill)
        }

        if queries.includeBlog {
            with(\.$blog) {
                $0.with(\.$categories)
            }
        }

        return self
    }
}

extension RepositoryFactoryKey {
    static let user: RepositoryFactoryKey = "user"
}

extension Request {

    var user: UserRepository {
        guard let result = registry.repository(.user, self) as? UserRepository else {
            fatalError("User repository is not configured")
        }
        return result
    }
}
