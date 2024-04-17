#
# Be sure to run `pod lib lint VoipLibIOS.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.platform = :ios
  s.ios.deployment_target = '12.0'
  s.requires_arc = true
  s.swift_version = "5"
    
  s.name             = 'VoipLibIOS'
  s.version          = '1.0.0'
  s.summary          = 'A short description of VoipLibIOS.'
  
  s.description      = 'This library is an opinionated sip-wrapper'
  s.homepage         = 'https://github.com/hieujames/VoipLibIOS.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { '37453099' => 'hieujames741@gmail.com' }
  s.source           = { :git => 'https://github.com/hieujames/VoipLibIOS.git', :tag => s.version.to_s }


  s.source_files = 'VoipLibIOS/**/*'
  
  s.vendored_frameworks = 'linphone-sdk-novideo-frameworks/*'
  s.framework = 'UIKit'
  s.dependency 'Swinject', '~> 2.8.2'
  
end
