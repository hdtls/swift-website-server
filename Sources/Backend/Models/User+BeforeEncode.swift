import Vapor

extension User.DTO {

    mutating func beforeEncode() throws {
        avatarUrl = avatarUrl?.bucketURLString()
        // Chain beforeEncode to nested content.
        projects = try projects?.map {
            var project = $0
            try project.beforeEncode()
            return project
        }

        blog = try blog?.map {
            var blog = $0
            try blog.beforeEncode()
            return blog
        }
    }
}
