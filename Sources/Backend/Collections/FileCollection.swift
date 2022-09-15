import Vapor

class FileCollection: RouteCollection {

    let type: MediaType
    let maximumBodySize: ByteCount

    init(type: MediaType, maximumBodySize: ByteCount = "10mb") {
        self.type = type
        self.maximumBodySize = maximumBodySize
    }

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.init(stringLiteral: type.rawValue))

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware(),
        ])

        trusted.on(.POST, body: .collect(maxSize: maximumBodySize), use: create)
    }

    func create(_ req: Request) async throws -> [String : String] {
        let path = try await saveFile(from: req, as: type)
        return ["url" : path]
    }
}
