import Foundation
import Testing
@testable import Intentional

@Test func readAllOnMissingFileReturnsEmpty() throws {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "intentional-test-\(UUID().uuidString).log")
    let log = EventLog(fileURL: url)
    #expect(try log.readAll().isEmpty)
}

@Test func readAllReturnsAppendedEntriesInOrder() throws {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "intentional-test-\(UUID().uuidString).log")
    defer { try? FileManager.default.removeItem(at: url) }
    let log = EventLog(fileURL: url)

    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), type: .unlock))
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_010), type: .intention, intention: "ship summary"))
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_020), type: .checkInDone))

    let entries = try log.readAll()
    #expect(entries.count == 3)
    #expect(entries[0].type == .unlock)
    #expect(entries[1].type == .intention)
    #expect(entries[1].intention == "ship summary")
    #expect(entries[2].type == .checkInDone)
}

@Test func readAllSkipsMalformedLines() throws {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "intentional-test-\(UUID().uuidString).log")
    defer { try? FileManager.default.removeItem(at: url) }

    let raw = """
        {"ts":"2023-11-14T22:13:20Z","type":"unlock"}
        this is not json
        {"ts":"2023-11-14T22:13:30Z","type":"intention","intention":"x"}

        """
    try raw.write(to: url, atomically: true, encoding: .utf8)

    let log = EventLog(fileURL: url)
    let entries = try log.readAll()
    #expect(entries.count == 2)
    #expect(entries[0].type == .unlock)
    #expect(entries[1].type == .intention)
}

@Test func readAllPreservesEscapedIntention() throws {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "intentional-test-\(UUID().uuidString).log")
    defer { try? FileManager.default.removeItem(at: url) }
    let log = EventLog(fileURL: url)

    let payload = #"reply to "Anna" \ then ship"#
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), type: .intention, intention: payload))

    let entries = try log.readAll()
    #expect(entries.first?.intention == payload)
}
