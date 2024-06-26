//
// aus der Technik, on 17.05.23.
// https://www.ausdertechnik.de
//

import Foundation
import FileMonitorShared
#if os(macOS)
import FileMonitorMacOS
#elseif os(Linux)
import FileMonitorLinux
#endif

/// Errors that `FileMonitor` can throw
public enum FileMonitorErrors: Error {
    case unsupportedOS
    case notImplemented
    case NotADirectory(url: URL)
    case failedToOpen(url: URL)
}

/// FileMonitor: Watch for file changes in a directory with a unified API on Linux and macOS.
public struct FileMonitor: WatcherDelegate {

    var watcher: Watcher
    
    public var delegate: FileDidChangeDelegate? {
        didSet {
            // further improvement:
            // bind watcher.delegate direct to delegate to get rid of call-tree
        }
    }

    @discardableResult
    public init(directory url: URL, delegate externDelegate: FileDidChangeDelegate? = nil, options: WatcherOptions?) throws {
        if url.isDirectory == false {
            throw FileMonitorErrors.NotADirectory(url: url)
        }

        // extern delegate
        if let externDelegate {
            delegate = externDelegate
        }
        
        #if os(Linux)
            watcher = LinuxWatcher(directory: url, options: options)
        #elseif os(macOS)
            watcher = try MacOSWatcher(directory: url, options: options)
        #else
            throw FileMonitorErrors.unsupportedOS
        #endif

        watcher.delegate = self
    }

    /// Start watching file changes
    /// - Throws:
    ///   - FileMonitorErrors
    ///   - Error
    public func start() throws {
        try watcher.observe()
    }

    /// Stop watching file changes
    ///
    /// - Throws:
    ///   - FileMonitorErrors
    ///   - Error
    public func stop() {
        watcher.stop()
    }

    // MARK: - WatcherDelegate

    /// Called when the underlying subsystem detect a file change
    ///
    /// - Parameter event: A file change event
    public func fileDidChange(event: FileChangeEvent) {
        delegate?.fileDidChange(event: event)
    }

}
