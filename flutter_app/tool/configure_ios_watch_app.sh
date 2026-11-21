#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
test -f ios/Runner.xcodeproj/project.pbxproj
test -f ios/Runner/AppDelegate.swift

gem install xcodeproj --no-document
mkdir -p ios/WatchApp ios/WatchExtension ios/Runner
cp ios/WatchApp/SalawatWatchApp.swift ios/WatchExtension/SalawatWatchApp.swift

cat > ios/WatchApp/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>WKWatchKitApp</key>
    <true/>
    <key>WKCompanionAppBundleIdentifier</key>
    <string>com.salawatquran.salawatQuran</string>
</dict>
</plist>
PLIST

cat > ios/WatchExtension/Info.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>WKAppBundleIdentifier</key>
            <string>com.salawatquran.salawatQuran.watchkitapp</string>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.watchkit</string>
    </dict>
</dict>
</plist>
PLIST

ruby <<'RUBY'
require 'xcodeproj'
require 'yaml'

# Keep the embedded WatchKit bundle versions in lockstep with the Flutter app.
app_version = YAML.load_file('pubspec.yaml')['version'].to_s
marketing_version, build_number = app_version.split('+', 2)
abort "Invalid pubspec version: #{app_version}" if marketing_version.to_s.empty? || build_number.to_s.empty?

project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
runner = project.targets.find { |target| target.name == 'Runner' }
abort 'Runner target not found' unless runner

watch_name = 'SalawatWatchApp'
extension_name = 'SalawatWatchExtension'

# Use Xcodeproj's native watchOS target types from creation time. Creating
# generic iOS application/extension targets and mutating product_type later
# leaves Xcode's target platform metadata inconsistent.
watch = project.targets.find { |target| target.name == watch_name }
watch ||= project.new_target(:watch2_app, watch_name, :watchos, '10.0')
watch.product_type = Xcodeproj::Constants::PRODUCT_TYPE_UTI[:watch2_app]
watch.product_name = watch_name
watch.product_reference.path = "#{watch_name}.app"
watch.product_reference.name = "#{watch_name}.app"

extension = project.targets.find { |target| target.name == extension_name }
extension ||= project.new_target(:watch2_extension, extension_name, :watchos, '10.0')
extension.product_type = Xcodeproj::Constants::PRODUCT_TYPE_UTI[:watch2_extension]
extension.product_name = extension_name
extension.product_reference.path = "#{extension_name}.appex"
extension.product_reference.name = "#{extension_name}.appex"

watch.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.salawatquran.salawatQuran.watchkitapp'
  settings['PRODUCT_NAME'] = watch_name
  settings['EXECUTABLE_NAME'] = watch_name
  settings['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  settings['TARGETED_DEVICE_FAMILY'] = '4'
  settings['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
  settings['SDKROOT'] = 'watchos'
  settings['SWIFT_VERSION'] = '5.0'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['INFOPLIST_FILE'] = 'WatchApp/Info.plist'
  settings['MARKETING_VERSION'] = marketing_version
  settings['CURRENT_PROJECT_VERSION'] = build_number
  settings['INFOPLIST_KEY_CFBundleShortVersionString'] = marketing_version
  settings['INFOPLIST_KEY_CFBundleVersion'] = build_number
  settings['SKIP_INSTALL'] = 'YES'
  settings['WKWatchKitApp'] = 'YES'
end

extension.build_configurations.each do |config|
  settings = config.build_settings
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.salawatquran.salawatQuran.watchkitapp.watchkitextension'
  settings['PRODUCT_NAME'] = extension_name
  settings['EXECUTABLE_NAME'] = extension_name
  settings['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  settings['TARGETED_DEVICE_FAMILY'] = '4'
  settings['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
  settings['SDKROOT'] = 'watchos'
  settings['SWIFT_VERSION'] = '5.0'
  settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  settings['INFOPLIST_FILE'] = 'WatchExtension/Info.plist'
  settings['MARKETING_VERSION'] = marketing_version
  settings['CURRENT_PROJECT_VERSION'] = build_number
  settings['INFOPLIST_KEY_CFBundleShortVersionString'] = marketing_version
  settings['INFOPLIST_KEY_CFBundleVersion'] = build_number
  settings['SKIP_INSTALL'] = 'YES'
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
end

watch_group = project.main_group.find_subpath('WatchApp', true)
watch_group.path = 'WatchApp'
extension_group = project.main_group.find_subpath('WatchExtension', true)
extension_group.path = 'WatchExtension'

# The SwiftUI @main app is the WatchKit extension executable, not the
# containing WatchKit app. This distinction is required by Xcode's watchOS
# app validation.
source = extension_group.files.find { |file| file.path == 'SalawatWatchApp.swift' } ||
         extension_group.new_file('SalawatWatchApp.swift')
extension.source_build_phase.add_file_reference(source) unless extension.source_build_phase.files_references.include?(source)

%w[SwiftUI.framework Combine.framework WatchConnectivity.framework].each do |framework|
  ref = project.frameworks_group.files.find { |file| file.path == "/System/Library/Frameworks/#{framework}" } ||
        project.frameworks_group.new_file("/System/Library/Frameworks/#{framework}")
  extension.frameworks_build_phase.add_file_reference(ref) unless extension.frameworks_build_phase.files_references.include?(ref)
end

watch.add_dependency(extension) unless watch.dependencies.any? { |dependency| dependency.target == extension }
embed_extension = watch.copy_files_build_phases.find { |phase| phase.name == 'Embed WatchKit Extension' } ||
                 watch.new_copy_files_build_phase('Embed WatchKit Extension')
embed_extension.dst_subfolder_spec = '13'
unless embed_extension.files_references.include?(extension.product_reference)
  build_file = embed_extension.add_file_reference(extension.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
end

runner.add_dependency(watch) unless runner.dependencies.any? { |dependency| dependency.target == watch }
embed_watch = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed Watch Content' } ||
              runner.new_copy_files_build_phase('Embed Watch Content')
embed_watch.dst_subfolder_spec = '16'
unless embed_watch.files_references.include?(watch.product_reference)
  build_file = embed_watch.add_file_reference(watch.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
end

# Embed Watch content before Flutter's Thin Binary phase to avoid a build
# dependency cycle through Runner's generated Info.plist.
thin_binary = runner.shell_script_build_phases.find { |phase| phase.name == 'Thin Binary' }
if thin_binary
  runner.build_phases.delete(embed_watch)
  runner.build_phases.insert(runner.build_phases.index(thin_binary), embed_watch)
end

runner_group = project.main_group.find_subpath('Runner', true)
runner_group.path = 'Runner'
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
  app_delegate.sub!(/\A/, "import Flutter\n") unless app_delegate.include?('import Flutter')
  bridge_code = <<~SWIFT
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

  registration = 'GeneratedPluginRegistrant.register(with: self)'
  if app_delegate.include?(registration)
    app_delegate.sub!(registration, registration + "\n\n" + bridge_code)
  else
    return_marker = 'return super.application(application, didFinishLaunchingWithOptions: launchOptions)'
    abort 'Could not locate a safe AppDelegate launch hook for WatchConnectivity' unless app_delegate.include?(return_marker)
    app_delegate.sub!(return_marker, bridge_code + "\n" + return_marker)
  end
  File.write(app_delegate_path, app_delegate)
end

puts 'Configured a WatchKit app container, embedded WatchKit extension, and WatchConnectivity bridge.'
RUBY
