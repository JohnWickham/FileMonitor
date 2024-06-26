import XCTest

@testable import FileMonitor
import FileMonitorShared

final class FileMonitorFileHasPathTests: XCTestCase {

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

    struct Watcher: FileDidChangeDelegate {
        static var fileChanges = 0
        static var missedChanges = 0
        static var lastFile: URL? = nil
        let callback: ()->Void
        let file: URL

        init(on file: URL, completion: @escaping ()->Void) {
            self.file = file
            callback = completion
        }

        func fileDidChange(event: FileChangeEvent) {
            switch event {
            case .created(let fileInEvent, _):
                if file.lastPathComponent == fileInEvent.lastPathComponent {
                    Watcher.lastFile = fileInEvent
                    Watcher.fileChanges = Watcher.fileChanges + 1
                    callback()
                }
            default:
                print("Missed", event)
                Watcher.missedChanges = Watcher.missedChanges + 1
            }
        }
    }

    func testLifecycleAdd() throws {
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

        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(Watcher.fileChanges, 1)
        XCTAssertNotNil(Watcher.lastFile)
        XCTAssertTrue(((Watcher.lastFile?.hasDirectoryPath) != nil))
        XCTAssert(Watcher.lastFile!.path.contains(dir))
    }
}
