import Vapor
import FluentMySQLDriver

final class BlogCategory: Model {

    typealias IDValue = UUID

    static var schema: String = "blog_categories"

    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.name.rawValue)
    var name: String

    init() {}

    init(id: IDValue?, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: FieldKeys
extension BlogCategory {
    enum FieldKeys: FieldKey {
        case name
    }
}

extension BlogCategory: Equatable {
    static func ==(lhs: BlogCategory, rhs: BlogCategory) -> Bool {
        return lhs.id == rhs.id
    }
}

extension BlogCategory: Content, Serializing {
    typealias SerializedObject = BlogCategory

    enum CodingKeys: CodingKey {
        case id
        case name
    }

    convenience init(content: SerializedObject) throws {
        self.init(id: content.id, name: content.name)
    }

    func reverted() throws -> BlogCategory {
        self
    }
}

extension BlogCategory: Mergeable {

    func merge(_ other: BlogCategory) {
        name = other.name
    }
}
