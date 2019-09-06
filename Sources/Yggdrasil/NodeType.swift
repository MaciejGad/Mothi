import Foundation

enum NodeType: String {
    case root
    case `static`
    case dynamic
    case wildcard
    
    static func from(pathComponent: String) -> NodeType {
        switch pathComponent {
        case let wildcard where wildcard == "*":
            return .wildcard
        case let key where key.hasPrefix(":"):
            return .dynamic
        default:
            return .static
        }
        
    }
}

#if Encodable
extension NodeType: Encodable {}
#endif
