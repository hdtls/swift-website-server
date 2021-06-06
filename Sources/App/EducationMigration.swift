import Fluent

extension Education {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Education.schema)
                .id()
                .field(FieldKeys.user, .uuid, .references(User.schema, .id))
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

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Education.schema).delete()
        }
    }
}
