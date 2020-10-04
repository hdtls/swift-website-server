import Vapor

extension FileIO {
    func writeFile(
        _ byteBuffer: ByteBuffer,
        path: String,
        relative: String
    ) -> EventLoopFuture<String> {
        let relative = relative.hasSuffix("/") ? String(relative.dropLast()) : relative

        let path = path.hasPrefix("/") ? path : "/" + path

        let directory = relative + path.split(separator: "/", omittingEmptySubsequences: false).dropLast().joined(separator: "/")

        try? FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true
        )

        let filepath = relative + path

        return writeFile(byteBuffer, at: filepath).map({ path })
    }
}

/// Auto generate filepath with file content hash.
/// - Parameters:
///   - file: file.
///   - path: relative path
/// - Returns: solved file location the value is a tuple of filename and directory.
fileprivate func _filepath(_ file: MultipartFileProtocol, relative: String = "") -> String {
    var directory = relative.hasSuffix("/") ? relative : relative + "/"

    var prefix = file.filename.prefix(8)

    // Add subpath with filename slices.
    let maxLength = 2
    while prefix.count >= maxLength {
        directory += prefix.prefix(maxLength) + "/"
        prefix.removeFirst(maxLength)
    }

    return directory + file.filename
}

struct MultipartFormData: Content {    
    var image: MultipartImage?
    var file: MultipartFile?
}

func uploadImageFile(_ req: Request) throws -> EventLoopFuture<String> {
    let multipartFormData = try req.content.decode(MultipartFormData.self)

    guard let multipartImage = multipartFormData.image else {
        throw Abort(.badRequest, reason: "Invalid image buffer.")
    }

    let filepath = _filepath(multipartImage, relative: "/images")

    return req.fileio.writeFile(
        multipartImage.data,
        path: filepath,
        relative: req.application.directory.publicDirectory
    )
}

func uploadFile(_ req: Request, relative path: String) throws -> EventLoopFuture<String> {
    let multipartFormData = try req.content.decode(MultipartFormData.self)
    guard let multipartFile = multipartFormData.file else {
        throw Abort(.badRequest, reason: "Invalid file buffer.")
    }

    let filepath = "/static/\(UUID().uuidString)\(multipartFile.extension != nil ? ".\(multipartFile.extension!)" : "")"

    return req.fileio.writeFile(
        multipartFile.data,
        path: filepath,
        relative: path
    )
}
