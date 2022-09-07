import Vapor

extension Blog {

    struct FrontMatter: Codable, Content {
        var id: Blog.IDValue?
        var alias: String
        var title: String
        var excerpt: String
        var tags: [String]?
        var categories: [BlogCategory.DTO]
    }

    var frontMatter: FrontMatter {
        get throws {
            try .init(
                id: id,
                alias: alias,
                title: title,
                excerpt: excerpt,
                categories: $categories.value?.map({ try $0.bridged() }) ?? []
            )
        }
    }

    static func fromFrontMatter(_ frontMatter: FrontMatter) -> Blog {
        let model = Blog.init()
        model.alias = frontMatter.alias
        model.title = frontMatter.title
        model.excerpt = frontMatter.excerpt
        model.tags = frontMatter.tags
        return model
    }
}
