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
    case checkInDone = "check_in_done"
    case checkInNotDone = "check_in_not_done"
    case checkInSkipped = "check_in_skipped"
}

struct LogEntry: Codable {
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
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: tsString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .ts, in: c, debugDescription: "invalid ISO8601 timestamp"
            )
        }
        let typeString = try c.decode(String.self, forKey: .type)
        guard let parsedType = EventType(rawValue: typeString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: c, debugDescription: "unknown event type \(typeString)"
            )
        }
        self.timestamp = date
        self.type = parsedType
        self.intention = try c.decodeIfPresent(String.self, forKey: .intention)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()
        try c.encode(formatter.string(from: timestamp), forKey: .ts)
        try c.encode(type.rawValue, forKey: .type)
        try c.encodeIfPresent(intention, forKey: .intention)
    }
}

struct EventLog {
    let fileURL: URL

    static func format(_ entry: LogEntry) -> String {
        let formatter = ISO8601DateFormatter()
        var parts = [
            "\"ts\":\"\(formatter.string(from: entry.timestamp))\"",
            "\"type\":\"\(entry.type.rawValue)\""
        ]
        if let intention = entry.intention {
            parts.append("\"intention\":\"\(escape(intention))\"")
        }
        return "{" + parts.joined(separator: ",") + "}"
    }

    private static func escape(_ s: String) -> String {
        var out = ""
        out.reserveCapacity(s.count)
        for ch in s {
            switch ch {
            case "\\": out.append(#"\\"#)
            case "\"": out.append(#"\""#)
            case "\n": out.append(#"\n"#)
            case "\r": out.append(#"\r"#)
            case "\t": out.append(#"\t"#)
            default: out.append(ch)
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

    static func defaultLocation() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appending(path: "Intentional/events.log")
    }
}
