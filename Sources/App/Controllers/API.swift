import Vapor

class API: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        routes.on(.GET, "resume", use: index)
    }

    func index(_ req: Request) -> Response {
        return req.fileio.streamFile(at: req.application.directory.publicDirectory + "resume.md")
    }
}
