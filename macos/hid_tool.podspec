#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hid_tool.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'hid_tool'
  s.version          = '0.0.7'
  s.summary          = 'A flutter plugin for HID.'
  s.description      = <<-DESC
A flutter plugin for communicating with HID devices (Human Interface Device).
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'hid_tool/Sources/hid_tool/**/*.swift'
  s.dependency 'FlutterMacOS'
  # Only used when Swift Package Manager is disabled. With Swift Package Manager
  # enabled the same hidapi sources are built from third_party/hidapi via
  # hid_tool/Package.swift instead.
  s.dependency 'hidapi', '0.15.0'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  s.frameworks = 'IOKit'
end
