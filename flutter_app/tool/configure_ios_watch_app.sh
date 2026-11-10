#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
test -f ios/Runner.xcodeproj/project.pbxproj
test -f ios/Runner/AppDelegate.swift

gem install xcodeproj --no-document
mkdir -p ios/WatchApp ios/Runner

cat > ios/WatchApp/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>WKWatchKitApp</key>
    <true/>
    <key>WKCompanionAppBundleIdentifier</key>
    <string>com.salawat_quran.salawat_quran</string>
</dict>
</plist>
PLIST

ruby <<'RUBY'
require 'xcodeproj'

project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = project.targets.find { |target| target.name == 'Runner' }
abort 'Runner target not found' unless runner

watch_name = 'SalawatWatchApp'
watch = project.targets.find { |target| target.name == watch_name }
watch ||= project.new_target(:application, watch_name, :watchos, '10.0')
watch.product_name = watch_name

watch.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.salawat_quran.salawat_quran.watchkitapp'
  settings['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  settings['TARGETED_DEVICE_FAMILY'] = '4'
  settings['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
  settings['SDKROOT'] = 'watchos'
  settings['SWIFT_VERSION'] = '5.0'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['INFOPLIST_FILE'] = 'WatchApp/Info.plist'
  settings['SKIP_INSTALL'] = 'YES'
  settings['WKWatchKitApp'] = 'YES'
end

watch_group = project.main_group.find_subpath('WatchApp', true)
source = watch_group.files.find { |file| file.path == 'SalawatWatchApp.swift' } ||
         watch_group.new_file('SalawatWatchApp.swift')
watch.source_build_phase.add_file_reference(source) unless watch.source_build_phase.files_references.include?(source)

%w[SwiftUI.framework WatchConnectivity.framework].each do |framework|
  ref = project.frameworks_group.files.find { |file| file.path == "/System/Library/Frameworks/#{framework}" } ||
        project.frameworks_group.new_file("/System/Library/Frameworks/#{framework}")
  watch.frameworks_build_phase.add_file_reference(ref) unless watch.frameworks_build_phase.files_references.include?(ref)
end

runner.add_dependency(watch) unless runner.dependencies.any? { |dependency| dependency.target == watch }
embed = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed Watch Content' } ||
        runner.new_copy_files_build_phase('Embed Watch Content')
embed.dst_subfolder_spec = '16'
unless embed.files_references.include?(watch.product_reference)
  build_file = embed.add_file_reference(watch.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
end

runner_group = project.main_group.find_subpath('Runner', true)
bridge = runner_group.files.find { |file| file.path == 'WatchPrayerSync.swift' } ||
         runner_group.new_file('WatchPrayerSync.swift')
runner.source_build_phase.add_file_reference(bridge) unless runner.source_build_phase.files_references.include?(bridge)

watch_connectivity = project.frameworks_group.files.find { |file| file.path == '/System/Library/Frameworks/WatchConnectivity.framework' } ||
                     project.frameworks_group.new_file('/System/Library/Frameworks/WatchConnectivity.framework')
runner.frameworks_build_phase.add_file_reference(watch_connectivity) unless runner.frameworks_build_phase.files_references.include?(watch_connectivity)

project.save

app_delegate_path = 'ios/Runner/AppDelegate.swift'
app_delegate = File.read(app_delegate_path)
unless app_delegate.include?('com.salawat_quran/watch_sync')
  replaced = app_delegate.sub!('GeneratedPluginRegistrant.register(with: self)', <<~SWIFT.strip)
    GeneratedPluginRegistrant.register(with: self)

    WatchPrayerSync.shared.activate()
    if let controller = window?.rootViewController as? FlutterViewController {
      let watchSyncChannel = FlutterMethodChannel(
        name: "com.salawat_quran/watch_sync",
        binaryMessenger: controller.binaryMessenger
      )
      watchSyncChannel.setMethodCallHandler { call, result in
        guard call.method == "syncNextPrayer",
              let arguments = call.arguments as? [String: Any],
              let enabled = arguments["enabled"] as? Bool,
              let schedule = arguments["schedule"] as? String,
              let locale = arguments["locale"] as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        WatchPrayerSync.shared.sync(enabled: enabled, schedule: schedule, locale: locale)
        result(nil)
      }
    }
  SWIFT
  abort 'Could not find Flutter plugin registration in AppDelegate.swift' unless replaced
  File.write(app_delegate_path, app_delegate)
end

puts 'Configured the minimal Apple Watch companion app and WatchConnectivity bridge.'
RUBY
