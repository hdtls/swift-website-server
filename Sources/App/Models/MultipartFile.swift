import Foundation
import Vapor

protocol MultipartFileProtocol {
    var filename: String { get set }
    var data: ByteBuffer { get set }
    var contentType: HTTPMediaType? { get }
    var `extension`: String? { get }

    init(data: ByteBuffer, filename: String)
}

extension MultipartFileProtocol {
    var contentType: HTTPMediaType? {
        return self.extension.flatMap({ HTTPMediaType.fileExtension($0.lowercased()) })
    }

    var `extension`: String? {
        let parts = filename.split(separator: ".")
        if parts.count > 1 {
            return parts.last.map(String.init)
        }
        return nil
    }
}

typealias MultipartFile = File
extension MultipartFile: MultipartFileProtocol {}

protocol MultipartImageProtocol: MultipartFileProtocol {
    var dimensions: String { get set }
}

struct MultipartImage: Codable, MultipartImageProtocol {

    /// Name of the image file. including extension.
    var filename: String

    /// The image file's data.
    var data: ByteBuffer

    var dimensions: String

    enum CodingKeys: String, CodingKey {
        case data, filename
    }

    /// `Decodable` conformance.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .data)
        var buffer = ByteBufferAllocator().buffer(capacity: 0)
        buffer.writeBytes(data)
        let filename = try container.decode(String.self, forKey: .filename)
        self.init(data: buffer, filename: filename)
    }

    /// `Encodable` conformance.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = self.data.getData(at: self.data.readerIndex, length: self.data.readableBytes)
        try container.encode(data, forKey: .data)
        try container.encode(self.filename, forKey: .filename)
    }

    init(data: ByteBuffer, filename: String) {
        self.data = data
        self.filename = filename
        self.dimensions = "0x0"

        var byteBuffer = data

        guard let serializer = ImageSerializerFactory.default.serializer(for: byteBuffer) else {
            return
        }

        let contentHash = Insecure.MD5.hash(data: byteBuffer.readData(length: byteBuffer.readableBytes)!)

        self.filename = "\(contentHash.hex).\(serializer.fileExtension)"
        self.dimensions = serializer.dimensions(data)
    }
}

extension MultipartImage: MultipartPartConvertible {

    var multipart: MultipartPart? {
        var part = MultipartPart(headers: .init(), body: .init(data.readableBytesView))
        part.contentType = self.extension
            .flatMap({ HTTPMediaType.fileExtension($0) })
            .flatMap({ $0.serialize() })
        return part
    }

    init?(multipart: MultipartPart) {
        guard let filename = multipart.filename else { return nil }
        self.init(data: multipart.body, filename: filename)
    }
}
