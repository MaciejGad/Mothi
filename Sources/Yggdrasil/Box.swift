import Foundation

public class Box<Value> {
    public let order: Int
    public let value: Value
    
    public var params:[String: String] = [:]
    public init(order: Int, value: Value) {
        self.order = order
        self.value = value
    }
}

#if Encodable
extension Box: Encodable {
    enum Keys: String, CodingKey {
        case order
        case value
        case params
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        try container.encode(order, forKey: .order)
        
        if let encodableValue = value as? Encodable {
            try encodableValue.encode(in: &container, key: .value)
        }
        
        if params.count > 0 {
            try container.encode(params, forKey: .params)
        }

    }
}

extension Encodable {
    func encode<Key>(in container: inout KeyedEncodingContainer<Key>, key: Key) throws where Key : CodingKey {
        try container.encode(self, forKey: key)
    }
}
#endif
