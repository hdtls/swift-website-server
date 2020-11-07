import Fluent

extension BlogCategorySiblings {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(BlogCategorySiblings.schema)
                .id()
                .field(FieldKeys.category.rawValue, .uuid, .required)
                .field(FieldKeys.blog.rawValue, .uuid, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(BlogCategorySiblings.schema).delete()
        }
    }
}
