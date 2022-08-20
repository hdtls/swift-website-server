import FluentMySQLDriver
import Vapor

extension MySQLError: AbortError {

    public var status: NIOHTTP1.HTTPResponseStatus {
        guard case .duplicateEntry = self else {
            return .unprocessableEntity
        }
        return .internalServerError
    }

    private var isRelease: Bool {
        (try? Environment.detect().isRelease) ?? true
    }

    public var reason: String {
        guard case .duplicateEntry(let localizedErrorDescription) = self else {
            guard !isRelease else {
                return "Something went wrong."
            }
            return description
        }

        return localizedErrorDescription
    }
}
