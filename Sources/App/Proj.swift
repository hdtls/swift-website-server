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
        
    static var schema: String = "projects"
    
    // MARK: Properties
    @ID()
    var id: UUID?
    
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
        
        init() {
            name = ""
            summary = ""
            kind = .app
            visibility = .public
            startDate = ""
            endDate = ""
        }
    }
    
    convenience init(from dto: SerializedObject) throws {
        self.init()
        id = dto.id
        name = dto.name
        note = dto.note
        genres = dto.genres
        summary = dto.summary
        artworkUrl = dto.artworkUrl?.path
        backgroundImageUrl = dto.backgroundImageUrl?.path
        promoImageUrl = dto.promoImageUrl?.path
        screenshotUrls = dto.screenshotUrls?.compactMap({ $0.path })
        padScreenshotUrls = dto.padScreenshotUrls?.compactMap({ $0.path })
        kind = dto.kind
        visibility = dto.visibility
        trackViewUrl = dto.trackViewUrl
        trackId = dto.trackId
        startDate = dto.startDate
        endDate = dto.endDate
    }
    
    func dataTransferObject() throws -> SerializedObject {
        var dataTransferObject = SerializedObject.init()
        dataTransferObject.id = try requireID()
        dataTransferObject.name = name
        dataTransferObject.note = note
        dataTransferObject.genres = genres
        dataTransferObject.summary = summary
        dataTransferObject.artworkUrl = artworkUrl?.absoluteURLString
        dataTransferObject.backgroundImageUrl = backgroundImageUrl?.absoluteURLString
        dataTransferObject.promoImageUrl = promoImageUrl?.absoluteURLString
        dataTransferObject.screenshotUrls = screenshotUrls?.compactMap({ $0.absoluteURLString })
        dataTransferObject.padScreenshotUrls = padScreenshotUrls?.compactMap({ $0.absoluteURLString })
        dataTransferObject.kind = kind
        dataTransferObject.visibility = visibility
        dataTransferObject.trackViewUrl = trackViewUrl
        dataTransferObject.trackId = trackId
        dataTransferObject.startDate = startDate
        dataTransferObject.endDate = endDate
        dataTransferObject.userId = $user.id
        return dataTransferObject
    }
}

extension Project: Updatable {
    
    @discardableResult
    func update(with dataTransferObject: SerializedObject) throws -> Project {
        name = dataTransferObject.name
        note = dataTransferObject.note
        genres = dataTransferObject.genres
        summary = dataTransferObject.summary
        artworkUrl = dataTransferObject.artworkUrl?.path
        backgroundImageUrl = dataTransferObject.backgroundImageUrl?.path
        promoImageUrl = dataTransferObject.promoImageUrl?.path
        screenshotUrls = dataTransferObject.screenshotUrls?.compactMap({ $0.path })
        padScreenshotUrls = dataTransferObject.padScreenshotUrls?.compactMap({ $0.path })
        kind = dataTransferObject.kind
        visibility = dataTransferObject.visibility
        trackViewUrl = dataTransferObject.trackViewUrl
        trackId = dataTransferObject.trackId
        startDate = dataTransferObject.startDate
        endDate = dataTransferObject.endDate
        return self
    }
}

extension Project: UserOwnable {
    var _$user: Parent<User> { return $user }
    
    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }
}
