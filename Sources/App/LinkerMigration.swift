import Fluent

extension Linker {
    
    static var migration: Migration {
            .init()
    }
    
    class Migration: Fluent.Migration {
        
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field("from", .int, .references(From.schema, .id))
                .field("to", .int, .references(To.schema, .id))
                .create()
        }
        
        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema).delete()
        }
    }
}
