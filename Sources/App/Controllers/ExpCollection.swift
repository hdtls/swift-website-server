import Vapor

class ExpCollection: RouteCollection {

    func boot(routes: RoutesBuilder) throws {
        try routes.group("exp") {
            try $0.register(collection: WorkExpCollection.init())
            try $0.register(collection: UserChildrenCollection<EducationalExp>.init(path: "edu"))
        }
    }
}
