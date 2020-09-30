import Vapor
import Fluent

final class Experience: Model {

    typealias IDValue = UUID
    
    static let schema: String = "experiences"

    // MARK: Properties
    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.title.rawValue)
    var title: String

    @Field(key: FieldKeys.companyName.rawValue)
    var companyName: String

    @Field(key: FieldKeys.location.rawValue)
    var location: String

    @Field(key: FieldKeys.startDate.rawValue)
    var startDate: String

    @Field(key: FieldKeys.endDate.rawValue)
    var endDate: String

    @OptionalField(key: FieldKeys.headline.rawValue)
    var headline: String?

    @OptionalField(key: FieldKeys.responsibilities.rawValue)
    var responsibilities: [String]?

    @OptionalField(key: FieldKeys.media.rawValue)
    var media: String?

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    @Siblings(through: ExpIndustrySiblings.self, from: \.$experience, to: \.$industry)
    var industry: [Industry]

    // MARK: Initializer
    init() {}
}

// MARK: Field keys
extension Experience {

    enum FieldKeys: FieldKey {
        case title
        case companyName = "campany_name"
        case location
        case startDate = "start_date"
        case endDate = "end_date"
        case headline
        case responsibilities
        case media
        case user = "user_id"
    }
}

extension Experience: Serializing {

    typealias SerializedObject = Coding
    
    struct Coding: Content, Equatable {
        // MARK: Properties
        var id: Experience.IDValue?
        var title: String
        var companyName: String
        var location: String
        var startDate: String
        var endDate: String
        var headline: String?
        var responsibilities: [String]?
        var media: String?

        // MARK: Relations
        var industry: [Industry.Coding]
        var userId: User.IDValue?
    }

    /// Convert `Coding` to `Experience`, used for decoding request content.
    /// - note: `user` and `industry` eager loading property will set on route operation.
    convenience init(content: Coding) {
        self.init()
        title = content.title
        companyName = content.companyName
        location = content.location
        startDate = content.startDate
        endDate = content.endDate
        headline = content.headline
        responsibilities = content.responsibilities
        media = content.media
    }

    func reverted() throws -> SerializedObject {
        try Coding.init(
            id: requireID(),
            title: title,
            companyName: companyName,
            location: location,
            startDate: startDate,
            endDate: endDate,
            headline: headline,
            responsibilities: responsibilities,
            media: media,
            industry: industry.compactMap({ try? $0.reverted() }),
            userId: $user.id
        )
    }
}

extension Experience: Mergeable {

    func merge(_ other: Experience) {
        title = other.title
        companyName = other.companyName
        location = other.location
        startDate = other.startDate
        endDate = other.endDate
        headline = other.headline
        responsibilities = other.responsibilities
        media = other.media
    }
}

extension Experience: UserOwnable {
    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }
    
    var _$user: Parent<User> {
        return $user
    }
}
