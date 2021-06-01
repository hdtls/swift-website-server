import Fluent

extension Blog {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Blog.schema)
                .id()
                .field(FieldKeys.alias.rawValue, .string, .required)
                .unique(on: FieldKeys.alias.rawValue)
                .field(FieldKeys.title.rawValue, .string, .required)
                .field(FieldKeys.artworkUrl.rawValue, .string)
                .field(FieldKeys.excerpt.rawValue, .string)
                .field(FieldKeys.tags.rawValue, .array(of: .string))
                .field(FieldKeys.contentUrl.rawValue, .string, .required)
                .field(FieldKeys.createdAt.rawValue, .string)
                .field(FieldKeys.updatedAt.rawValue, .string)
                .field(FieldKeys.user.rawValue, .uuid, .references(User.schema, .id))
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Blog.schema).delete()
        }
    }
}
