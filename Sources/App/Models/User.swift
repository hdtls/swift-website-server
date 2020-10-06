import Vapor
import Fluent

/// Login keys defination.
protocol Credentials {
    var username: String { get set }
    var password: String { get set }
}

final class User: Model {

    static let schema: String = "users"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.username.rawValue)
    var username: String

    @Field(key: FieldKeys.pwd.rawValue)
    var pwd: String

    @Field(key: FieldKeys.firstName.rawValue)
    var firstName: String

    @Field(key: FieldKeys.lastName.rawValue)
    var lastName: String

    @OptionalField(key: FieldKeys.avatarUrl.rawValue)
    var avatarUrl: String?

    @OptionalField(key: FieldKeys.phone.rawValue)
    var phone: String?

    @OptionalField(key: FieldKeys.emailAddress.rawValue)
    var emailAddress: String?

    @OptionalField(key: FieldKeys.aboutMe.rawValue)
    var aboutMe: String?

    @OptionalField(key: FieldKeys.location.rawValue)
    var location: String?

    @Timestamp(key: FieldKeys.createdAt.rawValue, on: .create)
    var createdAt: Date?

    @Timestamp(key: FieldKeys.updatedAt.rawValue, on: .update)
    var updatedAt: Date?

    // MARK: Relations
    @Children(for: \.$user)
    var tokens: [Token]

    @Children(for: \.$user)
    var social: [SocialNetworking]

    @Children(for: \.$user)
    var projects: [Project]

    @Children(for: \.$user)
    var eduExps: [Education]

    @Children(for: \.$user)
    var workExps: [Experience]

    @Children(for: \.$user)
    var skill: [Skill]

    @OptionalField(key: FieldKeys.interests.rawValue)
    var interests: [String]?

    // MARK: Initializer
    required init() {}

    init(
        id: User.IDValue? = nil,
        username: String,
        pwd: String,
        firstName: String,
        lastName: String,
        avatarUrl: String? = nil,
        phone: String? = nil,
        emailAddress: String? = nil,
        aboutMe: String? = nil,
        location: String? = nil,
        interests: [String]? = nil
    ) {
        self.id = id
        self.username = username
        self.pwd = pwd
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl
        self.phone = phone
        self.emailAddress = emailAddress
        self.aboutMe = aboutMe
        self.location = location
        self.interests = interests
    }
}

// MARK: Field keys
extension User {

    enum FieldKeys: FieldKey {
        case username
        case pwd
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
        case phone
        case emailAddress = "email_address"
        case aboutMe = "about_me"
        case location
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case interests
    }
}

// MARK: Authentication
extension User: ModelAuthenticatable {

    static var usernameKey = \User.$username
    static var passwordHashKey = \User.$pwd

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: pwd)
    }
}

extension Validatable where Self: Credentials {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...18))
    }
}

// MARK: User creation
extension User {

    struct Creation: Credentials, Content, Validatable {
        var firstName: String
        var lastName: String
        var username: String
        var password: String
    }

    convenience init(_ creation: Creation) throws {
        self.init(
            username: creation.username,
            pwd: try Bcrypt.hash(creation.password),
            firstName: creation.firstName,
            lastName: creation.lastName
        )
    }
}

// MARK: User coding helper.
extension User: Serializing {
    typealias SerializedObject = Coding

    /// `Coding` use for updata user and make response to user query.
    struct Coding: Content, Equatable {

        // MARK: Properties
        var id: User.IDValue?
        /// `username` is optional for decoding, required by encoding.
        /// - note: For decoding use logged in user's username instead.
        var username: String?
        var firstName: String
        var lastName: String
        var avatarUrl: String?
        var phone: String?
        var emailAddress: String?
        var aboutMe: String?
        var location: String?

        // MARK: Relations
        /// Links that user owned.
        /// - note: Only use for encoding user model.
        var social: [SocialNetworking.Coding]?

        /// Projects
        var projects: [Project.Coding]?

        /// Education experiances
        var eduExps: [Education.Coding]?

        /// Experiances
        var workExps: [Experience.Coding]?

        var skill: Skill.Coding?

        var interests: [String]?
    }

    convenience init(content: SerializedObject) {
        self.init()
        firstName = content.firstName
        lastName = content.lastName
        phone = content.phone
        emailAddress = content.emailAddress
        aboutMe = content.aboutMe
        location = content.location
        interests = content.interests
    }
    
    func reverted() throws -> SerializedObject {
        var coding = SerializedObject(firstName: firstName, lastName: lastName)
        coding.id = try requireID()
        coding.username = username
        coding.avatarUrl = avatarUrl?.absoluteURLString
        coding.phone = phone
        coding.emailAddress = emailAddress
        coding.aboutMe = aboutMe
        coding.location = location
        coding.social = $social.value?.compactMap({ try? $0.reverted() })
        coding.projects = $projects.value?.compactMap({ try? $0.reverted() })
        coding.eduExps = $eduExps.value?.compactMap({ try? $0.reverted() })
        coding.workExps = $workExps.value?.compactMap({ try? $0.reverted() })
        coding.social = $social.value?.compactMap({ try? $0.reverted() })
        coding.skill = try $skill.value?.first?.reverted()
        coding.interests = interests
        return coding
    }
}

extension User: Mergeable {

    func merge(_ other: User) {
        firstName = other.firstName
        lastName = other.lastName
        phone = other.phone
        emailAddress = other.emailAddress
        aboutMe = other.aboutMe
        location = other.location
        interests = other.interests
    }
}
