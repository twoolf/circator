# circator

iOS HealthKit/ResearchKit/WatchKit app for circadian monitoring.

---
##Getting started
We use [fastlane](https://fastlane.tools/) and [match](https://github.com/fastlane/match) to manage and guild Circator.

###XCode setup
First, set up Xcode's command line tools with:

```
xcode-select --install
```

If you have not used the command line tools before (which is likely if you just installed it), you'll need to accept the terms of service.

```
sudo xcodebuild -license accept
```

### [fastlane](https://github.com/fastlane/fastlane)

You can install fastlane (along with match) with:

```
sudo gem install fastlane --verbose
```

We'll also use the [FixCode Xcode Plugin](https://github.com/neonichu/FixCode) to disable the `Fix Issue` button. This helps to ensure that you do not revoke any of our certificate by mistake.

```
fastlane setupxcode
```

Next, we'll retrieve our code signing and provisioning profiles with:

```
match development --readonly
```

####Build
We can build Circator either manually from XCode, or from the command line.

```
fastlane build
```

That's it... Enjoy!

The Circator Team
Contributors: Yanif Ahmad, Tom Woolf, Sihao Lu, Anuj Mendhiratta, Mariano Pennini
