import Vapor
import Fluent

/// Restful style api defination.
/// by default it provide `CRUD` method if `T.IDValue` is `LosslessStringConvertible`
protocol RestfulApi {
    associatedtype T: Model, Serializing, Mergeable

    /// ID path for uri
    var restfulIDKey: String { get }

    /// Create new model
    /// This operation will decode request content with `T.SerializedObject` and transfer it to type `T`
    /// then save to db after that a saved model reverted object will be return for user.
    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject>

    /// Read model by given `id`.
    /// This operation will request model id as parameter, if db don't have a model type with `T`
    /// and id equal to `id` a `404 notFound` will be send to user, otherwise return model's
    /// reverted object to user.
    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject>

    /// Read all model type with `T`.
    /// Query all models and return all model reverted object to user.
    func readAll(_ req: Request) throws -> EventLoopFuture<[T.SerializedObject]>

    /// Update a model with given `id`
    /// This operation will query model with `id` first, if there is no model return `404` error
    /// otherwise update that model with transfered new model, final return new model's reverted
    /// object to user.
    /// - warning: This operation will change db model value, be careful if you want do this.
    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject>

    /// Delete a model with given `id`
    /// First this operation will query model with `id`, if there is no model with `id` `404`
    /// error will be return otherwise delete model from db.
    /// - warning: This operation is dangerous it will delete mdoel from db and can't be
    /// reverted.
    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus>
}

extension RestfulApi {
    var restfulIDKey: String { "id" }
}

/// Default `CRUD` implementation.
extension RestfulApi where T.IDValue: LosslessStringConvertible {

    func create(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)
        let model = try T.init(content: coding)
        return model.save(on: req.db)
            .flatMapThrowing({
                try model.reverted()
            })
    }

    func read(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }

        return T.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ try $0.reverted() })
    }

    func readAll(_ req: Request) throws -> EventLoopFuture<[T.SerializedObject]> {
        return T.query(on: req.db)
            .all()
            .flatMapEachThrowing({ try $0.reverted() })
    }

    func update(_ req: Request) throws -> EventLoopFuture<T.SerializedObject> {
        let coding = try req.content.decode(T.SerializedObject.self)
        let upgrade = try T.init(content: coding)

        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort(.notFound)
        }

        return T.find(id, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap({ saved -> EventLoopFuture<T> in
                saved.merge(upgrade)
                let newValue = saved
                return newValue.update(on: req.db).map({ newValue })
            })
            .flatMapThrowing({
                try $0.reverted()
            })
    }

    func delete(_ req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let id = req.parameters.get(restfulIDKey, as: T.IDValue.self) else {
            throw Abort.init(.notFound)
        }
        return T.find(id, on: req.db)
            .unwrap(or: Abort.init(.notFound))
            .flatMap({
                $0.delete(on: req.db)
            })
            .map({ .ok })
    }
}
