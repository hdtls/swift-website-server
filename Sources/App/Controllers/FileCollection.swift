import Vapor

class FileCollection: RouteCollection {

    let path: String
    let maximumBodySize: ByteCount

    init(path: String, maximumBodySize: ByteCount = "1mb") {
        self.path = path
        self.maximumBodySize = maximumBodySize
    }

    func boot(routes: RoutesBuilder) throws {
        let routes = routes.grouped(.init(stringLiteral: path))

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

    func create(_ req: Request) throws -> EventLoopFuture<[String]> {
        try uploadMultipleFiles(req).flatMapEachThrowing({ $0.absoluteURLString })
    }
}
