import Foundation

import struct NIO.ByteBuffer
import enum NIO.Endianness

protocol ImageSerializing {
    var fileExtension: String { get }
    func validate(_ byteBuffer: ByteBuffer) -> Bool
    func dimensions(_ byteBuffer: ByteBuffer) -> String
}

enum ImageSerializer: String, ImageSerializing {
    case png
    case jpg
    case bmp
    case gif

    var fileExtension: String {
        rawValue
    }

    func validate(_ byteBuffer: ByteBuffer) -> Bool {
        var byteBuffer = byteBuffer

        switch self {
        case .png:
            byteBuffer.moveReaderIndex(to: 1)

            guard byteBuffer.readString(length: 7, encoding: .ascii) == "PNG\r\n\u{1a}\n" else {
                return false
            }

            byteBuffer.moveReaderIndex(forwardBy: 4)

            var trunkName = byteBuffer.readString(length: 4, encoding: .ascii)
            if trunkName == "CgBI" {
                trunkName = byteBuffer.readString(length: 4, encoding: .ascii)
            }
            if trunkName != "IHDR" {
                // TODO: Error throw invalid png buffer.
                return false
            }
            return true
        case .bmp:
            return byteBuffer.readString(length: 2, encoding: .ascii) == "BM"
        case .gif:
            let signature = byteBuffer.readString(length: 6, encoding: .ascii)
            return signature?.range(of: "GIF8[79]a", options: .regularExpression) != nil
        default:
            return false
        }
    }

    func dimensions(_ byteBuffer: ByteBuffer) -> String {
        var byteBuffer = byteBuffer

        switch self {
        case .png:
            byteBuffer.moveReaderIndex(to: 12)
            let boolean = byteBuffer.readString(length: 4, encoding: .ascii) == "CgBI"
            return boolean
                ? _formattedSize(byteBuffer, offset: 16, as: UInt32.self)
                : _formattedSize(byteBuffer, offset: 0, as: UInt32.self)
        case .bmp:
            return _formattedSize(byteBuffer, offset: 18, endianess: .little, as: Int32.self)
        case .gif:
            return _formattedSize(byteBuffer, offset: 6, endianess: .little, as: UInt16.self)
        default:
            return "0x0"
        }
    }
}

class ImageSerializerFactory {

    static var `default`: ImageSerializerFactory = .init()

    private let _hashTable: [UInt8 : ImageSerializing] = [
        //    0x38 : "psd",
        //    0x42 : "bmp",
        //    0x44 : "dds",
        0x47 : ImageSerializer.gif,
        //    0x49 : "tiff",
        //    0x4d : "tiff",
        //    0x52 : "webp",
        //    0x69 : "icns",
        0x89 : ImageSerializer.png,
        //    0xff : "jpg"
    ]

    private var _keyedSerializer: [String : ImageSerializing] = [:]

    func register(_ serializer: ImageSerializing) {
        _keyedSerializer[serializer.fileExtension] = serializer
    }

    func serializer(for byteBuffer: ByteBuffer) -> ImageSerializing? {
        var mutableBufferCopy = byteBuffer

        let key: UInt8 = mutableBufferCopy.readInteger()!

        if let serializer = _hashTable[key] {
            if serializer.validate(byteBuffer) {
                return serializer
            }
        }

        return _keyedSerializer.values.first(where: {
            $0.validate(byteBuffer)
        })
    }
}

fileprivate func _formattedSize<T: FixedWidthInteger>(
    _ byteBuffer: ByteBuffer,
    offset: Int,
    endianess: Endianness = .big,
    as type: T.Type) -> String {
    var byteBuffer = byteBuffer
    byteBuffer.moveReaderIndex(forwardBy: offset)

    let width = byteBuffer.readInteger(endianness: endianess, as: type)!
    let height = byteBuffer.readInteger(endianness: endianess, as: type)!
    return "\(width)x\(height)"
}
