import SwiftUI
import Combine
import WatchConnectivity

struct PrayerRecord: Codable {
    let name: String
    let arabicName: String
    let timestamp: String

    var date: Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = fractional.date(from: timestamp) { return value }
        return ISO8601DateFormatter().date(from: timestamp)
    }
}

@MainActor
final class WatchPrayerStore: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchPrayerStore()

    @Published private(set) var prayers: [PrayerRecord] = []
    @Published private(set) var enabled = false
    @Published private(set) var isArabic = true

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        apply(WCSession.default.receivedApplicationContext)
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        if let error { print("Watch connectivity activation failed: \(error)") }
        DispatchQueue.main.async { self.apply(session.receivedApplicationContext) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.apply(applicationContext) }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        DispatchQueue.main.async { self.apply(userInfo) }
    }

    private func apply(_ payload: [String: Any]) {
        if let value = payload["enabled"] as? Bool { enabled = value }
        if let value = payload["locale"] as? String { isArabic = value == "ar" }
        if let raw = payload["schedule"] as? String,
           let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([PrayerRecord].self, from: data) {
            prayers = decoded.sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
        }
    }

}

@main
struct SalawatWatchApp: App {
    @StateObject private var store = WatchPrayerStore.shared

    var body: some Scene {
        WindowGroup {
            NextPrayerView(store: store)
        }
    }
}

private struct NextPrayerView: View {
    @ObservedObject var store: WatchPrayerStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            let next = store.prayers.first { ($0.date ?? .distantPast) > now }
            let prayerDate = next?.date
            VStack(spacing: 5) {
                Text(hijriDate(now, arabic: store.isArabic))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if store.enabled, let next, let prayerDate {
                    Text(store.isArabic ? next.arabicName : next.name)
                        .font(.system(size: 21, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(prayerDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(countdown(until: prayerDate, now: now))
                        .font(.system(size: 19, weight: .bold, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.75)
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text(store.isArabic ? "افتح التطبيق للمزامنة" : "Open iPhone app to sync")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 3)
        }
    }

    private func countdown(until date: Date, now: Date) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(now)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        if store.isArabic {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    private func hijriDate(_ date: Date, arabic: Bool) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: arabic ? "ar_SA" : "en")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
