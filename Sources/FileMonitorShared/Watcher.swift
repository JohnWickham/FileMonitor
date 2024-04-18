//
// aus der Technik, on 15.05.23.
// https://www.ausdertechnik.de
//

import Foundation

public enum FileMonitorOptions {
    case ignoreDirectories
}

public protocol WatcherDelegate {
    func fileDidChange(event: FileChangeEvent)
}

public protocol WatcherProtocol {
    var delegate: WatcherDelegate? { set get }

    init(directory: URL, options: [FileMonitorOptions]?) throws
    func observe() throws
    func stop()
}

public extension WatcherProtocol {
    func getCurrentFiles(in directory: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey, .typeIdentifierKey],
                options: [.skipsHiddenFiles]
        )
    }

    func getDifferencesInFiles(lhs: [URL], rhs: [URL]) -> Set<URL> {
        Set(lhs).subtracting(rhs)
    }
}
