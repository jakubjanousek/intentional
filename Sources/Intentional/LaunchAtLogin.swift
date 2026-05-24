import Foundation
import ServiceManagement

enum LaunchAtLogin {
    enum Failure: Error {
        case unavailable
    }

    static var isAvailable: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
            && Bundle.main.bundleIdentifier != nil
    }

    static var isRegistered: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard isAvailable else { throw Failure.unavailable }
        let service = SMAppService.mainApp
        if enabled {
            try service.register()
        } else if service.status == .enabled {
            try service.unregister()
        }
    }
}
