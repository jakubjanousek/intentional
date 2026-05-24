import Foundation
import Testing
@testable import Intentional

@Test func formatProducesISO8601TabbedLine() {
    let entry = LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), type: .unlock)
    #expect(EventLog.format(entry) == "2023-11-14T22:13:20Z\tunlock")
}

@Test func appendWritesLinesInOrder() throws {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "intentional-test-\(UUID().uuidString).log")
    defer { try? FileManager.default.removeItem(at: url) }

    let log = EventLog(fileURL: url)
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), type: .unlock))
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_010), type: .lock))

    let contents = try String(contentsOf: url, encoding: .utf8)
    #expect(contents == "2023-11-14T22:13:20Z\tunlock\n2023-11-14T22:13:30Z\tlock\n")
}

@Test func appendCreatesParentDirectory() throws {
    let root = FileManager.default.temporaryDirectory
        .appending(path: "intentional-test-\(UUID().uuidString)")
    let url = root.appending(path: "nested/events.log")
    defer { try? FileManager.default.removeItem(at: root) }

    let log = EventLog(fileURL: url)
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), type: .started))

    #expect(FileManager.default.fileExists(atPath: url.path))
}
