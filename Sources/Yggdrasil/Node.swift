import Foundation



final class Node<StorageValue, Key:Hashable> {
    let type: NodeType
    let value: String
    
    
    //children
    var statics: [String: Node] = [:]
    var dynamics: [String: Node] = [:]
    var wildcard: Node? = nil
    
    var keyStorage:[Key: [Box<StorageValue>]] = [:]
    var storage: [Box<StorageValue>] = []

    init(value: String, type: NodeType) {
        self.type = type
        self.value = value
    }
    
    private init() {
        type = .root
        value = "/"
    }
    static var root: Node {
        return .init()
    }
    
    
    func createChild(for component: String) -> Node {
        let type = NodeType.from(pathComponent: component)
        switch type {
        case .wildcard:
            if let wildcard = wildcard {
                return wildcard
            }
            let node = Node(value: component, type: type)
            self.wildcard = node
            return node
        case .dynamic:
            return createOrReuseNode(value: component, type: type, container: &dynamics)
        default:
            return createOrReuseNode(value: component, type: type, container: &statics)
        }
    }
    
    func createOrReuseNode(value: String, type: NodeType, container: inout [String: Node]) -> Node {
        if let node = container[value] {
            return node
        }
        let node = Node(value: value, type: type)
        container[value] = node
        return node
    }
    
    func store(box: Box<StorageValue>) {
        storage.append(box)
    }
    
    func store(box: Box<StorageValue>, key: Key) {
        var keyList = keyStorage[key] ?? []
        keyList.append(box)
        keyStorage[key] = keyList
    }
    
    func boxes(key: Key) -> [Box<StorageValue>] {
        var output = storage
        if let keyList = keyStorage[key] {
            output.append(contentsOf: keyList)
        }
        return output
    }
    
    var leaf: Bool {
        return wildcard == nil
            && statics.count == 0
            && dynamics.count == 0
    }
}

#if Encodable

extension Node: Encodable {
    enum Keys: String, CodingKey {
        case type
        case value
        case statics
        case dynamics
        case wildcard
        case storage
        case keyStorage
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        try container.encode(type, forKey: .type)
        try container.encode(value, forKey: .value)
        if statics.count > 0 {
            try container.encode(statics, forKey: .statics)
        }
        if dynamics.count > 0 {
            try container.encode(dynamics, forKey: .dynamics)
        }
        if let wildcard = wildcard {
            try container.encode(wildcard, forKey: .wildcard)
        }
        if keyStorage.count > 0 {
            var ecodableKeyStorage: [String: [Box<StorageValue>]] = [:]
            keyStorage.forEach { (key, value) in
                ecodableKeyStorage["\(key)"] = value
            }
            try container.encode(ecodableKeyStorage, forKey: .keyStorage)
        }
        if storage.count > 0 {
            try container.encode(storage, forKey: .storage)
        }
    }
}

#endif
