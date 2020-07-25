import Fluent

extension SocialNetworkingService {

    static let migration: Migration = .init()

    class Migration: Fluent.Migration {

        func prepare(on database: Database) -> EventLoopFuture<Void> {

            var enumBuilder = database.enum(ServiceType.schema)

            SocialNetworkingService.ServiceType.allCases.forEach({
                enumBuilder = enumBuilder.case($0.rawValue)
            })

            return enumBuilder.create()
                .flatMap({
                    database.schema(SocialNetworkingService.schema)
                        .id()
                        .field(FieldKeys.type.rawValue, $0, .required)
                        .create()
                })
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            database.schema(SocialNetworkingService.schema).delete()
                .flatMap({
                    database.enum(ServiceType.schema).delete()
                })
        }
    }
}
