use_frameworks!

def shared_pods
    pod 'AKPickerView-Swift'
    pod 'Alamofire', '= 3.5.1'
    pod 'ARSLineProgress', '~> 1.0'
    pod 'AsyncKit', '~> 1.2'
    pod 'AsyncSwift', '= 1.7.4'
    pod 'AwesomeCache', :git => 'https://github.com/aschuch/AwesomeCache.git', :branch => 'swift2.3'
    pod 'Charts', '~> 2.3.1'
    pod 'CryptoSwift', '~> 0.5.2'
    pod 'Dodo', '~> 2.2'
    pod 'EasyAnimation', '~> 1.0.5'
    pod 'EasyTipView', '= 1.0.1'
    pod 'FileKit', '~> 2.0.0'
    pod 'Former', '~> 1.4.0'
    pod 'Granola', :git => 'https://github.com/yanif/Granola.git'
    pod 'HealthKitSampleGenerator'
    pod 'HTPressableButton'
    pod 'JWTDecode', '~> 1.1.0'
    pod 'Locksmith', :git => 'https://github.com/matthewpalmer/Locksmith.git', :branch => 'swift-2.3'
    pod 'LogKit', '~> 2.3'
    pod 'MCCircadianQueries', :git => 'https://github.com/twoolf/MCCircadianQueries.git'
    pod 'MGSwipeTableCell', '~> 1.5.5'
    pod 'Navajo-Swift', '~> 0.0.6'
    pod 'NVActivityIndicatorView', '~> 2.12'
    pod 'Pages', '~> 0.6'
    pod 'ReachabilitySwift', '~> 2.3'
    pod 'ResearchKit', :git => 'https://github.com/twoolf/ResearchKit.git'
    pod 'Realm', '~> 1.0'
    pod 'RealmSwift', '~> 1.0'
    pod 'SORandom'
    pod 'Stormpath', :git => 'https://github.com/stormpath/stormpath-sdk-ios.git', :branch => 'swift2.3'
    pod 'SwiftChart', '= 0.2.1'
    pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git', :branch => 'feature/swift_23' 
    pod 'SwiftyBeaver', ‘= 0.7.0'
    pod 'SwiftyJSON', '~> 2.4.0'
    pod 'SwiftyUserDefaults', '~> 2.0'
    pod 'SwiftMessages', '~> 2.0.0'
end

target 'MetabolicCompassKit' do
    shared_pods
end

target 'MetabolicCompass' do
    shared_pods
    pod 'Crashlytics'
    pod 'Fabric'
end

target 'MetabolicCompassWatchExtension' do 
 platform :watchos, '2.0'
 pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git', :branch => 'feature/swift_23' 
 pod 'SwiftyBeaver',  ‘= 0.7.0'
 pod 'AwesomeCache', :git => 'https://github.com/aschuch/AwesomeCache.git', :branch => 'swift2.3'
 pod 'MCCircadianQueries', :git => 'https://github.com/twoolf/MCCircadianQueries.git'
end

target 'MetabolicCompassWatch' do
 platform :watchos, '2.0'
 pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git', :branch => 'feature/swift_23' 
 pod 'SwiftyBeaver',  ‘= 0.7.0'
 pod 'AwesomeCache', :git => 'https://github.com/aschuch/AwesomeCache.git', :branch => 'swift2.3'
 pod 'MCCircadianQueries', :git => 'https://github.com/twoolf/MCCircadianQueries.git'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'NO'
    end
  end

# Force swift 2.3 config
post_install do |installer|
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '2.3'
      end
  end
end

end
