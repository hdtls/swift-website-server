import Fluent

extension Blog {

    static let migration: Migration = .init()

    class Migration: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(Blog.schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.alias, .string, .required)
                .unique(on: FieldKeys.alias)
                .field(FieldKeys.title, .string, .required)
                .field(FieldKeys.artworkUrl, .string)
                .field(FieldKeys.excerpt, .sql(raw: "VARCHAR(1024)"))
                .field(FieldKeys.tags, .array(of: .string))
                .field(FieldKeys.content, .string, .required)
                .field(FieldKeys.user, .int, .references(User.schema, .id))
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Blog.schema).delete()
        }
    }
}
