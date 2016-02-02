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
### ios build
```
fastlane ios build
```
Build locally from the command line
### ios beta
```
fastlane ios beta
```
Submit a new Beta Build to Apple TestFlight

This will also make sure the profile is up to date
### ios appstore
```
fastlane ios appstore
```
Deploy a new version to the App Store

----

This README.md is auto-generated and will be re-generated every time to run [fastlane](https://fastlane.tools).  
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).  
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane).