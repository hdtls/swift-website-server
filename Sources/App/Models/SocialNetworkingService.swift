import Vapor
import Fluent

typealias SocialNetworkingService = SocialNetworking.Service

extension SocialNetworking {
    final class Service: Model {

        static var schema: String = "social_networking_services"

        // MARK: Properties
        @ID()
        var id: UUID?

        @Enum(key: FieldKeys.type.rawValue)
        var type: ServiceType

        // MARK: Relations
        @Children(for: \.$service)
        var social: [SocialNetworking]

        // MARK: Initializer
        required init() {}
    }
}

// MARK: Field keys
extension SocialNetworkingService {

    enum FieldKeys: FieldKey {
        case type
    }
}

// MARK: Meida tpye defination
extension SocialNetworkingService {

    enum ServiceType: String, CaseIterable, Codable {
        static let schema: String = "sns_type"
        
        case facebook = "Facebook"
        case youTube = "YouTube"
        case twitter = "Twitter"
        case whatsApp = "WhatsApp"
        case messenger = "Facebook Messenger"
        case wechat = "WeChat"
        case instagram = "Instagram"
        case tikTok = "TikTok"
        case qq = "QQ"
        case qzone = "Qzone"
        case weibo = "Sina Weibo"
        case reddit = "Reddit"
        case kuaishou = "Kuaishou"
        case snapchat = "Snapchat"
        case pinterest = "Pinterest"
        case tieba = "Baidu Tieba"
        case linkedIn = "LinkedIn"
        case viber = "Viber"
        case discord = "Discord"
        case githup = "Github"
        case stackOverflow = "StackOverflow"
        case mail = "Mail"
        case website = "Website"
        case undefined
    }
}

extension SocialNetworkingService: Serializing {
    typealias SerializedObject = Coding

    struct Coding: Content, Equatable {
        var id: SocialNetworkingService.IDValue?

        // `type` is require by create new service ignored when create social networking.
        // so make it optional.
        var type: SocialNetworkingService.ServiceType?
    }

    convenience init(content: SerializedObject) {
        self.init()
        type = content.type ?? .undefined
    }

    func reverted() throws -> SerializedObject {
        try SerializedObject.init(
            id: requireID(),
            type: type
        )
    }
}

extension SocialNetworkingService: Mergeable {

    func merge(_ other: SocialNetworking.Service) {
        type = other.type
    }
}
