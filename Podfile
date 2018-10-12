use_frameworks!

def circadian_queries
    pod 'MCCircadianQueries', :git => 'https://github.com/OlenaSrost/MCCircadianQueries.git', :branch => 'cache_improvements'
end

def shared_pods
    pod 'Auth0', '~> 1.0'
    pod 'AKPickerView-Swift', :git => 'https://github.com/Akkyie/AKPickerView-Swift.git'
    pod 'Alamofire' 
    pod 'ARSLineProgress' 
    pod 'AsyncKit' 
    pod 'AsyncSwift'
    pod 'AwesomeCache’, :git => ‘https://github.com/aschuch/AwesomeCache.git’, :branch => ‘master’
    pod 'Charts' , :git => 'https://github.com/OlenaSrost/Charts.git’
    pod 'CryptoSwift' 
    pod 'Dodo', '~> 11.0'
    pod 'EasyAnimation' 
    pod 'EasyTipView' 
    pod 'FileKit', :git => 'https://github.com/nvzqz/FileKit.git', :branch => 'master'
    pod 'Former' 
    pod 'Granola', :git => 'https://github.com/yanif/Granola.git'
    pod 'HTPressableButton'
    pod 'JWTDecode'
    pod 'Locksmith' 
    
    pod 'MGSwipeTableCell' 
    pod 'Navajo-Swift' 
    pod 'NVActivityIndicatorView' 
    pod 'Pages' 
    pod 'ReachabilitySwift', '~> 3.0’ 
    pod 'ResearchKit', :git => 'https://github.com/twoolf/ResearchKit.git'
    pod 'Realm' 
    pod 'RealmSwift'
    pod 'SwiftChart'
    pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git'
    pod 'SwiftyBeaver', :git => 'https://github.com/SwiftyBeaver/SwiftyBeaver.git', :branch => 'master'
    pod 'SwiftyJSON' 
    pod 'SwiftyUserDefaults', :git => 'https://github.com/radex/SwiftyUserDefaults.git'
    pod 'SwiftMessages’, '~> 4.1.0'
    pod 'AWSMobileClient', '~> 2.6.13'
    pod 'AWSS3', '~> 2.6.13'   # For file transfers
    pod 'AWSCognito', '~> 2.6.13'   #For data sync
    circadian_queries
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
    pod 'Instabug'
    pod 'Firebase/Core'
end

target 'MetabolicCompassWatch Extension' do 
 platform :watchos, '3.0'
 pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git'
 pod 'SwiftyBeaver', :git => 'https://github.com/SwiftyBeaver/SwiftyBeaver.git', :branch => 'master' 
 pod 'AwesomeCache', :git => ‘https://github.com/aschuch/AwesomeCache.git’, :branch => ‘master’
 circadian_queries
end

target 'MetabolicCompassWatch' do
 platform :watchos, '3.0'
 pod 'SwiftDate', :git => 'https://github.com/malcommac/SwiftDate.git' 
 pod 'SwiftyBeaver', :git => 'https://github.com/SwiftyBeaver/SwiftyBeaver.git', :branch => 'master'  
 pod 'AwesomeCache', :git => ‘https://github.com/aschuch/AwesomeCache.git’, :branch => ‘master’
 circadian_queries
end


# Force swift version config

post_install do |installer|
  
    swift4Targets = ['Charts', 'SwiftyBeaver', 'SwiftyBeaver-iOS', 'SwiftyBeaver-watchOS', 'CryptoSwift', 'SwiftDate’, ’SwiftDate-iOS’, ’SwiftDate-watchOS’ , ’SwiftMessages’ , ’FileKit’, ’Pages’, ’Former’, ’AWSMobileClient’, 'AWSCognito', 'AWSS3', 'Dodo']

    installer.pods_project.targets.each do |target|

	target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.2'
     	 end


        if swift4Targets.include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end

        if target.name == ’ResearchKit’
            target.build_configurations.each do |config|
                config.build_settings['GCC_NO_COMMON_BLOCKS'] = 'NO'
            end
        end
    end
end





