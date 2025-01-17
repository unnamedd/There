enum PhotoSource: String, CustomStringConvertible, CaseIterable, Identifiable {
    case bluesky
    case telegram
    case x
    case finder

    var description: String {
        switch self {
        case .bluesky: "Bluesky"
        case .finder: "Finder"
        case .telegram: "Telegram"
        case .x: "X"
        }
    }
    
    var id: String {
        rawValue
    }
}
