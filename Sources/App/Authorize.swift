import Fluent
import Vapor

extension FieldKey {
    
    static let createdAt: FieldKey = "created_at"
    static let updatedAt: FieldKey = "updated_at"
}

    /// Login keys defination.
protocol Credentials {
    var username: String { get set }
    var password: String { get set }
}

extension Validatable where Self: Credentials {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...18))
    }
}

extension User: ModelAuthenticatable {
    static var usernameKey: KeyPath<User, Field<String>> = \User.$username
    static var passwordHashKey: KeyPath<User, Field<String>> = \User.$pwd
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: pwd)
    }
}

extension User {
    
    struct Creation: Credentials, Content, Validatable {
        var firstName: String
        var lastName: String
        var username: String
        var password: String
    }
    
    convenience init(_ creation: Creation) throws {
        self.init()
        username = creation.username
        pwd = try Bcrypt.hash(creation.password, cost: 8)
        firstName = creation.firstName
        lastName = creation.lastName
    }
}
