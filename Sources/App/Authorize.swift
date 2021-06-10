import Fluent
import Vapor

extension User: ModelAuthenticatable {
    static var usernameKey = \User.$username
    static var passwordHashKey = \User.$pwd
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: pwd)
    }
}

extension User {
    
    struct Creation: Content {
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

extension User.Creation: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...18))
    }
}

struct AuthorizedMsg: Content {
    
    let user: User.DTO
    var expiresAt: Date?
    let identityTokenString: String
    
    init(user: User, token: Token) throws {
        self.user = try user.dataTransferObject()
        self.expiresAt = token.expiresAt
        self.identityTokenString = token.token
    }
}

final class Token: Model {
    
    static let schema: String = "tokens"
    
        // MARK: Properties
    @ID()
    var id: UUID?
    
    @Field(key: FieldKeys.token.rawValue)
    var token: String
    
    @OptionalField(key: FieldKeys.expiresAt.rawValue)
    var expiresAt: Date?
    
        // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User
}

extension Token {
    
    enum FieldKeys: FieldKey {
        case user = "user_id"
        case token
        case expiresAt = "expires_at"
    }
}

extension Token: ModelTokenAuthenticatable {
    
    static var valueKey = \Token.$token
    static let userKey = \Token.$user
    
    var isValid: Bool {
        guard let expiryDate = expiresAt else {
            return true
        }
        return expiryDate > Date()
    }
}

extension Token {
    
    convenience init(_ user: User) throws {
        self.init()
        $user.id = try user.requireID()
        token = [UInt8].random(count: 16).base64
        expiresAt = Date().addingTimeInterval(60 * 60 * 24 * 30)
    }
}
