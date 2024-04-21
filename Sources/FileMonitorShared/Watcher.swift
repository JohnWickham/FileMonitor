//
// aus der Technik, on 15.05.23.
// https://www.ausdertechnik.de
//

import Foundation

public protocol WatcherDelegate {
    func fileDidChange(event: FileChangeEvent)
}

public struct WatcherOptions: OptionSet {
    public var rawValue: UInt32
    
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    #if os(macOS)
    public static let noDefer          = WatcherOptions.init(rawValue: UInt32(kFSEventStreamCreateFlagNoDefer))
    public static let watchRoot        = WatcherOptions.init(rawValue: UInt32(kFSEventStreamCreateFlagWatchRoot))
    public static let ignoreSelf       = WatcherOptions.init(rawValue: UInt32(kFSEventStreamCreateFlagIgnoreSelf))
    public static let fileEvents       = WatcherOptions.init(rawValue: UInt32(kFSEventStreamCreateFlagFileEvents))
    public static let markSelf         = WatcherOptions.init(rawValue: UInt32(kFSEventStreamCreateFlagMarkSelf))
    public static let useExtendedData  = WatcherOptions.init(rawValue: UInt32(kFSEventStreamCreateFlagUseExtendedData))
    public static let fullHistory      = WatcherOptions.init(rawValue: UInt32(kFSEventStreamCreateFlagFullHistory))
    #elseif os(Linux)
    // TODO: Enumerate mask options for Inotify.
    public static let allEvents        = WatcherOptions.init(rawValue: InotifyEventMask.allEvents.rawValue)
    #endif
}

public protocol Watcher {
    var delegate: WatcherDelegate? { set get }

    init(directory: URL, options: WatcherOptions?) throws
    func observe() throws
    func stop()
}

public extension Watcher {
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
