import Fluent

extension SocialNetworking {

    static let migration: Migration = .init()
    
    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema)
                .id()
                .field(FieldKeys.user, .uuid, .required)
                .field(FieldKeys.url, .string, .required)
                .field(FieldKeys.service, .uuid, .required)
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema).delete()
        }
    }
}
