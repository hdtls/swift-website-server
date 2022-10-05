import Vapor

enum MediaType: String {
    case image = "images"
    case file = "files"
}

func saveFile(from req: Request, as type: MediaType) async throws -> String {
    let multipartFormData = try req.content.decode(MultipartFormData.self)
    let buffer: ByteBuffer
    let filename: String
    var fileURL: URL

    switch type {
        case .image:
            guard let multipartImage = multipartFormData.image else {
                throw Abort(.badRequest, reason: "Invalid image buffer.")
            }

            var url = URL(
                fileURLWithPath: type.rawValue,
                relativeTo: URL(fileURLWithPath: req.application.directory.publicDirectory)
            )

            var prefix = multipartImage.filename.prefix(8)

            // Add subpath with filename slices.
            let maxLength = 2
            while prefix.count >= maxLength {
                url.appendPathComponent(String(prefix.prefix(maxLength)))
                prefix.removeFirst(maxLength)
            }

            buffer = multipartImage.data
            filename = multipartImage.filename
            fileURL = url

        case .file:
            guard let multipartFile = multipartFormData.file else {
                throw Abort(.badRequest, reason: "Invalid file buffer.")
            }

            let url = URL(
                fileURLWithPath: type.rawValue,
                relativeTo: URL(fileURLWithPath: req.application.directory.publicDirectory)
            )
            buffer = multipartFile.data
            let contentHexEncodedString = Insecure.MD5.hash(data: Data(buffer: multipartFile.data))
                .hexEncodedString()
            filename =
                multipartFile.extension != nil
                ? "\(contentHexEncodedString).\(multipartFile.extension!)" : contentHexEncodedString
            fileURL = url
    }

    // Create any necessary intermediate directories.
    try? FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)

    fileURL.appendPathComponent(filename)

    // We use content hash as filename, so if file exists that mean it's duplicated
    // and we can ignored this write operation and just return exists file path.
    guard !FileManager.default.fileExists(atPath: fileURL.path) else {
        return "/\(fileURL.relativePath)"
    }

    try await req.fileio.writeFile(buffer, at: fileURL.path)

    return "/\(fileURL.relativePath)"
}
