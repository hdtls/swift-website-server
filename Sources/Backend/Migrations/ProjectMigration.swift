import Fluent

extension Project {
    
    static let migration: Migration = .init()
    
    class Migration: AsyncMigration {
        
        func prepare(on database: Database) async throws {
            let projectKinds = try await database.enum(ProjKind.schema)
                .case(ProjKind.app.rawValue)
                .case(ProjKind.website.rawValue)
                .case(ProjKind.library.rawValue)
                .create()

            let projectVisibilities = try await database.enum(ProjVisibility.schema)
                .case(ProjVisibility.private.rawValue)
                .case(ProjVisibility.public.rawValue)
                .create()

            try await database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.user, .int, .references(User.schema, .id))
                .field(FieldKeys.name, .string, .required)
                .field(FieldKeys.note, .string)
                .field(FieldKeys.genres, .array(of: .string))
                .field(FieldKeys.summary, .sql(raw: "VARCHAR(1024)"), .required)
                .field(FieldKeys.artworkUrl, .string)
                .field(FieldKeys.backgroundImageUrl, .string)
                .field(FieldKeys.promoImageUrl, .string)
                .field(FieldKeys.screenshotUrls, .array(of: .string))
                .field(FieldKeys.padScreenshotUrls, .array(of: .string))
                .field(FieldKeys.kind, projectKinds, .required)
                .field(FieldKeys.visibility, projectVisibilities, .required)
                .field(FieldKeys.trackViewUrl, .string)
                .field(FieldKeys.trackId, .string)
                .field(FieldKeys.startDate, .string, .required)
                .field(FieldKeys.endDate, .string, .required)
                .field(FieldKeys.isOpenSource, .bool, .required)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(schema).delete()
            try await database.enum(ProjKind.schema).delete()
            try await database.enum(ProjVisibility.schema).delete()
        }
    }
}
