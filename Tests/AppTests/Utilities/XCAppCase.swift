import XCTVapor
@testable import App

class XCAppCase: XCTestCase {

    var app: Application!

    override func setUpWithError() throws {
        try super.setUpWithError()

        app = .init(.testing)
        try bootstrap(app)
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }

    override func tearDown() {
        super.tearDown()
        
        app.shutdown()
    }
}
