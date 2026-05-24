import Foundation

enum EventType: String {
    case started
    case unlock
    case lock
}

struct LogEntry {
    let timestamp: Date
    let type: EventType
}

struct EventLog {
    let fileURL: URL

    static func format(_ entry: LogEntry) -> String {
        let formatter = ISO8601DateFormatter()
        return "\(formatter.string(from: entry.timestamp))\t\(entry.type.rawValue)"
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
