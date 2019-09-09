import Foundation



final class Node<StorageValue, Key:Hashable> {
    let value: String
    
    
    //children
    var statics: [String: Node]? = nil
    var dynamics: [String: Node]? = nil
    var wildcard: Node? = nil
    
    var keyStorage:[Key: [Box<StorageValue>]]? = nil
    var storage: [Box<StorageValue>]? = nil

    init(value: String) {
        self.value = value
    }
    
    private init() {
        value = "/"
    }
    static var root: Node {
        return .init()
    }
    
    func createChild(path: inout String, index: inout String.Index) -> Node {
        let slashRange = path.range(of: "/", range: index..<path.endIndex)
        let valueEndIndex = slashRange?.lowerBound ?? path.endIndex
        let value = String(path[index..<valueEndIndex])
        index = slashRange?.upperBound ?? path.endIndex
        switch value {
        case "*":
            if let wildcard = wildcard {
                return wildcard
            }
            let node = Node(value: value)
            self.wildcard = node
            return node
        case let key where key.hasPrefix(":"):
            return createOrReuseNode(value: value, container: &dynamics)
        default:
            return createOrReuseNode(value: value, container: &statics)
        }
    }
    
    func createOrReuseNode(value: String, container: inout [String: Node]?) -> Node {
        if container == nil {
            container = [:]
        }
        if let node = container?[value] {
            return node
        }
        let node = Node(value: value)
        container?[value] = node
        return node
    }
    
    func store(box: Box<StorageValue>) {
        if storage == nil {
            storage = []
        }
        storage?.append(box)
    }
    
    func store(box: Box<StorageValue>, key: Key) {
        var keyList = keyStorage?[key] ?? []
        keyList.append(box)
        if keyStorage == nil {
            keyStorage = [:]
        }
        keyStorage?[key] = keyList
    }
    
    func boxes(key: Key) -> [Box<StorageValue>] {
        var output = storage ?? []
        if let keyList = keyStorage?[key] {
            output.append(contentsOf: keyList)
        }
        return output
    }
    
    var leaf: Bool {
        return wildcard == nil
            && statics == nil
            && dynamics == nil
    }
}

#if Encodable

extension Node: Encodable {
    enum Keys: String, CodingKey {
        case value
        case statics
        case dynamics
        case wildcard
        case storage
        case keyStorage
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        try container.encode(value, forKey: .value)
        if statics?.count ?? 0 > 0 {
            try container.encode(statics, forKey: .statics)
        }
        if dynamics?.count ?? 0 > 0 {
            try container.encode(dynamics, forKey: .dynamics)
        }
        if let wildcard = wildcard {
            try container.encode(wildcard, forKey: .wildcard)
        }
        if keyStorage?.count ?? 0 > 0 {
            var ecodableKeyStorage: [String: [Box<StorageValue>]] = [:]
            keyStorage?.forEach { (key, value) in
                ecodableKeyStorage["\(key)"] = value
            }
            try container.encode(ecodableKeyStorage, forKey: .keyStorage)
        }
        if let storage = self.storage {
            try container.encode(storage, forKey: .storage)
        }
    }
}

#endif
