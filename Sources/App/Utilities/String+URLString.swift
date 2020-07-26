import Vapor

extension String {
    var absoluteURLString: String {
        let proto = Environment.get("URL_PROTO") ?? "http://"
        let host = Environment.get("VIRTUAL_HOST") ?? "localhost:8080"
        return proto + host + self
    }

    var path: String? {
        return URL.init(string: self)?.path
    }
}
