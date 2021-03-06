# MetabolicCompass

iOS HealthKit/ResearchKit/WatchKit app for circadian monitoring.

---
## Getting started
We use [fastlane](https://fastlane.tools/) and [match](https://github.com/fastlane/match) to manage and build Metabolic Compass.

### XCode setup
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

### Register new devices
If this is the first time you're using your device (iPhone or watch)

```
fastlane newdevices
```

### Build from XCode or command line
We can build Metabolic Compass either manually from XCode (XCode > Product > Build or Run), or from the command line.

If you are building from XCode, do

```
fastlane preparebuild
```

otherwise run

```
fastlane build
```

That's it... Enjoy!

The Metabolic Compass Team

Contributors: Yanif Ahmad, Tom Woolf, Sihao Lu, Anuj Mendhiratta, Mariano Pennini

Metabolic Compass is available under the Apache 2.0 License (see the LICENSE file)
