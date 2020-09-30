import Vapor
import Fluent

final class Education: Model {

    typealias IDValue = UUID

    static var schema: String = "education"

    // MARK: Properties
    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.school.rawValue)
    var school: String

    @Field(key: FieldKeys.degree.rawValue)
    var degree: String

    @Field(key: FieldKeys.field.rawValue)
    var field: String

    @OptionalField(key: FieldKeys.startYear.rawValue)
    var startYear: String?

    @OptionalField(key: FieldKeys.endYear.rawValue)
    var endYear: String?

    @OptionalField(key: FieldKeys.grade.rawValue)
    var grade: String?

    @OptionalField(key: FieldKeys.activities.rawValue)
    var activities: [String]?

    @OptionalField(key: FieldKeys.accomplishments.rawValue)
    var accomplishments: [String]?

    @OptionalField(key: FieldKeys.media.rawValue)
    var media: String?

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    // MARK: Initializer
    init() {}
}

// MARK: Field keys
extension Education {

    enum FieldKeys: FieldKey {
        case school
        case degree
        case field = "field"
        case startYear = "start_year"
        case endYear = "end_year"
        case grade
        case activities
        case accomplishments
        case media
        case user = "user_id"
    }
}

extension Education: Serializing {
    typealias SerializedObject = Coding
    
    struct Coding: Content, Equatable {

        // MARK: Properties
        var id: IDValue?
        var school: String
        var degree: String
        var field: String
        var startYear: String?
        var endYear: String?
        var grade: String?
        var activities: [String]?
        var accomplishments: [String]?
        var media: String?

        // MARK: Relations
        var userId: User.IDValue?
    }

    convenience init(content: SerializedObject) throws {
        self.init()
        school = content.school
        degree = content.degree
        field = content.field
        startYear = content.startYear
        endYear = content.endYear
        grade = content.grade
        activities = content.activities
        accomplishments = content.accomplishments
        media = content.media
    }

    func reverted() throws -> Coding {
        try Coding.init(
            id: requireID(),
            school: school,
            degree: degree,
            field: field,
            startYear: startYear,
            endYear: endYear,
            grade: grade,
            activities: activities,
            accomplishments: accomplishments,
            media: media,
            userId: $user.id
        )
    }
}

extension Education: Mergeable {

    func merge(_ other: Education) {
        school = other.school
        degree = other.degree
        field = other.field
        startYear = other.startYear
        endYear = other.endYear
        grade = other.grade
        activities = other.activities
        accomplishments = other.accomplishments
        media = other.media
    }
}

extension Education: UserOwnable {
    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }

    var _$user: Parent<User> {
        return $user
    }
}
