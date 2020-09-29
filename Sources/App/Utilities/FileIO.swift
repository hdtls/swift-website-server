import Vapor

extension FileIO {
    func writeFile(_ byteBuffer: ByteBuffer, path: String) -> EventLoopFuture<String> {

        let filepath = path.components(separatedBy: "/").dropLast().joined(separator: "/")
        try? FileManager.default.createDirectory(
            atPath: filepath,
            withIntermediateDirectories: true
        )
        print(filepath)
        return writeFile(byteBuffer, at: path).map({ path })
    }
}

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

    let futures = multipartFormData.multipart.map({ data -> EventLoopFuture<String> in

        var filepath = _filepath(data, relative: path)
        let byteBuffer = ByteBuffer.init(data: data)

        // TODO: Decode file extension from formdata.
        let fileExtension = path == "images" ? ".jpg" : ""
        filepath += fileExtension

        return req.fileio.writeFile(byteBuffer, path: req.application.directory.publicDirectory + filepath)
    })

    return EventLoopFuture.whenAllSucceed(futures, on: req.eventLoop)
}


/// Auto generate filepath with file content hash.
/// - Parameters:
///   - file: file data.
///   - path: relative path
/// - Returns: solved file location the value is a tuple of filename and directory.
fileprivate func _filepath(
    _ file: Data,
    relative path: String = ""
) -> String {

    var directory = path.hasSuffix("/") ? path : path + "/"

    let filename = Insecure.MD5.hash(data: file).hex

    var prefix = filename.prefix(6)

    // Add subpath with filename slices.
    let maxLength = 2
    while prefix.count >= maxLength {
        directory += prefix.prefix(maxLength) + "/"
        prefix.removeFirst(maxLength)
    }

    return directory + filename
}

func uploadImageFiles(_ req: Request) throws -> EventLoopFuture<[String]> {
    return try uploadMultipleFiles(req)
}
