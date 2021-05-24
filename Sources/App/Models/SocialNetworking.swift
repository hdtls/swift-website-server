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

extension SocialNetworking: Serializing {
    typealias SerializedObject = Coding
    
    struct Coding: Content, Equatable {
        var id: SocialNetworking.IDValue?
        var userId: User.IDValue?
        var url: String
        
        /// `ID` of `service` is require for create referance with `SocialNetworkingService`
        var service: Service.Coding?
        
        init() {
            id = nil
            userId = nil
            url = ""
            service = nil
        }
    }
    
    convenience init(from dto: SerializedObject) throws {
        guard let serviceID = dto.service?.id else {
            throw Abort.init(.badRequest, reason: "Value required for key 'service.id'")
        }
        
        self.init()
        url = dto.url
        $service.id = serviceID
    }
    
    func dataTransferObject() throws -> SerializedObject {
        var dataTransferObject = SerializedObject.init()
        dataTransferObject.id = try requireID()
        dataTransferObject.userId = $user.id
        dataTransferObject.url = url
        dataTransferObject.service = try $service.value?.dataTransferObject()
        return dataTransferObject
    }
}

extension SocialNetworking: Updatable {
    
    // Only `url` property can be update.
    @discardableResult
    func update(with dataTransferObject: SerializedObject) throws -> SocialNetworking {
        url = dataTransferObject.url
        return self
    }
}

extension SocialNetworking: UserOwnable {
    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }
    
    var _$user: Parent<User> {
        return $user
    }
}
