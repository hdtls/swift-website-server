import Fluent

extension Education {

    static let migration: Migration = .init()

    class Migration: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(Education.schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.user, .int, .references(User.schema, .id))
                .field(FieldKeys.school, .string, .required)
                .field(FieldKeys.degree, .string, .required)
                .field(FieldKeys.field, .string, .required)
                .field(FieldKeys.startYear, .string)
                .field(FieldKeys.endYear, .string)
                .field(FieldKeys.grade, .string)
                .field(FieldKeys.activities, .array(of: .string))
                .field(FieldKeys.accomplishments, .array(of: .string))
                .field(FieldKeys.media, .string)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Education.schema).delete()
        }
    }
}
