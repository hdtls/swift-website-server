import Vapor
import FluentMySQLDriver

class IndustryCollection: ApiCollection {
    typealias T = Industry

    func performUpdate(_ original: T?, on req: Request) throws -> EventLoopFuture<T.DTO> {
        let coding = try req.content.decode(T.DTO.self)
        guard coding.title != nil else {
            throw Abort.init(.unprocessableEntity, reason: "Value required for key 'title'")
        }

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
