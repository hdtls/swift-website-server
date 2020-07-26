import Fluent

extension Project {

    static let migration: Migration = .init()
    
    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            var enumBuilder = database.enum(Kind.schema)
            Kind.allCases.forEach({
                enumBuilder = enumBuilder.case($0.rawValue)
            })

            return enumBuilder.create()
                .flatMap({
                    database.schema(Project.schema)
                        .id()
                        .field(FieldKeys.user.rawValue, .uuid, .references(User.schema, .id))
                        .field(FieldKeys.name.rawValue, .string, .required)
                        .field(FieldKeys.genres.rawValue, .array(of: .string))
                        .field(FieldKeys.summary.rawValue, .string, .required)
                        .field(FieldKeys.artworkUrl.rawValue, .string)
                        .field(FieldKeys.screenshotUrls.rawValue, .array(of: .string))
                        .field(FieldKeys.kind.rawValue, $0, .required)
                        .field(FieldKeys.startDate.rawValue, .string, .required)
                        .field(FieldKeys.endDate.rawValue, .string, .required)
                        .create()
                })
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Project.schema)
                .delete()
                .flatMap({
                    database.enum(Kind.schema).delete()
                })
        }
    }
}
