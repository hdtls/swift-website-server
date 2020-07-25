import Fluent

extension WorkExpIndustrySiblings {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WorkExpIndustrySiblings.schema)
                .id()
                .field(FieldKeys.workExp.rawValue, .uuid, .required)
                .field(FieldKeys.industry.rawValue, .uuid, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(WorkExpIndustrySiblings.schema).delete()
        }
    }
}
