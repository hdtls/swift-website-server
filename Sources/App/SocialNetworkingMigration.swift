import Fluent

extension SocialNetworking {

    static let migration: Migration = .init()
    
    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(SocialNetworking.schema)
                .id()
                .field(FieldKeys.user.rawValue, .uuid, .required)
                .field(FieldKeys.url.rawValue, .string, .required)
                .field(FieldKeys.service.rawValue, .uuid, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(SocialNetworking.schema).delete()
        }
    }
}
