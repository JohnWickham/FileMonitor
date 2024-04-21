import XCTest

@testable import FileMonitor
import FileMonitorShared

final class FileMonitorExplicitAddTests: XCTestCase {

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

    struct AddWatcher: FileDidChangeDelegate {
        static var fileChanges = 0
        static var missedChanges = 0
        let callback: () -> Void
        let file: URL

        init(on file: URL, completion: @escaping ()->Void) {
            self.file = file
            callback = completion
        }

        func fileDidChange(event: FileChangeEvent) {
            switch event {
            case .created(file: let item, _):
                guard item.lastPathComponent == file.lastPathComponent || item.lastPathComponent == file.deletingLastPathComponent().lastPathComponent else {
                    AddWatcher.missedChanges += 1
                    return
                }
                AddWatcher.fileChanges += 1
                callback()
            case .modified(file: let item, isDirectory: _):
                guard item.lastPathComponent == file.lastPathComponent else {
                    AddWatcher.missedChanges += 1
                    return
                }
                AddWatcher.fileChanges += 1
            default:
                print("Skipped", event)
                AddWatcher.missedChanges = AddWatcher.missedChanges + 1
            }
        }
    }

    func testLifecycleAdd() throws {
        let expectation = expectation(description: "Wait for file creation")
        expectation.assertForOverFulfill = false

        let testFile = tmp.appendingPathComponent(dir).appendingPathComponent("\(String.random(length: 8)).\(String.random(length: 3))");
        let watcher = AddWatcher(on: testFile) { expectation.fulfill() }

        #if os(macOS)
        let options: WatcherOptions = [.markSelf, .noDefer]
        #elseif os(Linux)
        let options: WatcherOptions = [.allEvents]
        #endif
        let monitor = try FileMonitor(directory: tmp.appendingPathComponent(dir), delegate: watcher, options: options)
        try monitor.start()
        AddWatcher.fileChanges = 0

        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))
        wait(for: [expectation], timeout: 10)
        
        // FIXME: On macOS, FS events here seem totally random. Sometimes AddWatcher.fileChanges is 2, sometimes it's 1.
        XCTAssertEqual(AddWatcher.fileChanges, 2)// Expect 3 changes: 1 for creating the subdirectory, 1 for creating the file, 1 for modifying the file
    }
}
