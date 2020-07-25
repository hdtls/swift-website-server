import Fluent

extension WorkExp {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WorkExp.schema)
                .id()
                .field(FieldKeys.title.rawValue, .string, .required)
                .field(FieldKeys.companyName.rawValue, .string, .required)
                .field(FieldKeys.location.rawValue, .string)
                .field(FieldKeys.startDate.rawValue, .string, .required)
                .field(FieldKeys.endDate.rawValue, .string, .required)
                .field(FieldKeys.headline.rawValue, .string)
                .field(FieldKeys.responsibilities.rawValue, .array(of: .string))
                .field(FieldKeys.media.rawValue, .string)
                .field(FieldKeys.user.rawValue, .uuid, .references(User.schema, .id))
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WorkExp.schema).delete()
        }
    }
}
