import Vapor
import Fluent

final class SocialNetworking: Model {

    static var schema: String = "social_networking"

    // MARK: Properties
    @ID()
    var id: UUID?

    @Field(key: FieldKeys.url.rawValue)
    var url: String

    // MARK: Relations
    @Parent(key: FieldKeys.user.rawValue)
    var user: User

    @Parent(key: FieldKeys.service.rawValue)
    var service: Service

    // MARK: Initializer
    required init() {}
}

// MARK: Field keys
extension SocialNetworking {

    enum FieldKeys: FieldKey {
        case user = "user_id"
        case url
        case service = "service_id"
    }
}

extension SocialNetworking: UserChildren {
    typealias SerializedObject = Coding

    var _$user: Parent<User> {
        return $user
    }

    struct Coding: Content, Equatable {
        var id: SocialNetworking.IDValue?
        var userId: User.IDValue?
        var url: String

        /// `ID` of `service` is require for create referance with `SocialNetworkingService`
        var service: Service.Coding?
    }

    convenience init(content: SerializedObject) throws {
        guard let serviceID = content.service?.id else {
            throw Abort.init(.badRequest, reason: "Value required for key 'service.id'")
        }

        self.init()
        url = content.url
        $service.id = serviceID
    }

    func reverted() throws -> SerializedObject {
        try SerializedObject.init(
            id: requireID(),
            userId: $user.id,
            url: url,
            service: service.reverted()
        )
    }
}

extension SocialNetworking: Mergeable {

    // Only `url` property can be update.
    func merge(_ other: SocialNetworking) {
        url = other.url
    }
}
