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
                    database.schema(Project.schema)
                        .id()
                        .field(Project.uidFieldKey, .uuid, .references(User.schema, .id))
                        .field(FieldKeys.name.rawValue, .string, .required)
                        .field(FieldKeys.note.rawValue, .string)
                        .field(FieldKeys.genres.rawValue, .array(of: .string))
                        .field(FieldKeys.summary.rawValue, .sql(raw: "VARCHAR(1024)"), .required)
                        .field(FieldKeys.artworkUrl.rawValue, .string)
                        .field(FieldKeys.backgroundImageUrl.rawValue, .string)
                        .field(FieldKeys.promoImageUrl.rawValue, .string)
                        .field(FieldKeys.screenshotUrls.rawValue, .array(of: .string))
                        .field(FieldKeys.padScreenshotUrls.rawValue, .array(of: .string))
                        .field(FieldKeys.kind.rawValue, $0.0, .required)
                        .field(FieldKeys.visibility.rawValue, $0.1, .required)
                        .field(FieldKeys.trackViewUrl.rawValue, .string)
                        .field(FieldKeys.trackId.rawValue, .string)
                        .field(FieldKeys.startDate.rawValue, .string, .required)
                        .field(FieldKeys.endDate.rawValue, .string, .required)
                        .create()
                })
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Project.schema)
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
