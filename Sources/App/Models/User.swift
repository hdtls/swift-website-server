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
    var education: [Education]
    
    @Children(for: \.$user)
    var experiences: [Experience]
    
    @OptionalChild(for: \.$user)
    var skill: Skill?
    
    @Children(for: \.$user)
    var blog: [Blog]
    
    @OptionalField(key: FieldKeys.interests.rawValue)
    var interests: [String]?
    
    // MARK: Initializer
    required init() {}
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
        self.init()
        username = creation.username
        pwd = try Bcrypt.hash(creation.password)
        firstName = creation.firstName
        lastName = creation.lastName
    }
}

// MARK: User coding helper.
extension User: Serializing {
    typealias SerializedObject = Coding
    
    /// `Coding` use for updata user and make response to user query.
    struct Coding: Content, Equatable {
        
        // MARK: Properties
        var id: User.IDValue?
        var username: String
        var firstName: String
        var lastName: String
        var avatarUrl: String?
        var phone: String?
        var emailAddress: String?
        var aboutMe: String?
        var location: String?
        var interests: [String]?
        
        // MARK: Relations
        /// Links that user owned.
        /// - note: Only use for encoding user model.
        var social: [SocialNetworking.SerializedObject]?
        
        /// Projects
        var projects: [Project.SerializedObject]?
        
        /// Education experiances
        var education: [Education.SerializedObject]?
        
        /// Experiances
        var experiences: [Experience.SerializedObject]?
        
        var blog: [Blog.SerializedObject]?
        
        var skill: Skill.SerializedObject?
        
        init() {
            username = ""
            firstName = ""
            lastName = ""
        }
    }
    
    convenience init(from dto: SerializedObject) {
        self.init()
        username = dto.username
        firstName = dto.firstName
        lastName = dto.lastName
        avatarUrl = dto.avatarUrl?.path
        phone = dto.phone
        emailAddress = dto.emailAddress
        aboutMe = dto.aboutMe
        location = dto.location
        interests = dto.interests
    }
    
    func dataTransferObject() throws -> SerializedObject {
        var coding = SerializedObject()
        coding.username = username
        coding.firstName = firstName
        coding.lastName = lastName
        coding.id = try requireID()
        coding.avatarUrl = avatarUrl?.absoluteURLString
        coding.phone = phone
        coding.emailAddress = emailAddress
        coding.aboutMe = aboutMe
        coding.location = location
        coding.interests = interests
        coding.social = $social.value?.compactMap({ try? $0.dataTransferObject() })
        coding.projects = $projects.value?.compactMap({ try? $0.dataTransferObject() })
        coding.education = $education.value?.compactMap({ try? $0.dataTransferObject() })
        coding.experiences = $experiences.value?.compactMap({ try? $0.dataTransferObject() })
        coding.social = $social.value?.compactMap({ try? $0.dataTransferObject() })
        coding.blog = $blog.value?.compactMap({ try? $0.dataTransferObject() })
        coding.skill = try $skill.value??.dataTransferObject()
        return coding
    }
}

extension User: Updatable {
    
    @discardableResult
    func update(with dataTrasferObject: SerializedObject) throws -> User {
        username = dataTrasferObject.username
        firstName = dataTrasferObject.firstName
        lastName = dataTrasferObject.lastName
        avatarUrl = dataTrasferObject.avatarUrl?.path
        phone = dataTrasferObject.phone
        emailAddress = dataTrasferObject.emailAddress
        aboutMe = dataTrasferObject.aboutMe
        location = dataTrasferObject.location
        interests = dataTrasferObject.interests
        return self
    }
}
