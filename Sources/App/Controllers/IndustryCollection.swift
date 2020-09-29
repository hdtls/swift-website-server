import Vapor
import FluentMySQLDriver

class IndustryCollection: RestfulApiCollection {
    typealias T = Industry

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)
        guard coding.title != nil else {
            throw Abort.init(.unprocessableEntity, reason: "Value required for key 'industry.title'")
        }
        let industry = try T.init(content: coding)

        return performUpdate(industry, on: req)
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)

        guard coding.title != nil else {
            throw Abort.init(.unprocessableEntity, reason: "Value required for key 'industry.title'")
        }
        let upgrade = try T.init(content: coding)

        return try topLevelQueryBuilder(on: req)
            .first()
            .unwrap(or: Abort(.notFound))
            .flatMap({
                $0.merge(upgrade)
                return self.performUpdate($0, on: req)
            })
    }

    func performUpdate(_ upgrade: Industry, on req: Request) -> EventLoopFuture<Industry.Coding> {
        upgrade.save(on: req.db)
            .flatMapErrorThrowing({
                if case MySQLError.duplicateEntry = $0 {
                    throw Abort.init(.unprocessableEntity, reason: "Value for key 'industry.title' already taken.")
                }
                throw $0
            })
            .flatMapThrowing({
                try upgrade.reverted()
            })
    }
}
