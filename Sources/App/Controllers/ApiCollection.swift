import Vapor

class ApiCollection: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.on(.GET, use: readAllApi)
    }

    func readAllApi(_ req: Request) throws -> EventLoopFuture<Response> {

        // create absolute file path
        let filePath = req.application.directory.resourcesDirectory + "docs/api.md"

        // check if file exists and is not a directory
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue else {
            throw Abort(.notFound)
        }

        // stream the file
        let res = req.fileio.streamFile(at: filePath)
        return req.eventLoop.makeSucceededFuture(res)
    }
}
