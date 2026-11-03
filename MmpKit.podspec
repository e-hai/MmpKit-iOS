Pod::Spec.new do |s|
  s.name             = 'MmpKit'
  s.version          = '1.0.0'
  s.summary          = 'Unified MMP Attribution SDK wrapper for iOS (AppsFlyer, Adjust, etc.)'
  s.description      = <<-DESC
MmpKit provides a unified, cross-platform architecture and Swift facade for Mobile Measurement Partners (MMP)
such as AppsFlyer and Adjust on iOS. Apps interact only with the unified Mmp facade, switching MMP vendors
without modifying application business logic.
                       DESC
  s.homepage         = 'https://github.com/e-hai/MmpKit-iOS'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'e-hai' => 'contact@example.com' }
  s.source           = { :git => 'https://github.com/e-hai/MmpKit-iOS.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.9'

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/MmpCore/**/*.{swift}'
    ss.frameworks   = 'Foundation'
  end

  s.subspec 'AppsFlyer' do |ss|
    ss.dependency 'MmpKit/Core'
    ss.dependency 'AppsFlyerFramework', '~> 6.14.0'
    ss.source_files = 'Sources/MmpAppsFlyer/**/*.{swift}'
  end

  s.subspec 'Adjust' do |ss|
    ss.dependency 'MmpKit/Core'
    ss.dependency 'Adjust', '~> 4.38.0'
    ss.source_files = 'Sources/MmpAdjust/**/*.{swift}'
  end
end
