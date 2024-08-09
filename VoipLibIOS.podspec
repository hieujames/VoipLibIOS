#
# Be sure to run `pod lib lint VoipLibIOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'VoipLibIOS'
  s.version          = '1.0.11'
  s.summary          = 'An opinionated sip-wrapper for iOS'
  s.description      = 'This library provides a comprehensive wrapper for SIP functionality in iOS applications, including core VoIP features, call handling, and chat capabilities.'
  s.homepage         = 'https://github.com/hieujames/VoipLibIOS.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '37453099' => 'hieujames741@gmail.com' }
  s.source           = { :git => 'https://github.com/hieujames/VoipLibIOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.source_files = 'VoipLibIOS/**/*'
  
  s.dependency 'Swinject', '~> 2.8.2'

  s.frameworks = 'UIKit'
  
  s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
  s.user_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }

  s.preserve_paths = 'libs/**/*'
  s.vendored_frameworks = 'libs/*.xcframework'
  
end
