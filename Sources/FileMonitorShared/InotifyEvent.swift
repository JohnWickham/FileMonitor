//
// aus der Technik, on 16.05.23.
// https://www.ausdertechnik.de
//
// Heavily inspired by https://github.com/felix91gr/FileSystemWatcher/blob/master/Sources/fswatcher.swift
// See https://www.man7.org/linux/man-pages/man7/inotify.7.html

import Foundation
import Dispatch

/// A single Inotify event
public struct InotifyEvent {
  // Watch descriptor
  public let watchDescriptor: Int

  // Mask describing the event
  public let mask: UInt32

  // Used on rename events
  public let cookie: UInt32

  // Size of the name field
  public let length: UInt32

  // Normally the file name
  public let name: String
    
    public init(watchDescriptor: Int, mask: UInt32, cookie: UInt32, length: UInt32, name: String) {
        self.watchDescriptor = watchDescriptor
        self.mask = mask
        self.cookie = cookie
        self.length = length
        self.name = name
    }
}

/// Equability and hashability of an Inotify Event
extension InotifyEvent: Equatable, Hashable {
    public static func == (lhs: InotifyEvent, rhs: InotifyEvent) -> Bool {
        lhs.watchDescriptor == rhs.watchDescriptor
        && lhs.name == rhs.name
        && lhs.mask == rhs.mask
        && lhs.cookie == rhs.cookie
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(watchDescriptor)
        hasher.combine(name)
        hasher.combine(mask)
        hasher.combine(cookie)
    }
}

/// Type of the event (from sys/inotify.h)
public enum InotifyEventMask: UInt32 {
    
    /// Mask options that can be used when initializing the watch
    case accessed           = 0x00000001 // File was accessed
    case modified           = 0x00000002 // File was modified
    case attributesChanged  = 0x00000004 // Metadata changed

    case closedWithWrite    = 0x00000008 // Closed after opened for writing
    case closedWithoutWrite = 0x00000010 // Closed after opening for reading
    case closed             = 0x00000018 // Closed (independent of mode; equal to closedWithWrite | closedWithoutWrite)

    case opened             = 0x00000020 // File opened
    case movedFrom          = 0x00000040 // Old file before move
    case movedTo            = 0x00000080 // New file after move
    case moved              = 0x000000C0 // On any move event (equal to movedFrom | movedTo)

    case created            = 0x00000100 // New file created
    case deleted            = 0x00000200 // File deleted
    case deletedSelf        = 0x00000400 // Watched file was deleted
    case movedSelf          = 0x00000800 // Watched file was moved
    
    case allEvents          = 0x00000FFF // Meta value to watch all events (equal to OR of all above options)

    case onlyDir            = 0x01000000 // Set to only watch if is a dir
    case noFollow           = 0x02000000 // Dont watch if is symlink
    case excludeUnlink      = 0x04000000 // Ignore events for children if not applicable

    case maskAdd            = 0x20000000 // Dont overwrite watch masks

    case isDirectory        = 0x40000000 // File is a directory
    case oneShot            = 0x80000000 // Only watch for changes once
    
    /// Mask options that may be included in events from the kernel

    case unmounted          = 0x00002000 // FS was unmounted
    case queueOverflowed    = 0x00004000 // Queue overflowed
    case ignored            = 0x00008000 // Either the watch or the file itself was removed
}

