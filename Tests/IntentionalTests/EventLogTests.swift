import Foundation
import Testing
@testable import Intentional

@Test func formatProducesJSONLineForSimpleEvent() {
    let entry = LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), type: .unlock)
    #expect(EventLog.format(entry) == #"{"ts":"2023-11-14T22:13:20Z","type":"unlock"}"#)
}

@Test func formatIncludesIntentionPayload() {
    let entry = LogEntry(
        timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        type: .intention,
        intention: "write tests"
    )
    #expect(EventLog.format(entry) == #"{"ts":"2023-11-14T22:13:20Z","type":"intention","intention":"write tests"}"#)
}

@Test func formatEscapesQuotesAndBackslashesInIntention() {
    let entry = LogEntry(
        timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        type: .intention,
        intention: #"reply to "Anna" \ then ship"#
    )
    #expect(EventLog.format(entry) == #"{"ts":"2023-11-14T22:13:20Z","type":"intention","intention":"reply to \"Anna\" \\ then ship"}"#)
}

@Test func appendWritesLinesInOrder() throws {
    let url = FileManager.default.temporaryDirectory
        .appending(path: "intentional-test-\(UUID().uuidString).log")
    defer { try? FileManager.default.removeItem(at: url) }

    let log = EventLog(fileURL: url)
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_000), type: .unlock))
    try log.append(LogEntry(timestamp: Date(timeIntervalSince1970: 1_700_000_010), type: .lock))

    let contents = try String(contentsOf: url, encoding: .utf8)
    #expect(contents == """
        {"ts":"2023-11-14T22:13:20Z","type":"unlock"}
        {"ts":"2023-11-14T22:13:30Z","type":"lock"}

        """)
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

@Test func supportsAllEventTypes() {
    #expect(EventType.started.rawValue == "started")
    #expect(EventType.unlock.rawValue == "unlock")
    #expect(EventType.lock.rawValue == "lock")
    #expect(EventType.prompted.rawValue == "prompted")
    #expect(EventType.intention.rawValue == "intention")
    #expect(EventType.skipped.rawValue == "skipped")
    #expect(EventType.pomodoroCompleted.rawValue == "pomodoro_completed")
    #expect(EventType.pomodoroEndedEarly.rawValue == "pomodoro_ended_early")
    #expect(EventType.checkInDone.rawValue == "check_in_done")
    #expect(EventType.checkInNotDone.rawValue == "check_in_not_done")
    #expect(EventType.checkInSkipped.rawValue == "check_in_skipped")
}
