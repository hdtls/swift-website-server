import Vapor

extension Blog.DTO {

    mutating func beforeEncode() throws {
        artworkUrl = artworkUrl?.bucketURLString()
    }
}
