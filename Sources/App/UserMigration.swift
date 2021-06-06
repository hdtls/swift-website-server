import Fluent

extension User {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema)
                .id()
                .field(FieldKeys.username, .string, .required)
                .unique(on: FieldKeys.username)
                .field(FieldKeys.pwd, .string, .required)
                .field(FieldKeys.firstName, .string, .required)
                .field(FieldKeys.lastName, .string, .required)
                .field(FieldKeys.avatarUrl, .string)
                .field(FieldKeys.phone, .string)
                .field(FieldKeys.emailAddress, .string)
                .field(FieldKeys.aboutMe, .sql(raw: "VARCHAR(1024)"))
                .field(FieldKeys.location, .string)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .field(FieldKeys.interests, .array(of: .string))
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema).delete()
        }
    }
}
