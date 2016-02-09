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
### ios betabuild
```
fastlane ios betabuild
```
Build a new Beta release
### ios betaupload
```
fastlane ios betaupload
```
Upload a Beta Build to Apple TestFlight
### ios betauploadfabric
```
fastlane ios betauploadfabric
```
Upload a Beta Build to Fabric/Crashlytics
### ios beta
```
fastlane ios beta
```
Build and submit a new Beta Build to Apple TestFlight
### ios betafabric
```
fastlane ios betafabric
```
Build and submit a new Beta Build to Fabric/Crashlytics

----

This README.md is auto-generated and will be re-generated every time to run [fastlane](https://fastlane.tools).  
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).  
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane).