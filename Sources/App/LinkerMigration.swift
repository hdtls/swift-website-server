import Fluent

extension Linker {
    
    static var migration: Migration {
            .init()
    }
    
    class Migration: Fluent.Migration {
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema)
                .id()
                .field("from", .uuid, .references(From.schema, .id))
                .field("to", .uuid, .references(To.schema, .id))
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema).delete()
        }
    }
}
