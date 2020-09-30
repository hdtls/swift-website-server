import Fluent

extension ExpIndustrySiblings {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(ExpIndustrySiblings.schema)
                .id()
                .field(FieldKeys.experience.rawValue, .uuid, .required)
                .field(FieldKeys.industry.rawValue, .uuid, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(ExpIndustrySiblings.schema).delete()
        }
    }
}
