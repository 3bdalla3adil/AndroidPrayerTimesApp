import Foundation
import WatchConnectivity

final class WatchPrayerSync: NSObject, WCSessionDelegate {
    static let shared = WatchPrayerSync()

    private var pendingPayload: [String: Any]?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sync(enabled: Bool, schedule: String, locale: String) {
        guard WCSession.isSupported() else { return }
        pendingPayload = [
            "enabled": enabled,
            "schedule": schedule,
            "locale": locale
        ]
        if WCSession.default.activationState == .activated {
            sendPendingPayload(using: WCSession.default)
        } else {
            activate()
        }
    }

    private func sendPendingPayload(using session: WCSession) {
        guard let payload = pendingPayload else { return }
        do {
            try session.updateApplicationContext(payload)
            session.transferUserInfo(payload)
            pendingPayload = nil
        } catch {
            print("Unable to sync prayer schedule to Apple Watch: \(error)")
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        if let error { print("Watch connectivity activation failed: \(error)") }
        guard state == .activated else { return }
        sendPendingPayload(using: session)
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
