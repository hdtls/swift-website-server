import Fluent

extension Experience {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.title, .string, .required)
                .field(FieldKeys.companyName, .string, .required)
                .field(FieldKeys.location, .string)
                .field(FieldKeys.startDate, .string, .required)
                .field(FieldKeys.endDate, .string, .required)
                .field(FieldKeys.headline, .string)
                .field(FieldKeys.responsibilities, .array(of: .string))
                .field(FieldKeys.media, .string)
                .field(FieldKeys.user, .int, .references(User.schema, .id))
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema).delete()
        }
    }
}
