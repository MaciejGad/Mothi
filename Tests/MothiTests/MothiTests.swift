import XCTest
@testable import Mothi

final class MothiTests: XCTestCase {
    
    let serverQueue: DispatchQueue = .init(label: "server_queue", qos: .background, attributes: .concurrent)
    
    func testToooMaaaanyEndpoints() {
        let sut = Server()
        
        let maxNumber = 10_000
        var startTime = now()
        for i in 0..<maxNumber {
            sut.get("/test/\(i)") { (req, res, loop)  in
                res.send("Works!")
                return loop.makeSucceededFuture(.next)
            }
        }
        let duration = now() - startTime
        print(String(format: "middleware creating time %0.2f s for \(maxNumber) endpoints",  duration))
        
        let port = 1337 + Int.random(in: 0..<100)
        sut.listen(host:"localhost" , port: port, asynch: true)
        let expectation = self.expectation(description: "API call")
        let random = Int.random(in: 0..<maxNumber)
        print("selected endpoint: /test/\(random)")
        guard let url = URL(string: "http://localhost:\(port)/test/\(random)") else {
            XCTFail("Wrong url")
            return
        }
        startTime = now()
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(String(format: "response time %0.2f ms", (now() - startTime) * 1000))
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            
            expectation.fulfill()
        }.resume()
        self.waitForExpectations(timeout: 5, handler: nil)

    }

    func testResponseTime() throws {
        let sut = Server()
        
        let maxNumber = 100
        
        
        sut.get("/test") { (req, res, loop)  in
            res.send("Works!")
            return loop.makeSucceededFuture(.next)
        }
    
        
        let port = 1337 + Int.random(in: 0..<100)
        sut.listen(host:"localhost" , port: port, asynch: true)
        guard let url = URL(string: "http://localhost:\(port)/test") else {
            XCTFail("Wrong url")
            return
        }
        
        let startTime = now()
        for _ in 0..<maxNumber {
            _ = try Data(contentsOf: url)
        }
        let time = (now() - startTime)
        print(String(format: "response time %0.2f s for \(maxNumber) request", time))
        print(String(format: "avg response time %0.2f ms", time/Double(maxNumber) * 1000 ))
    
    }
    static var allTests = [
        ("testToooMaaaanyEndpoints", testToooMaaaanyEndpoints),
        ("testResponseTime", testResponseTime)
    ]
}

@inline(__always) func now() -> TimeInterval {
    return Date.timeIntervalSinceReferenceDate
}
