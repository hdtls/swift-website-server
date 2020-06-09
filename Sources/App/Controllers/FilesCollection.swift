import Vapor

class FilesCollection: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.on(.GET, ":fileID", use: index)
    }

    func index(_ req: Request) -> Response {

        guard let fileID = req.parameters.get("fileID") else {
            return Response.init(status: .internalServerError)
        }

        return req.fileio.streamFile(at: req.application.directory.publicDirectory + fileID)
    }
}
