import Vapor
import Fluent

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
