import Fluent

extension Skill {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema)
                .field(.id, .int, .identifier(auto: true))
                .field(FieldKeys.professional, .array(of: .string))
                .field(FieldKeys.workflow, .array(of: .string))
                .field(FieldKeys.user, .int, .references(User.schema, .id))
                .field(.createdAt, .datetime)
                .field(.updatedAt, .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(schema).delete()
        }
    }
}
