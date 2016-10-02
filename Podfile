use_frameworks!

def shared_pods
    pod 'ResearchKit', :git => 'https://github.com/twoolf/ResearchKit.git'
    pod 'MCCircadianQueries', :git => 'https://github.com/twoolf/MCCircadianQueries.git'
    pod 'Charts', :git => 'https://github.com/danielgindi/ios-charts.git', :commit => '098b961b4c'
    pod 'EasyAnimation'
    pod 'Alamofire', '~> 2.0'
    pod 'Realm'
    pod 'RealmSwift'
    pod 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git', :branch => 'swift2'
    pod 'SwiftDate'
    pod 'SwiftyUserDefaults'
    pod 'SwiftyBeaver', ‘= 0.5.4'
    pod 'Dodo', '~> 2.0'
    pod 'CryptoSwift'
    pod 'AsyncSwift'
    pod 'Locksmith'
    pod 'Granola', :git => 'https://github.com/yanif/Granola.git'
    pod 'Stormpath', '~> 1.2'
    pod 'Former'
    pod 'HTPressableButton'
    pod 'MGSwipeTableCell'
    pod 'Pages'
    pod 'SwiftChart'
    pod 'SORandom'
    pod 'FileKit', '~> 2.0.0'
    pod 'JWTDecode', '~> 1.0'
    pod 'AKPickerView-Swift'
    pod 'AsyncKit'
    pod 'AwesomeCache'
    pod 'EasyTipView'
    pod 'HealthKitSampleGenerator'
    pod 'ReachabilitySwift'
    pod 'Navajo-Swift'
    pod 'ARSLineProgress', '~> 1.0'
    pod 'NVActivityIndicatorView', '~> 2.12'
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
 pod 'SwiftDate'
 pod 'SwiftyBeaver',  ‘= 0.5.4'
 pod 'AwesomeCache'
 pod 'MCCircadianQueries', :git => 'https://github.com/twoolf/MCCircadianQueries.git'
end

target 'MetabolicCompassWatch' do
 platform :watchos, '2.0'
 pod 'SwiftDate'
 pod 'SwiftyBeaver',  ‘= 0.5.4'
 pod 'AwesomeCache'
 pod 'MCCircadianQueries', :git => 'https://github.com/twoolf/MCCircadianQueries.git'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'NO'
    end
  end
end
