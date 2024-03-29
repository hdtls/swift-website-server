import Fluent

extension Token {

    static let migration: Migration = .init()

    class Migration: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.user, .int, .references(User.schema, .id))
                .field(FieldKeys.token, .string, .required)
                .unique(on: FieldKeys.token)
                .field(FieldKeys.expiresAt, .datetime)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }
}
