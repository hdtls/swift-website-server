import Vapor

struct MultipartFormData: Codable {
    var multipart: [Data]
}

func uploadMultipleFiles(
    _ req: Request,
    path: String = "images"
) throws -> EventLoopFuture<[String]> {

    let multipartFormData = try req.content.decode(MultipartFormData.self)

    guard !multipartFormData.multipart.isEmpty else {
        throw Abort(.badRequest)
    }

    let fileDescriptors: [(Data, String)] = try multipartFormData.multipart.map({
        let filename = Insecure.MD5.hash(data: $0).hex
        var substring = filename.prefix(6)
        var filepath = path + "/"

        let maxLength = 2
        while substring.count >= maxLength {
            filepath += substring.prefix(maxLength) + "/"
            substring.removeFirst(maxLength)
        }

        try FileManager.default.createDirectory(
            atPath: req.application.directory.publicDirectory + filepath,
            withIntermediateDirectories: true
        )

        // TODO: Decode file extension from formdata.
        let fileExtension = path == "images" ? ".jpg" : ""
        filepath += filename + fileExtension
        return ($0, filepath)
    })

    return EventLoopFuture<Void>.andAllSucceed(fileDescriptors.map({
        req.fileio.writeFile(.init(data: $0.0), at: req.application.directory.publicDirectory + $0.1)
    }), on: req.eventLoop)
    .map({
        fileDescriptors.map({
            "/" + $0.1
        })
    })
}

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

    func create(_ req: Request) throws -> EventLoopFuture<[String]> {
        try uploadMultipleFiles(req).flatMapEachThrowing({ $0.absoluteURLString })
    }

    /// Query file  at path `url` in public fold.
    func read(_ req: Request) -> Response {
        return req.fileio.streamFile(at: req.application.directory.publicDirectory + req.url.string)
    }
}
