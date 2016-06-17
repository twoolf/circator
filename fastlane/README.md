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
### ios setupbb
```
fastlane ios setupbb
```
Install Blackbox for secure git files
### ios start_coding
```
fastlane ios start_coding
```
Start a Metabolic Compass development session
### ios stop_coding
```
fastlane ios stop_coding
```
Stop a Metabolic Compass development session
### ios rename_app
```
fastlane ios rename_app
```
Rename the app, via its app identifier
### ios create_portal_appids
```
fastlane ios create_portal_appids
```
Create bundle identifiers on the Developer Portal
### ios create_itc_appids
```
fastlane ios create_itc_appids
```
Create bundle identifiers on iTunes Connect
### ios certs
```
fastlane ios certs
```
Fastlane/match execution
### ios adhoc_certs
```
fastlane ios adhoc_certs
```
Get Ad Hoc distribution certs
### ios app_certs
```
fastlane ios app_certs
```
Get App Store distribution certs
### ios new_dev_certs
```
fastlane ios new_dev_certs
```
Force new development certificates
### ios new_adhoc_certs
```
fastlane ios new_adhoc_certs
```
Force new adhoc certificates
### ios new_app_certs
```
fastlane ios new_app_certs
```
Force new app certificates
### ios preparebuild
```
fastlane ios preparebuild
```
Command line build preparation
### ios set_codesigning
```
fastlane ios set_codesigning
```
Set XCode project code signing and provisioning
### ios build_version
```
fastlane ios build_version
```
Set a specific build number
### ios build_dev
```
fastlane ios build_dev
```
Build a development archive
### ios build_adhoc
```
fastlane ios build_adhoc
```
Build an adhoc archive
### ios build_app
```
fastlane ios build_app
```
Build a release archive
### ios resign_dev
```
fastlane ios resign_dev
```
Resign a development archive
### ios resign_dev_as_dist
```
fastlane ios resign_dev_as_dist
```
Resign a development archive
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
Build and submit a beta build to Apple TestFlight
### ios beta_fabric
```
fastlane ios beta_fabric
```
Build and submit a beta build to Fabric/Crashlytics
### ios beta
```
fastlane ios beta
```
Build and submit a beta build to Apple TestFlight and Fabric/Crashlytics
### ios beta_srost_fabric
```
fastlane ios beta_srost_fabric
```
Build and submit a beta build to Fabric/Crashlytics

----

This README.md is auto-generated and will be re-generated every time to run [fastlane](https://fastlane.tools).  
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).  
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane).