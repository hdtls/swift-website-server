import Foundation
import Fluent

final class BlogCategorySiblings: Model {

    typealias IDValue = UUID

    static var schema: String = "blog_category_siblings"

    @ID()
    var id: IDValue?

    @Parent(key: FieldKeys.blog.rawValue)
    var blog: Blog

    @Parent(key: FieldKeys.category.rawValue)
    var category: BlogCategory

    init() {}
}

// MARK: FieldKeys
extension BlogCategorySiblings {

    enum FieldKeys: FieldKey {
        case blog = "blog_id"
        case category = "category_id"
    }
}
