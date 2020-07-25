import Fluent

extension Industry {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Industry.schema)
                .id()
                .field(FieldKeys.title.rawValue, .string, .required)
                .unique(on: FieldKeys.title.rawValue)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(Industry.schema).delete()
        }
    }
}
