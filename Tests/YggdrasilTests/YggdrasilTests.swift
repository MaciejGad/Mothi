import XCTest
import Yggdrasil

final class YggdrasilTests: XCTestCase {

    func testTreenOneStaticBranch() {
        //given
        let tree = Tree<Value, Int>()
        let givenLabel = "test label"
        let givenKey = 1
        let givenPath = "/test"
        
        //when
        tree.store(path: givenPath, value: Value(givenLabel))
        let out = tree.withdraw(path: givenPath, key: givenKey)

        //then
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].value.label, givenLabel)
    }
    
    func testTreenOneDynamicBranch() {
        //given
        let tree = Tree<Value, String>()
        let givenLabel = "test label"
        let givenKey = "key"

        
        //when
        tree.store(path: "/:id", value: Value(givenLabel))
        let out = tree.withdraw(path: "/1", key: givenKey)
        
        //then
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].value.label, givenLabel)
        XCTAssertEqual(out[0].params["id"], "1")
    }
    
    func testTreenOneWildcardBranch() {
        //given
        let tree = Tree<Value, String>()
        let givenLabel = "test label"
        let givenKey = "key"
        
        
        //when
        tree.store(path: "/*", value: Value(givenLabel))
        
        //then
        let out = tree.withdraw(path: "/1", key: givenKey)
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].value.label, givenLabel)
        XCTAssertEqual(out[0].params.count, 0)
    }
    
    func testTree3Branches() {
        //given
        let tree = Tree<Value, String>()
        
        //when
        tree.store(path: "/*", value: "wildcard")
        tree.store(path: "/:id", value: "dynamic")
        tree.store(path: "/1", value: "static")
        
        //then
        let out = tree.withdraw(path: "/1", key: "any")
        XCTAssertEqual(out.count, 3)
        XCTAssertEqual(out[0].value.label, "wildcard")
        XCTAssertEqual(out[1].value.label, "dynamic")
        XCTAssertEqual(out[1].params["id"], "1")
        XCTAssertEqual(out[2].value.label, "static")
//        print(tree.varDump())
    }
    
    func testTree2BranchesMathcingPath() {
        //given
        let tree = Tree<Value, String>()
        
        //when
        tree.store(path: "/*", value: "wildcard")
        tree.store(path: "/:id", value: "dynamic")
        tree.store(path: "/1", value: "static")
        
        //then
        let out = tree.withdraw(path: "/2", key: "any")
        XCTAssertEqual(out.count, 2)
        XCTAssertEqual(out[0].value.label, "wildcard")
        XCTAssertEqual(out[1].value.label, "dynamic")
        XCTAssertEqual(out[1].params["id"], "2")
        
        tree.varDump()

    }
    
    func testBoxForTwoSameStaticBranches() {
        //given
        let tree = Tree<Value, String>()
        
        //when
        tree.store(path: "/1", value: "static 1")
        tree.store(path: "/1", value: "static 2")
        
        //then
        let out = tree.withdraw(path: "/1", key: "any")
        XCTAssertEqual(out.count, 2)
        XCTAssertEqual(out[0].value.label, "static 1")
        XCTAssertEqual(out[1].value.label, "static 2")
        
        tree.varDump()
    }
    
    func testShortBranch() {
        //given
        let tree = Tree<Value, String>()
        
        //when
        tree.store(path: "/test", value: "static /test")
        tree.store(path: "/test/short", value: "static /test/short")
        tree.store(path: "/*", value: "widlcard for /*")

        //then
        let out = tree.withdraw(path: "/test/short/branch", key: "any")
        XCTAssertEqual(out.count, 1)
        XCTAssertEqual(out[0].value.label, "widlcard for /*")
        tree.varDump()
        
    }
    
    func testTwoWildcards() {
        //given
        let tree = Tree<Value, String>()
        
        //when
        tree.store(path: "/test", value: "static /test")
        tree.store(path: "/test/short", value: "static /test/short")
        tree.store(path: "/*", value: "widlcard for /*")
        tree.store(path: "/*", value: "2nd widlcard for /*")
        
        //then
        let out = tree.withdraw(path: "/test/short/branch", key: "any")
        XCTAssertEqual(out.count, 2)
        XCTAssertEqual(out[0].value.label, "widlcard for /*")
        XCTAssertEqual(out[1].value.label, "2nd widlcard for /*")
        tree.varDump()
    }
    
    func testKey() {
        //given
        let tree = Tree<Value, String>()
        
        tree.store(path: "/test", key: "GET", value: "GET /test")
        tree.store(path: "/test", key: "POST", value: "POST /test")
        tree.store(path: "/test", value: "ANY /test")
        
        //then
        let out = tree.withdraw(path: "/test", key: "GET")
        XCTAssertEqual(out.count, 2)
        XCTAssertEqual(out[0].value.label, "GET /test")
        XCTAssertEqual(out[1].value.label, "ANY /test")
        tree.varDump()
    }
    
    static var allTests = [
        ("testTreenOneStaticBranch", testTreenOneStaticBranch),
        ("testTreenOneDynamicBranch", testTreenOneDynamicBranch),
        ("testTreenOneWildcardBranch", testTreenOneWildcardBranch),
        ("testTree3Branches", testTree3Branches),
        ("testTree2BranchesMathcingPath", testTree2BranchesMathcingPath),
        ("testBoxForTwoSameStaticBranches", testBoxForTwoSameStaticBranches),
        ("testShortBranch", testShortBranch),
        ("testTwoWildcards", testTwoWildcards),
        ("testKey", testKey)        
    ]
}

class Value: Encodable, ExpressibleByStringLiteral {
    let label: String

    init(_ label: String) {
        self.label = label
    }
    
    required init(stringLiteral value: String) {
        label = value
    }
}

extension Tree {
    public func varDump() {
        #if Encodable
        let encoder = JSONEncoder()
        if #available(OSX 10.13, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.prettyPrinted]
        }
        let data = try! encoder.encode(self)
        print(String(bytes: data, encoding: .utf8)!)
        #endif
    }
}
