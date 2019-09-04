import Foundation


public class Path: ExpressibleByStringLiteral {
    private let components: [Component]
    private let staticValue: String?
    private let staticPrefix: String?
    
    private enum Component: CustomStringConvertible {
        case root
        case `static`(string: String)
        case dynamic(string: String)
        case wildcard
        
        var description: String {
            switch self {
            case .root:
                return "/"
            case .static(string: let value):
                return value
            case .dynamic(string: let key):
                return ":\(key)"
            case .wildcard:
                return "*"
            }
        }
    }
    
    public required init(stringLiteral value: String) {
        let rawComponents = value.components(separatedBy: "/").dropFirst()
        
        if rawComponents.count == 1 && rawComponents[1] == "" {
            components = [.root]
            staticValue = "/"
            staticPrefix = nil
        } else {
            var isDynimic = false
            var staticPart = ""
            components = rawComponents.map { raw in
                switch raw {
                case let key where key.hasPrefix(":"):
                    isDynimic = true
                    return .dynamic(string: String(key.dropFirst()))
                case let wildcard where wildcard == "*":
                    isDynimic = true
                    return .wildcard
                default:
                    if isDynimic == false {
                        staticPart.append("/" + raw)
                    }
                    return .static(string: raw)
                }
            }
            if isDynimic {
                staticPrefix = staticPart
                staticValue = nil
            } else {
                staticPrefix = nil
                staticValue = staticPart
            }
        }
    }
    var params: [String: String] = [:]

    func matching(path: String) -> Bool {
        if let staticValue = staticValue {
            return path == staticValue
        }
        if let staticPrefix = staticPrefix {
            guard path.hasPrefix(staticPrefix) else {
                return false
            }
        }
        let pathComponents = Array(path.components(separatedBy: "/").dropFirst())
        guard pathComponents.count == components.count else {
            return false
        }
        var possibleParams:[String: String] = [:]
        
        for i in 0..<pathComponents.count {
            let p = pathComponents[i]
            let c = components[i]
            switch c {
                case .root where p != "":
                    return false
                case .static(string: let value) where p != value:
                    return false
                case .dynamic(string: let key):
                    possibleParams[key] = p
                case .wildcard:
                    continue
                default:
                    continue
            }
        }
        params = possibleParams
        return true
    }
}
