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

        let trusted = routes.grouped([
            User.authenticator(),
            Token.authenticator(),
            User.guardMiddleware()
        ])

        trusted.on(.POST, body: .collect(maxSize: maximumBodySize), use: create)
    }

    func create(_ req: Request) throws -> EventLoopFuture<MultipartFileCoding> {
        switch type {
        case .images:
            return try uploadImageFile(req)
                .map {
                    MultipartFileCoding.init(url: $0.absoluteURLString)
                }
        default:
            return try uploadFile(req, relative: req.application.directory.publicDirectory)
                .map {
                    MultipartFileCoding.init(url: $0.absoluteURLString)
                }
        }
    }
}
