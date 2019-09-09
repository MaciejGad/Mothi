import XCTest
import Foundation

final class MothiExampleTests: XCTestCase {
    var process:Process!
    var host: String!
    var port: Int!
    
    override func setUp() {
        super.setUp()
        startServer()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        super.tearDown()
        process.terminate()
        process.interrupt()
        process = nil
        host = nil
        port = nil
    }
    
    func testRootPoem() throws {
        //given
        let expectedResponse = #"["Móði ok Magni","skulu Mjöllni hafa","Vingnis at vígþroti."]"#
        try get(path: "/", expected: expectedResponse)
    }
    
    func testParameters() throws {
        try get(path: "/param?test=1", expected: #"{"param":"1"}"#)
    }
    
    func testURPathParameters() throws {
        try get(path: "/id/123a", expected: #"{"id":"123a"}"#)
    }
    
    func testWildcard() throws {
        let uuid = UUID().uuidString
        try get(path: "/any/\(uuid)", expected: #"{"path":"\/any\/\#(uuid)"}"#)
    }
    
    func testMerge() throws {
        try get(path: "/merge", expected: #"["First line","Second line"]"#)
    }
    
    func testEnd() throws {
        try get(path: "/end", expected: #"["Test"]"#)
    }
    
    func testThrow() throws {
        try get(path: "/throw", statusCode: 500)
    }
    
    func testCustomObjectEncode() throws {
        try get(path: "/out", expected: #"{"anotherOut":"Test"}"#)
    }
    
    func testPost() throws {
        //given
        let expectation = #"[{"out":"test"},{"loggedAs":"user"}]"#
        let auth = "Basic dXNlcjp0ZXN0"
        let body = ["value": "test"]
        try post(path: "/post", body:body, expected: expectation, authorization:auth)
    }
    
    func testPromise() throws {
        try get(path: "/promise")
    }
    
    func testPostPromise() throws {
        try post(path: "/promise", body: ["value": "test"])
    }
    

    func testPut() throws {
        try use(path: "/put", method: "PUT", body: ["value": "test"], expected: #"["test"]"#)
    }
    
    func testPatch() throws {
        try use(path: "/patch", method: "PATCH", body: ["value": "test"], expected: #"["test"]"#)
    }
    
    func testDelete() throws {
        try use(path: "/delete", method: "DELETE", statusCode: 204)
    }
    
    func testSearch() throws {
        try use(path: "/?q=query", method: "SEARCH", expected: #"{"searching":"query"}"#, statusCode: 302)
    }
    
    static var allTests = [
        ("testRootPoem", testRootPoem),
        ("testParameters", testParameters),
        ("testURPathParameters", testURPathParameters),
        ("testWildcard", testWildcard),
        ("testMerge", testMerge),
        ("testEnd", testEnd),
        ("testThrow", testThrow),
        ("testCustomObjectEncode", testCustomObjectEncode),
        ("testPromise", testPromise),
        ("testPostPromise", testPostPromise),
        ("testPost", testPost),
        ("testPut", testPut),
        ("testPatch", testPatch),
        ("testDelete", testDelete),
        ("testSearch", testSearch)
    ]
    
}
extension MothiExampleTests {
    func post(path: String, body: [String: Any], expected: String? = nil, statusCode: Int = 200, authorization: String? = nil, file: StaticString = #file, line: UInt = #line) throws {
        
        try use(path: path, method: "POST", body: body, expected: expected, statusCode: statusCode, authorization: authorization, file: file, line: line)
    }
    
    func get(path: String, expected: String? = nil, statusCode: Int = 200, authorization: String? = nil, file: StaticString = #file, line: UInt = #line) throws {
        try use(path: path, method: "GET", expected: expected, statusCode: statusCode, authorization: authorization, file: file, line: line)
    }
    
    func use(path: String, method: String, body: [String: Any]? = nil, expected: String? = nil, statusCode: Int = 200, authorization: String? = nil, file: StaticString = #file, line: UInt = #line) throws {
        //given
        guard let url = URL(string: "http://\(host!):\(port!)\(path)") else {
            XCTFail("not valid path: \(path)", file: file, line: line)
            return
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = method.uppercased()
        
        if let body = body {
            request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        if let authorization = authorization {
            request.addValue(authorization, forHTTPHeaderField: "Authorization")
        }
        
        call(request: request, expected: expected, statusCode: statusCode, authorization: authorization, file: file, line: line)

    }
    
    func call(request: URLRequest, expected: String? = nil, statusCode: Int = 200, authorization: String? = nil, file: StaticString = #file, line: UInt = #line) {
   
        let expectation = self.expectation(description: "API call")
        
        //when
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            XCTAssertNil(error, file: file, line: line)
            
            XCTAssertNotNil(response, file: file, line: line)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, statusCode, file: file, line: line)
            XCTAssertNotNil(data, file: file, line: line)
            if let data = data {
                let text = String(bytes: data, encoding: .utf8)
                XCTAssertNotNil(text, file: file, line: line)
                if let expected = expected {
                    XCTAssertEqual(text, expected, file: file, line: line)
                }
            }
            expectation.fulfill()
            }.resume()
        
        //then
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    /// Returns path to the built products directory.
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }
    
    func startServer() {
        guard #available(macOS 10.13, *) else {
            return
        }
        
        host = "localhost"
        port = 1337 
        
        let fooBinary = productsDirectory.appendingPathComponent("MothiExample")
        
        process = Process()
        process.executableURL = fooBinary
        process.arguments = [host, "\(port!)"]
        do {
            try self.process.run()
        } catch {
            print("\(error)")
        }
        usleep(100_000) //wait 0.1s for webserver to setup
    }
    

}
