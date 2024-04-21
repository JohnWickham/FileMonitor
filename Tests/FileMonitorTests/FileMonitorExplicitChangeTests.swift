import XCTest

@testable import FileMonitor
import FileMonitorShared

final class FileMonitorExplicitChangeTests: XCTestCase {

    let tmp = FileManager.default.temporaryDirectory
    let dir = String.random(length: 10)
    let testFileName = "\(String.random(length: 8)).\(String.random(length: 3))";

    override func setUpWithError() throws {
        super.setUp()
        let directory = tmp.appendingPathComponent(dir)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        print("Created directory: \(tmp.appendingPathComponent(dir).path)")

        let testFile = tmp.appendingPathComponent(dir).appendingPathComponent(testFileName)
        try "hello".write(to: testFile, atomically: false, encoding: .utf8)
        print("Created test file: \(tmp.appendingPathComponent(testFileName))")

    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        let directory = tmp.appendingPathComponent(dir)
        try FileManager.default.removeItem(at: directory)
    }

    struct ChangeWatcher: FileDidChangeDelegate {
        static var fileChanges = 0
        static var missedChanges = 0
        let expectation: XCTestExpectation
        let file: URL

        init(on file: URL, expectation: XCTestExpectation) {
            self.file = file
            self.expectation = expectation
        }

        func fileDidChange(event: FileChangeEvent) {
            switch event {
            case .modified(let fileInEvent, let isDirectory):
                if isDirectory, fileInEvent.lastPathComponent == fileInEvent.deletingLastPathComponent().path {
                    print("Parent directory was modified")
                }
                else if file.lastPathComponent == fileInEvent.lastPathComponent {
                    print("File was modified")
                    ChangeWatcher.fileChanges = ChangeWatcher.fileChanges + 1
                    expectation.fulfill()
                }
            default:
                print("Skipped", event)
                ChangeWatcher.missedChanges = ChangeWatcher.missedChanges + 1
            }
        }
    }

    func testLifecycleChange() throws {
        let expectation = XCTestExpectation(description: "Wait for file creation")
        expectation.assertForOverFulfill = false

        let testFile = tmp.appendingPathComponent(dir).appendingPathComponent(testFileName)
        let watcher = ChangeWatcher(on: testFile, expectation: expectation)

        #if os(macOS)
        let options: WatcherOptions = [.fileEvents, .markSelf]
        #elseif os(Linux)
        let options: WatcherOptions = [.allEvents]
        #endif
        let monitor = try FileMonitor(directory: tmp.appendingPathComponent(dir), delegate: watcher, options: options)
        try monitor.start()
        ChangeWatcher.fileChanges = 0

        let fileHandle = try FileHandle(forWritingTo: testFile)
        try fileHandle.seekToEnd()
        fileHandle.write("append some text".data(using: .utf8)!)
        try fileHandle.close()

        wait(for: [expectation], timeout: 10)

        XCTAssertEqual(ChangeWatcher.fileChanges, 1)
    }
}
