fastlane documentation
================
# Installation
```
sudo gem install fastlane
```
# Available Actions
## iOS
### ios setupxcode
```
fastlane ios setupxcode
```
Install FixCode for c&p management
### ios setupbb
```
fastlane ios setupbb
```
Install Blackbox for secure git files
### ios cleanderived
```
fastlane ios cleanderived
```
Clean DerivedData
### ios test
```
fastlane ios test
```
Runs all the tests
### ios start_coding
```
fastlane ios start_coding
```
Start a Circator development session
### ios stop_coding
```
fastlane ios stop_coding
```
Stop a Circator development session
### ios newdevices
```
fastlane ios newdevices
```
Ensure all devices are added to the provisioning profile
### ios preparebuild
```
fastlane ios preparebuild
```
Prepare for command line build
### ios preparedeploy
```
fastlane ios preparedeploy
```
Prepare for command line deployment to the App Store
### ios build
```
fastlane ios build
```
Build locally from the command line
### ios beta_build
```
fastlane ios beta_build
```
Build a new Beta release
### ios beta_upload_testflight
```
fastlane ios beta_upload_testflight
```
Upload a Beta Build to Apple TestFlight
### ios beta_upload_fabric
```
fastlane ios beta_upload_fabric
```
Upload a Beta Build to Fabric/Crashlytics
### ios beta_testflight
```
fastlane ios beta_testflight
```
Build and submit a new Beta Build to Apple TestFlight
### ios beta_fabric
```
fastlane ios beta_fabric
```
Build and submit a new Beta Build to Fabric/Crashlytics
### ios beta
```
fastlane ios beta
```
Build and submit a new Beta Build to Apple TestFlight and Fabric/Crashlytics

----

This README.md is auto-generated and will be re-generated every time to run [fastlane](https://fastlane.tools).  
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).  
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane).