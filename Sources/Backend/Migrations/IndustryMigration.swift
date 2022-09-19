import Fluent

extension Industry {

    static let migration: Migration = .init()

    class Migration: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.title, .string, .required)
                .unique(on: FieldKeys.title)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }
}
