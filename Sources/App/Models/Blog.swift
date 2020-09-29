import Vapor
import Fluent

final class Blog: Model {

    typealias IDValue = UUID

    static var schema: String = "blog"

    // MARK: Properties
    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.alias.rawValue)
    var alias: String

    @Field(key: FieldKeys.title.rawValue)
    var title: String

    @OptionalField(key: FieldKeys.artworkUrl.rawValue)
    var artworkUrl: String?

    @OptionalField(key: FieldKeys.excerpt.rawValue)
    var excerpt: String?

    @OptionalField(key: FieldKeys.tags.rawValue)
    var tags: [String]?

    @Field(key: FieldKeys.contentUrl.rawValue)
    var contentUrl: String

    @Timestamp(key: FieldKeys.createdAt.rawValue, on: .create, format: .iso8601)
    var createdAt: Date?

    @Timestamp(key: FieldKeys.updatedAt.rawValue, on: .update, format: .iso8601)
    var updatedAt: Date?

    // MARK: Relation
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    // MARK: Initializer
    init() {}
}

// MAKR: Field keys
extension Blog {
    enum FieldKeys: FieldKey {
        case title
        case alias
        case artworkUrl = "artwork_url"
        case excerpt
        case tags
        case contentUrl = "content_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user = "user_id"
    }
}

// MARK: Serializing
extension Blog: Serializing {

    typealias SerializedObject = Coding

    struct Coding: Content, Equatable {
        // `Blog` does not support auto generate id value.
        // This value is used as `Blog.id` and file identifier,
        var id: IDValue?
        var alias: String
        var title: String
        var artworkUrl: String?
        var excerpt: String?
        var tags: [String]?
        var content: String?
        var createAt: String?
        var updateAt: String?

        // MARK: Relations
        var userId: User.IDValue?
    }

    // require `content.userId` be setted before call this initializer.
    convenience init(content: SerializedObject) throws {
        self.init()
        id = content.id
        alias = content.alias
        title = content.title
        artworkUrl = content.artworkUrl?.path
        excerpt = content.excerpt
        tags = content.tags
        // Before save blog to db `contentUrl` is use to store content.
        // this value will upgrade to file url after `blog.content` is
        // writed to a local file.
        contentUrl = content.content ?? ""
    }

    func reverted() throws -> SerializedObject {
        try SerializedObject.init(
            id: requireID(),
            alias: alias,
            title: title,
            artworkUrl: artworkUrl?.absoluteURLString,
            excerpt: excerpt,
            tags: tags,
            content: nil,
            createAt: $createdAt.timestamp,
            updateAt: $updatedAt.timestamp,
            userId: $user.id
        )
    }
}

// MARK: Mergeable
extension Blog: Mergeable {

    func merge(_ other: Blog) {
        title = other.title
        artworkUrl = other.artworkUrl
        excerpt = other.excerpt
        tags = other.tags
        contentUrl = other.contentUrl
    }
}

extension Blog: UserOwnable {
    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }

    var _$user: Parent<User> { return $user }
}
