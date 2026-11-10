import WidgetKit
import SwiftUI

private let appGroupId = "group.com.salawat_quran"
private let widgetKind = "NextPrayerLockScreenWidget"

private struct PrayerRecord: Decodable {
    let name: String
    let arabicName: String
    let timestamp: String
}

private struct NextPrayerEntry: TimelineEntry {
    let date: Date
    let hijriDate: String
    let prayerName: String
    let prayerTime: String
    let prayerDate: Date?
    let enabled: Bool
    let isArabic: Bool
}

private struct NextPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPrayerEntry {
        makeEntry(at: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPrayerEntry) -> Void) {
        completion(makeEntry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPrayerEntry>) -> Void) {
        let now = Date()
        let records = loadRecords()
        var dates = [now]
        dates.append(contentsOf: records.compactMap { parseDate($0.timestamp) }.filter { $0 > now }.map { $0.addingTimeInterval(1) })
        let entries = dates.sorted().map { makeEntry(at: $0) }
        let refresh = (records.compactMap { parseDate($0.timestamp) }.max() ?? now.addingTimeInterval(6 * 60 * 60)).addingTimeInterval(60)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func loadRecords() -> [PrayerRecord] {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              defaults.bool(forKey: "widget_enabled"),
              let raw = defaults.string(forKey: "prayer_schedule"),
              let data = raw.data(using: .utf8),
              let records = try? JSONDecoder().decode([PrayerRecord].self, from: data) else {
            return []
        }
        return records.sorted { (parseDate($0.timestamp) ?? .distantFuture) < (parseDate($1.timestamp) ?? .distantFuture) }
    }

    private func parseDate(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: value) { return date }
        let standard = ISO8601DateFormatter()
        return standard.date(from: value)
    }

    private func makeEntry(at date: Date) -> NextPrayerEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let isArabic = (defaults?.string(forKey: "widget_locale") ?? "ar") == "ar"
        let enabled = defaults?.bool(forKey: "widget_enabled") ?? false
        let next = loadRecords().first { (parseDate($0.timestamp) ?? .distantPast) > date }
        let prayerDate = next.flatMap { parseDate($0.timestamp) }
        let hijri = DateFormatter()
        hijri.calendar = Calendar(identifier: .islamicUmmAlQura)
        hijri.locale = Locale(identifier: isArabic ? "ar_SA" : "en")
        hijri.dateFormat = "d MMMM yyyy"
        let time = DateFormatter()
        time.locale = Locale(identifier: isArabic ? "ar" : "en_US")
        time.timeZone = .current
        time.dateFormat = isArabic ? "HH:mm" : "h:mm a"
        return NextPrayerEntry(
            date: date,
            hijriDate: hijri.string(from: date),
            prayerName: next.map { isArabic ? $0.arabicName : $0.name } ?? (isArabic ? "الفجر" : "Fajr"),
            prayerTime: prayerDate.map { time.string(from: $0) } ?? "--:--",
            prayerDate: prayerDate,
            enabled: enabled,
            isArabic: isArabic
        )
    }
}

private struct NextPrayerWidgetView: View {
    let entry: NextPrayerProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: family == .accessoryRectangular ? 3 : 7) {
            Text(entry.hijriDate)
                .font(family == .accessoryRectangular ? .caption2 : .caption)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if !entry.enabled {
                Text(entry.isArabic ? "فعّل الويدجت من الإعدادات" : "Enable widget in Settings")
                    .font(.caption)
                    .lineLimit(2)
            } else {
                HStack(spacing: 4) {
                    Text(entry.isArabic ? "الصلاة القادمة:" : "Next prayer:")
                        .font(.caption2)
                    Text(entry.prayerName)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                HStack(spacing: 5) {
                    Text(entry.prayerTime)
                        .font(.caption)
                    if let prayerDate = entry.prayerDate {
                        Text(timerInterval: entry.date...prayerDate, countsDown: true)
                            .font(family == .accessoryRectangular ? .caption : .title3.monospacedDigit())
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .foregroundStyle(family == .accessoryRectangular ? .white : Color.primary)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(family == .accessoryRectangular ? 2 : 12)
        .background(family == .accessoryRectangular ? Color.clear : Color(red: 0.04, green: 0.16, blue: 0.13))
        .widgetURL(URL(string: "salawatquran://prayer"))
    }
}

@main
struct NextPrayerLockScreenWidget: Widget {
    let kind = widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPrayerProvider()) { entry in
            NextPrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Prayer")
        .description("Hijri date, next prayer time and live countdown.")
        .supportedFamilies([.accessoryRectangular, .systemSmall])
    }
}
