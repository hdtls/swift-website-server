import Vapor
import Fluent

final class Project: Model {
    typealias IDValue = UUID

    static var schema: String = "projects"

    // MARK: Properties
    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.name.rawValue)
    var name: String

    @OptionalField(key: FieldKeys.genres.rawValue)
    var genres: [String]?

    @Field(key: FieldKeys.summary.rawValue)
    var summary: String

    @OptionalField(key: FieldKeys.artworkUrl.rawValue)
    var artworkUrl: String?

    @OptionalField(key: FieldKeys.screenshotUrls.rawValue)
    var screenshotUrls: [String]?

    @Field(key: FieldKeys.kind.rawValue)
    var kind: Kind

    @Field(key: FieldKeys.startDate.rawValue)
    var startDate: String

    @Field(key: FieldKeys.endDate.rawValue)
    var endDate: String

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    init() {}
}

// MARK: FieldKeys
extension Project {

    enum FieldKeys: FieldKey {
        case name
        case genres
        case summary
        case artworkUrl = "artwork_url"
        case screenshotUrls = "screenshot_urls"
        case kind
        case startDate = "start_date"
        case endDate = "end_date"
        case user = "user_id"
    }
}

extension Project {
    enum Kind: String, CaseIterable, Codable {
        static let schema: String = "proj_kind"

        case software
    }
}

extension Project: Serializing {

    typealias SerializedObject = Coding

    struct Coding: Content, Equatable {
        var id: IDValue?
        var name: String
        var genres: [String]?
        var summary: String
        var artworkUrl: String?
        var screenshotUrls: [String]?
        var kind: Kind
        var startDate: String
        var endDate: String

        // MARK: Relations
        var userId: User.IDValue?
    }

    convenience init(content: SerializedObject) throws {
        self.init()
        id = content.id
        name = content.name
        genres = content.genres
        summary = content.summary
        artworkUrl = content.artworkUrl?.path
        screenshotUrls = content.screenshotUrls?.compactMap({ $0.path })
        kind = content.kind
        startDate = content.startDate
        endDate = content.endDate
    }

    func reverted() throws -> SerializedObject {
        try SerializedObject.init(
            id: requireID(),
            name: name,
            genres: genres,
            summary: summary,
            artworkUrl: artworkUrl?.absoluteURLString,
            screenshotUrls: screenshotUrls?.map({ $0.absoluteURLString }),
            kind: kind,
            startDate: startDate,
            endDate: endDate,
            userId: $user.id
        )
    }
}

extension Project: Mergeable {

    func merge(_ other: Project) {
        name = other.name
        genres = other.genres
        summary = other.summary
        artworkUrl = other.artworkUrl
        screenshotUrls = other.screenshotUrls
        kind = other.kind
        startDate = other.startDate
        endDate = other.endDate
    }
}
