import Fluent

extension Blog {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Blog.schema)
                .id()
                .field(FieldKeys.alias, .string, .required)
                .unique(on: FieldKeys.alias)
                .field(FieldKeys.title, .string, .required)
                .field(FieldKeys.artworkUrl, .string)
                .field(FieldKeys.excerpt, .string)
                .field(FieldKeys.tags, .array(of: .string))
                .field(FieldKeys.content, .string, .required)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .field(FieldKeys.user, .uuid, .references(User.schema, .id))
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Blog.schema).delete()
        }
    }
}
