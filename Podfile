use_frameworks!

def shared_pods
    pod 'AKPickerView-Swift'
    pod 'Alamofire', '~> 2.0'
    pod 'ARSLineProgress', '~> 1.0'
    pod 'AsyncKit', '~> 1.2'
    pod 'AsyncSwift', '~> 1.7'
    pod 'AwesomeCache'
    pod 'Charts', :git => 'https://github.com/danielgindi/ios-charts.git', :commit => '098b961b4c'
    pod 'CryptoSwift', '~> 0.5.2'
    pod 'Dodo', '~> 2.0'
    pod 'EasyAnimation', '~> 1.0.5'
    pod 'EasyTipView', '= 1.0.0'
    pod 'FileKit', '~> 2.0.0'
    pod 'Former', '~> 1.4.0'
    pod 'Granola', :git => 'https://github.com/yanif/Granola.git'
    pod 'HealthKitSampleGenerator'
    pod 'HTPressableButton'
    pod 'JWTDecode', '~> 1.1.0'
    pod 'Locksmith', '~> 2.0.8'
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
    pod 'Stormpath', '~> 1.2'
    pod 'SwiftChart', '= 0.2.1'
    pod 'SwiftDate', '~> 3.0'
    pod 'SwiftyBeaver', ‘= 0.5.4'
    pod 'SwiftyJSON', '~> 2.0'
    pod 'SwiftyUserDefaults', '~> 2.0'
    pod 'SwiftMessages', '~> 1.1.4'
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
 pod 'SwiftDate', '~> 3.0'
 pod 'SwiftyBeaver',  ‘= 0.5.4'
 pod 'AwesomeCache'
 pod 'MCCircadianQueries', :git => 'https://github.com/twoolf/MCCircadianQueries.git'
end

target 'MetabolicCompassWatch' do
 platform :watchos, '2.0'
 pod 'SwiftDate', '~> 3.0'
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
