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
        
        init() {
            id = nil
            alias = ""
            title = ""
            artworkUrl = nil
            excerpt = ""
            tags = nil
            content = nil
            createdAt = nil
            updatedAt = nil
            userId = nil
            categories = []
        }
    }
    
    convenience init(from dto: SerializedObject) throws {
        self.init()
        id = dto.id
        alias = dto.alias
        title = dto.title
        artworkUrl = dto.artworkUrl?.path
        excerpt = dto.excerpt
        tags = dto.tags
        
        // Set default value for `contentUrl`
        contentUrl = ""
    }
    
    func dataTransferObject() throws -> SerializedObject {
        var dataTransferObject = SerializedObject.init()
        dataTransferObject.id = try requireID()
        dataTransferObject.alias = alias
        dataTransferObject.title = title
        dataTransferObject.artworkUrl = artworkUrl?.absoluteURLString
        dataTransferObject.excerpt = excerpt
        dataTransferObject.tags = tags
        dataTransferObject.createdAt = $createdAt.timestamp
        dataTransferObject.updatedAt = $updatedAt.timestamp
        dataTransferObject.userId = $user.id
        dataTransferObject.categories = $categories.value?.compactMap({ try? $0.dataTransferObject() }) ?? []
        return dataTransferObject
    }
}

// MARK: Updatable
extension Blog: Updatable {
    
    @discardableResult
    func update(with dataTrasferObject: SerializedObject) throws -> Blog {
        title = dataTrasferObject.title
        alias = dataTrasferObject.alias
        artworkUrl = dataTrasferObject.artworkUrl?.path
        excerpt = dataTrasferObject.excerpt
        tags = dataTrasferObject.tags
        // TODO: -- content url
        contentUrl = ""
        return self
    }
}

extension Blog: UserOwnable {
    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }
    
    var _$user: Parent<User> { return $user }
}
