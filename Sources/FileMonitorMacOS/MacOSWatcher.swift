//
//  File.swift
//  
//
//  Created by John Wickham on 4/19/24.
//

import Foundation
import FileMonitorShared

public enum MacOSWatcherError: Error {
    case failedToOpenStream(path: String)
}

public class MacOSWatcher: Watcher {
    
    public var delegate: WatcherDelegate?
    
    private var directory: URL
    private var options: WatcherOptions?
    private var eventStream: FSEventStream?
    
    public required init(directory: URL, options: WatcherOptions?) throws {
        self.directory = directory
        self.options = options
    }
    
    public convenience init(directory: URL, delegate: WatcherDelegate?) throws {
        try self.init(directory: directory, options: nil)
        self.delegate = delegate
    }
    
    public func observe() throws {
        
        var flags: UInt32
        if let options = options {
            flags = options.rawValue
        }
        else {
            flags = UInt32(kFSEventStreamCreateFlagNone)
        }
        
        let stream = FSEventStream(path: directory.path(), since: nil, updateInterval: 1, fsEventStreamFlags: flags, queue: DispatchQueue.global(qos: .background)) { stream, event in
            
            switch event {
            case .itemCreated(path: let path, itemType: let itemType, eventId: _, fromUs: _):
                
                let fileURL = URL(fileURLWithPath: path)
                let isDirectory = itemType == .directory
                self.delegate?.fileDidChange(event: .created(file: fileURL, isDirectory: isDirectory))
                
            case .itemDataModified(path: let path, itemType: let itemType, eventId: _, fromUs: _),
                 .itemInodeMetadataModified(path: let path, itemType: let itemType, eventId: _, fromUs: _),
                 .itemRenamed(path: let path, itemType: let itemType, eventId: _, fromUs: _):
                
                let fileURL = URL(fileURLWithPath: path)
                let isDirectory = itemType == .directory
                self.delegate?.fileDidChange(event: .modified(file: fileURL, isDirectory: isDirectory))
                
            case .itemRemoved(path: let path, itemType: let itemType, eventId: _, fromUs: _):
                
                let fileURL = URL(fileURLWithPath: path)
                let isDirectory = itemType == .directory
                self.delegate?.fileDidChange(event: .removed(file: fileURL, isDirectory: isDirectory))
                
            default:
                print("Unhandled FSEvent: \(event)")
            }
            
        }
        
        self.eventStream = stream
        
        eventStream?.startWatching()
    }
    
    public func stop() {
        eventStream?.stopWatching()
    }
    
    
}
