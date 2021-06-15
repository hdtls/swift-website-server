import Fluent

extension SocialNetworking {

    static let migration: Migration = .init()
    
    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.user, .int, .required)
                .field(FieldKeys.url, .string, .required)
                .field(FieldKeys.service, .int, .required)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema).delete()
        }
    }
}
