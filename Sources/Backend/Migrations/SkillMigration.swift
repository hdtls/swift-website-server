import Fluent

extension Skill {

    static let migration: Migration = .init()

    class Migration: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.professional, .array(of: .string))
                .field(FieldKeys.workflow, .array(of: .string))
                .field(FieldKeys.user, .int, .references(User.schema, .id))
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }
}
