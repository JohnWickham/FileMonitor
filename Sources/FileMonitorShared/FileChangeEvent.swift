//
// aus der Technik, on 17.05.23.
// https://www.ausdertechnik.de
//

import Foundation

public enum FileChangeEvent {
    case created(file: URL, isDirectory: Bool)
    case modified(file: URL, isDirectory: Bool)
    case removed(file: URL, isDirectory: Bool)

    // Display friendly description of the event
    public var description: String {
        get {
            switch self {
            case .created(file: let file, isDirectory: let isDirectory):
                return "Created \(isDirectory ? "directory" : "file"):    \(file.path)"
            case .modified(file: let file, isDirectory: let isDirectory):
                return "Modified \(isDirectory ? "directory" : "file"):    \(file.path)"
            case .removed(file: let file, isDirectory: let isDirectory):
                return "Removed \(isDirectory ? "directory" : "file"):  \(file.path)"
            }
        }
    }
}
