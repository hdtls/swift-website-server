import Vapor
import FluentMySQLDriver

class BlogCategoryCollection: RestfulApiCollection {
    typealias T = BlogCategory

    func performUpdate(_ upgrade: BlogCategory, on req: Request) -> EventLoopFuture<BlogCategory> {
        upgrade.save(on: req.db)
            .flatMapErrorThrowing({
                if case MySQLError.duplicateEntry(let msg) = $0 {
                    throw Abort.init(.unprocessableEntity, reason: msg)
                }
                throw $0
            })
            .flatMapThrowing({
                try upgrade.reverted()
            })
    }
}
