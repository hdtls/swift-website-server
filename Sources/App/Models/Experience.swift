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
    var industries: [Industry]

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
        var industries: [Industry.Coding]
        var userId: User.IDValue?
    }

    /// Convert `Coding` to `Experience`, used for decoding request content.
    /// - note: `user` and `industries` eager loading property will set on route operation.
    convenience init(from dto: Coding) throws {
        self.init()
        title = dto.title
        companyName = dto.companyName
        location = dto.location
        startDate = dto.startDate
        endDate = dto.endDate
        headline = dto.headline
        responsibilities = dto.responsibilities
        media = dto.media
    }

    func dataTransferObject() throws -> SerializedObject {
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
            industries: industries.compactMap({ try? $0.dataTransferObject() }),
            userId: $user.id
        )
    }
}

extension Experience: Updatable {

    @discardableResult
    func update(with dataTrasferObject: SerializedObject) throws -> Experience {
        title = dataTrasferObject.title
        companyName = dataTrasferObject.companyName
        location = dataTrasferObject.location
        startDate = dataTrasferObject.startDate
        endDate = dataTrasferObject.endDate
        headline = dataTrasferObject.headline
        responsibilities = dataTrasferObject.responsibilities
        media = dataTrasferObject.media
        return self
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
