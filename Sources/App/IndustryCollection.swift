import FluentMySQLDriver
import Vapor

class IndustryCollection: ApiCollection {
    typealias T = Industry

    func performUpdate(_ original: T?, on req: Request) async throws -> T.DTO {
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

        do {
            try await upgrade.save(on: req.db)
        } catch {
            if case MySQLError.duplicateEntry(let localizedErrorDescription) = error {
                throw Abort.init(.unprocessableEntity, reason: localizedErrorDescription)
            }
            throw error
        }
        return try upgrade.dataTransferObject()
    }
}
