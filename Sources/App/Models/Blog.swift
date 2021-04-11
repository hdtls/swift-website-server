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

    @Field(key: FieldKeys.excerpt.rawValue)
    var excerpt: String

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

    @Siblings(through: BlogCategorySiblings.self, from: \.$blog, to: \.$category)
    var categories: [BlogCategory]

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
        var excerpt: String
        var tags: [String]?

        // Content should be required property
        // but in encoding of `Route.readAll(_:)` content will be ignored
        var content: String?
        var createdAt: String?
        var updatedAt: String?

        // MARK: Relations
        var userId: User.IDValue?
        var categories: [BlogCategory.SerializedObject]
    }

    convenience init(content: SerializedObject) throws {
        self.init()
        id = content.id
        alias = content.alias
        title = content.title
        artworkUrl = content.artworkUrl?.path
        excerpt = content.excerpt
        tags = content.tags

        // Set default value for `contentUrl`
        contentUrl = ""
    }

    func reverted() throws -> SerializedObject {
        try SerializedObject.init(
            id: requireID(),
            alias: alias,
            title: title,
            artworkUrl: artworkUrl?.absoluteURLString,
            excerpt: excerpt,
            tags: tags,
            createdAt: $createdAt.timestamp,
            updatedAt: $updatedAt.timestamp,
            userId: $user.id,
            categories: $categories.value?.compactMap({ try? $0.reverted() }) ?? []
        )
    }
}

// MARK: Updatable
extension Blog: Updatable {

    func update(with other: Blog) {
        title = other.title
        alias = other.alias
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
