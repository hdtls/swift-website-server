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

    @OptionalField(key: FieldKeys.screenName.rawValue)
    var screenName: String?

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
    var eduExps: [EducationalExp]

    @Children(for: \.$user)
    var workExps: [WorkExp]

    @Children(for: \.$user)
    var skill: [Skill]

    @OptionalField(key: FieldKeys.hobbies.rawValue)
    var hobbies: [String]?

    // MARK: Initializer
    required init() {}

    init(
        id: User.IDValue? = nil,
        username: String,
        pwd: String,
        firstName: String,
        lastName: String,
        screenName: String? = nil,
        avatarUrl: String? = nil,
        phone: String? = nil,
        emailAddress: String? = nil,
        aboutMe: String? = nil,
        location: String? = nil,
        hobbies: [String]? = nil
    ) {
        self.id = id
        self.username = username
        self.pwd = pwd
        self.firstName = firstName
        self.lastName = lastName
        self.screenName = screenName
        self.avatarUrl = avatarUrl
        self.phone = phone
        self.emailAddress = emailAddress
        self.aboutMe = aboutMe
        self.location = location
        self.hobbies = hobbies
    }
}

// MARK: Field keys
extension User {

    enum FieldKeys: FieldKey {
        case username
        case pwd
        case firstName = "first_name"
        case lastName = "last_name"
        case screenName = "screen_name"
        case avatarUrl = "avatar_url"
        case phone
        case emailAddress = "email_address"
        case aboutMe = "about_me"
        case location
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case hobbies
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
        /// - note: For decoding we will query default logged in user's username instead.
        var username: String?
        var firstName: String
        var lastName: String
        var screenName: String?
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
        var eduExps: [EducationalExp.Coding]?

        /// Experiances
        var workExps: [WorkExp.Coding]?

        var skill: Skill.Coding?

        var hobbies: [String]?
    }

    convenience init(content: SerializedObject) {
        self.init()
        firstName = content.firstName
        lastName = content.lastName
        screenName = content.screenName
        phone = content.phone
        emailAddress = content.emailAddress
        aboutMe = content.aboutMe
        location = content.location
        hobbies = content.hobbies
    }
    
    func reverted() throws -> SerializedObject {
        var coding = SerializedObject.init(firstName: firstName, lastName: lastName)
        coding.id = try requireID()
        coding.username = username
        coding.screenName = screenName
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
        coding.hobbies = hobbies
        return coding
    }
}

extension User: Mergeable {

    func merge(_ other: User) {
        firstName = other.firstName
        lastName = other.lastName
        screenName = other.screenName
        avatarUrl = other.avatarUrl
        phone = other.phone
        emailAddress = other.emailAddress
        aboutMe = other.aboutMe
        location = other.location
        hobbies = other.hobbies
    }
}
