import Foundation
import WatchConnectivity

final class WatchPrayerSync: NSObject, WCSessionDelegate {
    static let shared = WatchPrayerSync()

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
        let payload: [String: Any] = [
            "enabled": enabled,
            "schedule": schedule,
            "locale": locale
        ]
        let session = WCSession.default
        if session.activationState == .activated {
            try? session.updateApplicationContext(payload)
            session.transferUserInfo(payload)
        } else {
            activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                guard session.activationState == .activated else { return }
                try? session.updateApplicationContext(payload)
                session.transferUserInfo(payload)
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
}
