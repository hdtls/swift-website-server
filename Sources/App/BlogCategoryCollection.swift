import Vapor
import FluentMySQLDriver

class BlogCategoryCollection: ApiCollection {
    typealias T = BlogCategory
    
    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.DTO> {
        let coding = try req.content.decode(T.DTO.self)

        var upgrade = T.init()
        
        if let original = original {
            upgrade = try original.update(with: coding)
        } else {
            upgrade = try T.init(from: coding)
            upgrade.id = nil
        }
        
        return upgrade.save(on: req.db)
            .flatMapErrorThrowing({
                if case MySQLError.duplicateEntry(let localizedErrorDescription) = $0 {
                    throw Abort.init(.unprocessableEntity, reason: localizedErrorDescription)
                }
                throw $0
            })
            .flatMapThrowing({
                try upgrade.dataTransferObject()
            })
    }
}
