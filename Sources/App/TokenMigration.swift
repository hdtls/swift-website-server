import Fluent

extension Token {
    
    static let migration: Migration = .init()
    
    class Migration: Fluent.Migration {
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Token.schema)
                .id()
                .field(FieldKeys.user.rawValue, .uuid, .references(User.schema, .id))
                .field(FieldKeys.token.rawValue, .string, .required)
                .unique(on: FieldKeys.token.rawValue)
                .field(FieldKeys.expiresAt.rawValue, .date)
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Token.schema).delete()
        }
    }
}
