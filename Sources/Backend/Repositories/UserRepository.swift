import Fluent
import Vapor

struct UserRepository: Repository {

    var req: Request

    init(req: Request) {
        self.req = req
    }

    func query() -> QueryBuilder<User> {
        User.query(on: req.db)
    }

    func query(_ id: User.IDValue) -> QueryBuilder<User> {
        query().filter(\.$id == id)
    }

    func save(_ model: User) async throws {
        try await model.save(on: req.db)
    }

    func identified(by id: User.IDValue) async throws -> User {
        guard let result = try await query(id).first() else {
            throw Abort(.notFound)
        }
        return result
    }

    func formatted(by uname: String) async throws -> User {
        let saved = try await query()
            .filter(\.$username == uname)
            .with(\.$projects)
            .with(\.$education)
            .with(\.$experiences) {
                $0.with(\.$industries)
            }
            .with(\.$social) {
                $0.with(\.$service)
            }
            .with(\.$skill)
            .first()

        guard let saved = saved else {
            throw Abort(.notFound)
        }

        return saved
    }

    func delete(_ id: User.IDValue) async throws {
        try await query(id).delete()
    }
}

extension RepositoryID {
    static let user: RepositoryID = "user"
}

extension Request {

    var user: UserRepository {
        guard let result = registry.repository(.user, self) as? UserRepository else {
            fatalError("User repository is not configured")
        }
        return result
    }
}
