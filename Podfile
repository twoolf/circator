use_frameworks!
def shared_pods

    pod 'Auth0', '~> 1.0'
    pod 'AKPickerView-Swift', :git => 'https://github.com/Akkyie/AKPickerView-Swift.git' 
    pod 'Alamofire' 
    pod 'ARSLineProgress' 
    pod 'AsyncKit' 
    pod 'AsyncSwift'
    pod 'AwesomeCache' 
    pod 'Charts' 
    pod 'CryptoSwift' 
    pod 'Dodo' 
    pod 'EasyAnimation' 
    pod 'EasyTipView' 
    pod 'FileKit' 
    pod 'Former' 
    pod 'Granola', :git => 'https://github.com/yanif/Granola.git'
    pod 'HTPressableButton'
    pod 'JWTDecode'
    pod 'Locksmith' 
    pod 'MCCircadianQueries', :git => 'https://github.com/OlenaSrost/MCCircadianQueries.git', :branch => 'swift3'
    pod 'MGSwipeTableCell' 
    pod 'Navajo-Swift' 
    pod 'NVActivityIndicatorView' 
    pod 'Pages' 
    pod 'ReachabilitySwift' 
    pod 'ResearchKit', :git => 'https://github.com/twoolf/ResearchKit.git'
    pod 'Realm' 
    pod 'RealmSwift'
    pod 'Stormpath' 
    pod 'SwiftChart'
    pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git'
    pod 'SwiftyBeaver'
    pod 'SwiftyJSON' 
    pod 'SwiftyUserDefaults', :git => 'https://github.com/radex/SwiftyUserDefaults.git'
    pod 'SwiftMessages’, :git => 'https://github.com/SwiftKickMobile/SwiftMessages.git’, :branch => 'swift4.0’
end

target 'MetabolicCompassKit' do
    platform :ios, '10.0'
    shared_pods
end

target 'MetabolicCompass' do
    platform :ios, '10.0'
    shared_pods
    pod 'Crashlytics'
    pod 'Fabric'
end

#target 'MetabolicCompassWatchExtension' do 
# platform :watchos, '3.0'
# pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git'
# pod 'SwiftyBeaver' 
# pod 'AwesomeCache' 
# pod 'MCCircadianQueries', :git => 'https://github.com/OlenaSrost/MCCircadianQueries.git', :branch => 'swift3'
#end

#target 'MetabolicCompassWatch' do
# platform :watchos, '3.0'
# pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git' 
# pod 'SwiftyBeaver'  
# pod 'AwesomeCache' 
# pod 'MCCircadianQueries', :git => 'https://github.com/OlenaSrost/MCCircadianQueries.git', :branch => 'swift3'
#end


# Force swift 3.0 config
post_install do |installer|
  installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
      end
  end
end

