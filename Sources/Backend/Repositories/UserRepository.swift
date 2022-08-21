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

    func formatted(by uname: String) async throws -> Model {
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
