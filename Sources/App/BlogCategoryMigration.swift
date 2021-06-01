import Fluent

extension BlogCategory {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(BlogCategory.schema)
                .id()
                .field(FieldKeys.name.rawValue, .string, .required)
                .unique(on: FieldKeys.name.rawValue)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(BlogCategory.schema).delete()
        }
    }
}
