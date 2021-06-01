import Fluent

extension User {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema)
                .id()
                .field(FieldKeys.username.rawValue, .string, .required)
                .unique(on: FieldKeys.username.rawValue)
                .field(FieldKeys.pwd.rawValue, .string, .required)
                .field(FieldKeys.firstName.rawValue, .string, .required)
                .field(FieldKeys.lastName.rawValue, .string, .required)
                .field(FieldKeys.avatarUrl.rawValue, .string)
                .field(FieldKeys.phone.rawValue, .string)
                .field(FieldKeys.emailAddress.rawValue, .string)
                .field(FieldKeys.aboutMe.rawValue, .sql(raw: "VARCHAR(1024)"))
                .field(FieldKeys.location.rawValue, .string)
                .field(FieldKeys.createdAt.rawValue, .datetime)
                .field(FieldKeys.updatedAt.rawValue, .datetime)
                .field(FieldKeys.interests.rawValue, .array(of: .string))
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(User.schema).delete()
        }
    }
}
