import XCTest
@testable import Mothi

final class MothiTests: XCTestCase {
    
    func testToooMaaaanyEndpoints() {
        let sut = Server()
        
        let maxNumber = 10_000
        var startTime = CACurrentMediaTime()
        for i in 0..<maxNumber {
            sut.get("/test/\(i)") { (req, res, loop)  in
                res.send("Works!")
                return loop.makeSucceededFuture(.next)
            }
        }
        print(String(format: "middleware creating time %0.2f ms for \(maxNumber) endpoints", (CACurrentMediaTime() - startTime) * 1000))
        
        let port = 1337 + Int.random(in: 0..<100)
        DispatchQueue.global().async {
            sut.listen(host:"localhost" , port: port)
        }
        usleep(100_000)
        let expectation = self.expectation(description: "API call")
        let random = Int.random(in: 0..<maxNumber)
        print("selected endpoint: /test/\(random)")
        guard let url = URL(string: "http://localhost:\(port)/test/\(random)") else {
            XCTFail("Wrong url")
            return
        }
        startTime = CACurrentMediaTime()
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            print(String(format: "response time %0.2f ms", (CACurrentMediaTime() - startTime) * 1000))
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            
            expectation.fulfill()
        }.resume()
        self.waitForExpectations(timeout: 5000, handler: nil)

    }

    func testResponseTime() {
        let sut = Server()
        
        let maxNumber = 100
        
        
        sut.get("/test") { (req, res, loop)  in
            res.send("Works!")
            return loop.makeSucceededFuture(.next)
        }
    
        
        let port = 1337 + Int.random(in: 0..<100)
        DispatchQueue.global().async {
            sut.listen(host:"localhost" , port: port)
        }
        usleep(100_000)
        guard let url = URL(string: "http://localhost:\(port)/test") else {
            XCTFail("Wrong url")
            return
        }
        
        let startTime = CACurrentMediaTime()
        for _ in 0..<maxNumber {
            _ = try! Data(contentsOf: url)
        }
        let time = (CACurrentMediaTime() - startTime)
        print(String(format: "response time %0.2f s for \(maxNumber) request", time))
        print(String(format: "avg response time %0.2f ms", time/Double(maxNumber) * 1000 ))
    
    }
    static var allTests = [
        ("testToooMaaaanyEndpoints", testToooMaaaanyEndpoints),
        ("testResponseTime", testResponseTime)
    ]
}
