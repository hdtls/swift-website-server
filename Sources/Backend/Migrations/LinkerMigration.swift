import Fluent

extension Linker {

    static var migration: Migration {
        .init()
    }

    class Migration: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field("from", .int, .references(From.schema, .id))
                .field("to", .int, .references(To.schema, .id))
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }
}
