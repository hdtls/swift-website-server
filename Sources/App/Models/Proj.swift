import Vapor
import Fluent

enum ProjKind: String, CaseIterable, Codable {
    static let schema: String = "project_kinds"

    case app
    case website
    case repositry
}

enum ProjVisibility: String, CaseIterable, Codable {
    static let schema: String = "project_visibility"

    case `private`
    case `public`
}

protocol ProjProtocol {
    var name: String { get set }
    var note: String? { get set }
    var genres: [String]? { get set }
    var summary: String { get set }
    var artworkUrl: String? { get set }
    var backgroundImageUrl: String? { get set }
    var promoImageUrl: String? { get set }
    var screenshotUrls: [String]? { get set }
    var padScreenshotUrls: [String]? { get set }
    var kind: ProjKind { get set }
    var visibility: ProjVisibility { get set }
    var trackViewUrl: String? { get set }
    var trackId: String? { get set }
    var startDate: String { get set }
    var endDate: String { get set }
}

final class Project: ProjProtocol, Model {

    typealias IDValue = UUID

    static var schema: String = "projects"

    // MARK: Properties
    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.name.rawValue)
    var name: String

    @OptionalField(key: FieldKeys.note.rawValue)
    var note: String?

    @OptionalField(key: FieldKeys.genres.rawValue)
    var genres: [String]?

    @Field(key: FieldKeys.summary.rawValue)
    var summary: String

    @OptionalField(key: FieldKeys.artworkUrl.rawValue)
    var artworkUrl: String?

    @OptionalField(key: FieldKeys.backgroundImageUrl.rawValue)
    var backgroundImageUrl: String?

    @OptionalField(key: FieldKeys.promoImageUrl.rawValue)
    var promoImageUrl: String?

    @OptionalField(key: FieldKeys.screenshotUrls.rawValue)
    var screenshotUrls: [String]?

    @OptionalField(key: FieldKeys.padScreenshotUrls.rawValue)
    var padScreenshotUrls: [String]?

    @Field(key: FieldKeys.kind.rawValue)
    var kind: ProjKind

    @Field(key: FieldKeys.visibility.rawValue)
    var visibility: ProjVisibility

    @OptionalField(key: FieldKeys.trackViewUrl.rawValue)
    var trackViewUrl: String?

    @OptionalField(key: FieldKeys.trackId.rawValue)
    var trackId: String?

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
        case note
        case genres
        case summary
        case artworkUrl = "artwork_url"
        case backgroundImageUrl = "background_image_url"
        case promoImageUrl = "promo_image_url"
        case screenshotUrls = "screenshot_urls"
        case padScreenshotUrls = "pad_screenshot_urls"
        case kind
        case visibility
        case trackViewUrl = "track_view_url"
        case trackId = "track_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case user = "user_id"
    }
}

extension Project: Serializing {

    typealias SerializedObject = Coding

    struct Coding: ProjProtocol, Content, Equatable {
        var id: IDValue?
        var name: String
        var note: String?
        var genres: [String]?
        var summary: String
        var artworkUrl: String?
        var backgroundImageUrl: String?
        var promoImageUrl: String?
        var screenshotUrls: [String]?
        var padScreenshotUrls: [String]?
        var kind: ProjKind
        var visibility: ProjVisibility
        var trackViewUrl: String?
        var trackId: String?
        var startDate: String
        var endDate: String

        // MARK: Relations
        var userId: User.IDValue?
    }

    convenience init(content: SerializedObject) throws {
        self.init()
        name = content.name
        note = content.note
        genres = content.genres
        summary = content.summary
        kind = content.kind
        visibility = content.visibility
        trackViewUrl = content.trackViewUrl
        trackId = content.trackId
        startDate = content.startDate
        endDate = content.endDate
    }

    func reverted() throws -> SerializedObject {
        try SerializedObject.init(
            id: requireID(),
            name: name,
            note: note,
            genres: genres,
            summary: summary,
            artworkUrl: artworkUrl,
            backgroundImageUrl: backgroundImageUrl,
            promoImageUrl: promoImageUrl,
            screenshotUrls: screenshotUrls,
            padScreenshotUrls: padScreenshotUrls,
            kind: kind,
            visibility: visibility,
            trackViewUrl: trackViewUrl,
            trackId: trackId,
            startDate: startDate,
            endDate: endDate,
            userId: $user.id
        )
    }
}

extension Project: Mergeable {

    func merge(_ other: Project) {
        name = other.name
        note = other.note
        genres = other.genres
        summary = other.summary
        artworkUrl = other.artworkUrl?.path
        backgroundImageUrl = other.backgroundImageUrl?.path
        promoImageUrl = other.promoImageUrl
        screenshotUrls = other.screenshotUrls
        padScreenshotUrls = other.padScreenshotUrls
        kind = other.kind
        visibility = other.visibility
        trackViewUrl = other.trackViewUrl
        trackId = other.trackId
        startDate = other.startDate
        endDate = other.endDate
    }
}

extension Project: UserOwnable {
    var _$user: Parent<User> { return $user }

    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }
}
