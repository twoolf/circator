fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

## Choose your installation method:

<table width="100%" >
<tr>
<th width="33%"><a href="http://brew.sh">Homebrew</a></td>
<th width="33%">Installer Script</td>
<th width="33%">Rubygems</td>
</tr>
<tr>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS or Linux with Ruby 2.0.0 or above</td>
</tr>
<tr>
<td width="33%"><code>brew cask install fastlane</code></td>
<td width="33%"><a href="https://download.fastlane.tools">Download the zip file</a>. Then double click on the <code>install</code> script (or run it in a terminal window).</td>
<td width="33%"><code>sudo gem install fastlane -NV</code></td>
</tr>
</table>

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
### ios preparebuild
```
fastlane ios preparebuild
```
Command line build preparation
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

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
