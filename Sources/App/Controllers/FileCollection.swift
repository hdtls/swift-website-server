import Vapor

class FileCollection: RouteCollection {

    enum MediaType: String {
        case images
        case files
    }

    let type: MediaType
    let maximumBodySize: ByteCount

    init(type: MediaType, maximumBodySize: ByteCount = "100mb") {
        self.type = type
        self.maximumBodySize = maximumBodySize
    }

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.init(stringLiteral: type.rawValue))

        routes.on(.GET, .anything, use: read)

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])

        trusted.on(.POST, body: .collect(maxSize: maximumBodySize), use: create)
    }

    func read(_ req: Request) throws -> EventLoopFuture<Response> {
        // make a copy of the path
        var path = req.url.path

        // path must be relative.
        while path.hasPrefix("/") {
            path = String(path.dropFirst())
        }

        // protect against relative paths
        guard !path.contains("../") else {
            return req.eventLoop.makeFailedFuture(Abort(.forbidden))
        }

        // create absolute file path
        let filePath = req.application.directory.publicDirectory + (path.removingPercentEncoding ?? path)

        // check if file exists and is not a directory
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
            throw Abort(.notFound)
        }

        return req.eventLoop.makeSucceededFuture(req.fileio.streamFile(at: filePath))
    }

    func create(_ req: Request) throws -> EventLoopFuture<String> {
        switch type {
        case .images:
            return try uploadImageFile(req).map { $0.absoluteURLString }
        default:
            return try uploadFile(req, relative: req.application.directory.publicDirectory).map { $0.absoluteURLString }
        }
    }
}
