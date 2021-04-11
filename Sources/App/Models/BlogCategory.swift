import Vapor
import FluentMySQLDriver

final class BlogCategory: Model {

    typealias IDValue = UUID

    static var schema: String = "blog_categories"

    @ID()
    var id: IDValue?

    @Field(key: FieldKeys.name.rawValue)
    var name: String

    @Siblings(through: BlogCategorySiblings.self, from: \.$category, to: \.$blog)
    var blog: [Blog]

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

extension BlogCategory: Updatable {

    func update(with other: BlogCategory) {
        name = other.name
    }
}
