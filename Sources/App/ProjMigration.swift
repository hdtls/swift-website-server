import Fluent

extension Project {

    static let migration: Migration = .init()
    
    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            var kindBuilder = database.enum(ProjKind.schema)
            ProjKind.allCases.forEach({
                kindBuilder = kindBuilder.case($0.rawValue)
            })

            var visibilityBuilder = database.enum(ProjVisibility.schema)
            ProjVisibility.allCases.forEach({
                visibilityBuilder = visibilityBuilder.case($0.rawValue)
            })

            return kindBuilder.create()
                .and(visibilityBuilder.create())
                .flatMap({
                    database.schema(schema)
                        .id()
                        .field(FieldKeys.user, .uuid, .references(User.schema, .id))
                        .field(FieldKeys.name, .string, .required)
                        .field(FieldKeys.note, .string)
                        .field(FieldKeys.genres, .array(of: .string))
                        .field(FieldKeys.summary, .sql(raw: "VARCHAR(1024)"), .required)
                        .field(FieldKeys.artworkUrl, .string)
                        .field(FieldKeys.backgroundImageUrl, .string)
                        .field(FieldKeys.promoImageUrl, .string)
                        .field(FieldKeys.screenshotUrls, .array(of: .string))
                        .field(FieldKeys.padScreenshotUrls, .array(of: .string))
                        .field(FieldKeys.kind, $0.0, .required)
                        .field(FieldKeys.visibility, $0.1, .required)
                        .field(FieldKeys.trackViewUrl, .string)
                        .field(FieldKeys.trackId, .string)
                        .field(FieldKeys.startDate, .string, .required)
                        .field(FieldKeys.endDate, .string, .required)
                        .field(.createdAt, .datetime)
                        .field(.updatedAt, .datetime)
                        .create()
                })
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema)
                .delete()
                .flatMap({
                    database.enum(ProjKind.schema).delete()
                })
                .flatMap({
                    database.enum(ProjVisibility.schema).delete()
                })
        }
    }
}
