import Vapor
import Fluent

final class Skill: Model {
    
    typealias IDValue = UUID
    
    static var schema: String = "skills"
    
    @ID()
    var id: IDValue?
    
    @Field(key: FieldKeys.professional.rawValue)
    var professional: [String]
    
    @OptionalField(key: FieldKeys.workflow.rawValue)
    var workflow: [String]?
    
    @Parent(key: FieldKeys.user.rawValue)
    var user: User
    
    init() {}
}

extension Skill {
    
    enum FieldKeys: FieldKey {
        case professional
        case workflow
        case user = "user_id"
    }
}

extension Skill: Serializing {
    
    typealias SerializedObject = Coding
    
    struct Coding: Content, Equatable {
        
        var id: IDValue?
        var professional: [String]
        var workflow: [String]?
        
        init() {
            id = nil
            professional = []
            workflow = nil
        }
    }
    
    convenience init(from dto: SerializedObject) {
        self.init()
        professional = dto.professional
        workflow = dto.workflow
    }
    
    func dataTransferObject() throws -> SerializedObject {
        var dataTransferObject = SerializedObject.init()
        dataTransferObject.id = try requireID()
        dataTransferObject.professional = professional
        dataTransferObject.workflow = workflow
        return dataTransferObject
    }
}

extension Skill: Updatable {
    
    @discardableResult
    func update(with dataTrasferObject: SerializedObject) throws -> Skill {
        professional = dataTrasferObject.professional
        workflow = dataTrasferObject.workflow
        return self
    }
}

extension Skill: UserOwnable {
    static var uidFieldKey: FieldKey {
        return FieldKeys.user.rawValue
    }
    
    var _$user: Parent<User> {
        $user
    }
}
