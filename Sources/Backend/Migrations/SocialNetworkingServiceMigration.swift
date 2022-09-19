import Fluent

extension SocialNetworkingService {

    static let migration: Migration = .init()

    class Migration: AsyncMigration {

        func prepare(on database: Database) async throws {
            try await database.schema(SocialNetworkingService.schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.name, .string, .required)
                .unique(on: FieldKeys.name)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
        }
    }
}
