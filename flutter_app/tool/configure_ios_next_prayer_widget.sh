#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
test -f ios/Runner.xcodeproj/project.pbxproj
gem install xcodeproj --no-document

mkdir -p ios/NextPrayerWidgetExtension
cat > ios/NextPrayerWidgetExtension/NextPrayerWidget.swift <<'SWIFT'
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
        .containerBackground(for: .widget) {
            family == .accessoryRectangular ? Color.clear : Color(red: 0.04, green: 0.16, blue: 0.13)
        }
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
SWIFT

ruby <<'RUBY'
require 'xcodeproj'
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == 'Runner' }
abort 'Runner target not found' unless runner

target_name = 'NextPrayerWidgetExtension'
target = project.targets.find { |item| item.name == target_name }
unless target
  target = project.new_target(:app_extension, target_name, :ios, '16.0')
end

target.product_name = target_name
target.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.salawat_quran.salawat_quran.NextPrayerWidgetExtension'
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  settings['SWIFT_VERSION'] = '5.0'
  settings['SKIP_INSTALL'] = 'YES'
  settings['CODE_SIGN_ENTITLEMENTS'] = 'NextPrayerWidgetExtension/NextPrayerWidgetExtension.entitlements'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['INFOPLIST_KEY_NSExtension_NSExtensionPointIdentifier'] = 'com.apple.widgetkit-extension'
  settings['INFOPLIST_KEY_NSHumanReadableCopyright'] = ''
end

group = project.main_group.find_subpath('NextPrayerWidgetExtension', true)
source = group.files.find { |file| file.path == 'NextPrayerWidget.swift' } ||
         group.new_file('NextPrayerWidget.swift')
target.source_build_phase.add_file_reference(source) unless target.source_build_phase.files_references.include?(source)

%w[WidgetKit.framework SwiftUI.framework].each do |framework|
  ref = project.frameworks_group.files.find { |file| file.path == "/System/Library/Frameworks/#{framework}" } ||
        project.frameworks_group.new_file("/System/Library/Frameworks/#{framework}")
  target.frameworks_build_phase.add_file_reference(ref) unless target.frameworks_build_phase.files_references.include?(ref)
end

runner.add_dependency(target) unless runner.dependencies.any? { |dependency| dependency.target == target }

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

def write_group_entitlements(path)
  File.write(path, <<~PLIST)
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0"><dict><key>com.apple.security.application-groups</key><array><string>group.com.salawat_quran</string></array></dict></plist>
  PLIST
end
write_group_entitlements('ios/Runner/Runner.entitlements')
write_group_entitlements('ios/NextPrayerWidgetExtension/NextPrayerWidgetExtension.entitlements')

embed = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' } ||
        runner.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
unless embed.files_references.include?(target.product_reference)
  build_file = embed.add_file_reference(target.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
end

project.save
puts 'Configured WidgetKit Lock Screen extension and App Group entitlements.'
RUBY
