import Foundation

enum EventType: String {
    case started
    case unlock
    case lock
    case prompted
    case intention
    case skipped
}

struct LogEntry {
    let timestamp: Date
    let type: EventType
    let intention: String?

    init(timestamp: Date, type: EventType, intention: String? = nil) {
        self.timestamp = timestamp
        self.type = type
        self.intention = intention
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

    static func defaultLocation() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        return appSupport.appending(path: "Intentional/events.log")
    }
}
