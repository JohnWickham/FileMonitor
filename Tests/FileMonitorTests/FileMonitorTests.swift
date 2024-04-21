import XCTest

@testable import FileMonitor
import FileMonitorShared

final class FileMonitorTests: XCTestCase {

    let tmp = FileManager.default.temporaryDirectory
    let dir = String.random(length: 10)

    override func setUpWithError() throws {
        super.setUp()
        let directory = tmp.appendingPathComponent(dir)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        print("Created directory: \(tmp.appendingPathComponent(dir).path)")
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let directory = tmp.appendingPathComponent(dir)
        try FileManager.default.removeItem(at: directory)
    }

    func testInitModule() throws {
        #if os(macOS)
        let options: WatcherOptions = [.fileEvents, .markSelf]
        #elseif os(Linux)
        let options: WatcherOptions = [.allEvents]
        #endif
        XCTAssertNoThrow(try FileMonitor(directory: FileManager.default.temporaryDirectory, options: options))
    }

    struct Watcher: FileDidChangeDelegate {
        static var fileChanges = 0
        let callback: ()->Void
        let file: URL

        init(on file: URL, completion: @escaping ()->Void) {
            self.file = file
            callback = completion
        }

        func fileDidChange(event: FileChangeEvent) {
            switch event {
            case .modified(let fileInEvent, _), .removed(let fileInEvent, _), .created(let fileInEvent, _):
                if file.lastPathComponent == fileInEvent.lastPathComponent {
                    Watcher.fileChanges = Watcher.fileChanges + 1
                    callback()
                }
            }
        }
    }

    func testLifecycleCreate() throws {
        let expectation = expectation(description: "Wait for file creation")
        expectation.assertForOverFulfill = false

        let testFile = tmp.appendingPathComponent(dir).appendingPathComponent("\(String.random(length: 8)).\(String.random(length: 3))");
        let watcher = Watcher(on: testFile) { expectation.fulfill() }

        #if os(macOS)
        let options: WatcherOptions = [.fileEvents, .markSelf]
        #elseif os(Linux)
        let options: WatcherOptions = [.allEvents]
        #endif
        let monitor = try FileMonitor(directory: tmp.appendingPathComponent(dir), delegate: watcher, options: options)
        try monitor.start()
        Watcher.fileChanges = 0

        FileManager.default.createFile(atPath: testFile.path, contents: "hello".data(using: .utf8))
        wait(for: [expectation], timeout: 10)

        XCTAssertGreaterThan(Watcher.fileChanges, 0)
    }

    func testLifecycleChange() throws {
        let expectation = expectation(description: "Wait for file creation")
        expectation.assertForOverFulfill = false

        let testFile = tmp.appendingPathComponent(dir).appendingPathComponent("\(String.random(length: 8)).\(String.random(length: 3))");
        FileManager.default.createFile(atPath: testFile.path, contents: "hello".data(using: .utf8))

        let watcher = Watcher(on: testFile) { expectation.fulfill() }

        #if os(macOS)
        let options: WatcherOptions = [.fileEvents, .markSelf]
        #elseif os(Linux)
        let options: WatcherOptions = [.allEvents]
        #endif
        let monitor = try FileMonitor(directory: tmp.appendingPathComponent(dir), delegate: watcher, options: options)
        try monitor.start()
        Watcher.fileChanges = 0

        try "New Content".write(toFile: testFile.path, atomically: true, encoding: .utf8)
        wait(for: [expectation], timeout: 10)

        XCTAssertGreaterThan(Watcher.fileChanges, 0)
    }

    func testLifecycleDelete() throws {
        let expectation = expectation(description: "Wait for file deletion")
        expectation.assertForOverFulfill = false

        let testFile = tmp.appendingPathComponent(dir).appendingPathComponent("\(String.random(length: 8)).\(String.random(length: 3))");
        FileManager.default.createFile(atPath: testFile.path, contents: "hello".data(using: .utf8))

        let watcher = Watcher(on: testFile) { expectation.fulfill() }

        #if os(macOS)
        let options: WatcherOptions = [.fileEvents, .markSelf]
        #elseif os(Linux)
        let options: WatcherOptions = [.allEvents]
        #endif
        let monitor = try FileMonitor(directory: tmp.appendingPathComponent(dir), delegate: watcher, options: options)
        try monitor.start()
        Watcher.fileChanges = 0

        try FileManager.default.removeItem(at: testFile)
        wait(for: [expectation], timeout: 10)

        XCTAssertGreaterThan(Watcher.fileChanges, 0)
    }


}
