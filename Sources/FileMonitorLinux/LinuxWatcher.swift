//
// aus der Technik, on 15.05.23.
// https://www.ausdertechnik.de
//

import Foundation
import FileMonitorShared
#if canImport(CInotify)
import CInotify
#endif

#if os(Linux)
public struct LinuxWatcher: Watcher {
    var fsWatcher: FileSystemWatcher
    public var delegate: WatcherDelegate?
    var path: URL
    public var options: WatcherOptions?

    public init(directory: URL, options: WatcherOptions?) {
        self.fsWatcher = FileSystemWatcher()
        self.path = directory
        self.options = options
    }

    public func observe() throws {
        fsWatcher.watch(path: path.path, for: InotifyEventMask.allEvents) { fsEvent in
            //print("Mask: 0x\(String(format: "%08x", fsEvent.mask))")
            guard let url = URL(string: self.path.path + "/" + fsEvent.name) else { return }

            var fileEvent: FileChangeEvent? = nil
            
            // Future improvement: check fsEvent.mask for the InotifyEventMask.movedFrom and InotifyEventMask.movedTo bits to notify about the original and destination of moved files.

            let isDirectory = fsEvent.mask & InotifyEventMask.isDirectory.rawValue > 0
            
            // Added
            if fsEvent.mask & InotifyEventMask.created.rawValue > 0 ||
               fsEvent.mask & InotifyEventMask.moved.rawValue > 0 {
                fileEvent = .created(file: url, isDirectory: isDirectory)
            }
            // Modified
            if fsEvent.mask & InotifyEventMask.modified.rawValue > 0 ||
               fsEvent.mask & InotifyEventMask.attributesChanged.rawValue > 0 {
                fileEvent = .modified(file: url, isDirectory: isDirectory)
            }
            // Deleted or removed
            else if fsEvent.mask & InotifyEventMask.deleted.rawValue > 0 ||
                    fsEvent.mask & InotifyEventMask.deletedSelf.rawValue > 0 {
                fileEvent = .removed(file: url, isDirectory: isDirectory)
            }

            if fileEvent == nil  {
                return
            }

            self.delegate?.fileDidChange(event: fileEvent!)
        }

        fsWatcher.start()
    }

    public func stop() {
        fsWatcher.stop()
    }
}
#endif
