import Foundation

enum EventType: String {
    case started
    case unlock
    case lock
    case prompted
    case intention
    case skipped
    case pomodoroCompleted = "pomodoro_completed"
    case pomodoroEndedEarly = "pomodoro_ended_early"
    case outcomeDone = "outcome_done"
    case outcomeFailed = "outcome_failed"
    case outcomeSkipped = "outcome_skipped"
    case breakStarted = "break_started"
    case breakCompleted = "break_completed"
    case breakEndedEarly = "break_ended_early"
    case idleStarted = "idle_started"
    case idleEnded = "idle_ended"

    static func decode(_ raw: String) -> EventType? {
        if let direct = EventType(rawValue: raw) { return direct }
        switch raw {
        case "check_in_done": return .outcomeDone
        case "check_in_not_done": return .outcomeFailed
        case "check_in_skipped": return .outcomeSkipped
        default: return nil
        }
    }
}

struct LogEntry: Decodable {
    let timestamp: Date
    let type: EventType
    let intention: String?

    init(timestamp: Date, type: EventType, intention: String? = nil) {
        self.timestamp = timestamp
        self.type = type
        self.intention = intention
    }

    private enum CodingKeys: String, CodingKey {
        case ts, type, intention
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let tsString = try c.decode(String.self, forKey: .ts)
        guard let date = EventLog.iso8601.date(from: tsString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .ts, in: c, debugDescription: "invalid ISO8601 timestamp"
            )
        }
        let typeString = try c.decode(String.self, forKey: .type)
        guard let parsedType = EventType.decode(typeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c, debugDescription: "unknown event type \(typeString)"
            )
        }
        self.timestamp = date
        self.type = parsedType
        self.intention = try c.decodeIfPresent(String.self, forKey: .intention)
    }
}

struct EventLog {
    let fileURL: URL

    nonisolated(unsafe) static let iso8601 = ISO8601DateFormatter()

    static func format(_ entry: LogEntry) -> String {
        var parts = [
            "\"ts\":\"\(iso8601.string(from: entry.timestamp))\"",
            "\"type\":\"\(entry.type.rawValue)\""
        ]
        if let intention = entry.intention {
            parts.append("\"intention\":\"\(escape(intention))\"")
        }
        return "{" + parts.joined(separator: ",") + "}"
    }

    private static func escape(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.unicodeScalars.count)
        for scalar in s.unicodeScalars {
            switch scalar.value {
            case 0x22: out.append(#"\""#)
            case 0x5C: out.append(#"\\"#)
            case 0x08: out.append(#"\b"#)
            case 0x09: out.append(#"\t"#)
            case 0x0A: out.append(#"\n"#)
            case 0x0C: out.append(#"\f"#)
            case 0x0D: out.append(#"\r"#)
            case 0x00...0x1F:
                out.append(String(format: #"\u%04x"#, scalar.value))
            default:
                out.unicodeScalars.append(scalar)
            }
        }
        return out
    }

    func append(_ entry: LogEntry) throws {
        let line = EventLog.format(entry) + "\n"
        let data = Data(line.utf8)

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if FileManager.default.fileExists(atPath: fileURL.path) {
            let handle = try FileHandle(forWritingTo: fileURL)
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
            try handle.close()
        } else {
            try data.write(to: fileURL)
        }
    }

    func rewrite(_ entries: [LogEntry]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let body = entries.map { EventLog.format($0) }.joined(separator: "\n")
        let text = entries.isEmpty ? "" : body + "\n"
        try Data(text.utf8).write(to: fileURL, options: .atomic)
    }

    func readAll() throws -> [LogEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        let decoder = JSONDecoder()
        return text.split(separator: "\n", omittingEmptySubsequences: true).compactMap { line in
            guard let lineData = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(LogEntry.self, from: lineData)
        }
    }

    func lastIntention() throws -> String? {
        let entries = try readAll()
        return entries.reversed().first { $0.type == .intention }?.intention
    }

    static func defaultLocation() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appending(path: "Intentional/events.log")
    }
}
