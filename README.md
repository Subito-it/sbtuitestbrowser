
If you're [running UI Tests using xcodebuild](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/08-automation.html)  (or anything that uses it like [fastlane](https://github.com/fastlane/fastlane)'s scan) you probably already know how hard it is to pin point an error when it occurs. The number of log information written in the various folder is so large that it's often easier to run the failing test again in Xcode and check from there what went wrong. This process is tedious and time consuming and often doesn't solve the problem because the test might mysteriously pass when manually run in Xcode.

sbtuitestbrowser parses xcodebuild's logs for you presenting them in a simple web interface to help visualize errors faster (some say even better than Xcode). It is additionally able to display a screencast of the simulator test session that can be synched with the tests steps.

The following demo shows how you can easily browse UI test results from a browser:

<img src="https://raw.githubusercontent.com/Subito-it/sbtuitestbrowser/master/Images/demo.gif" width="480" />

# Cloning
To get source code ready for Xcode you'll need to compile Swift's package dependencies first
```
git clone https://github.com/Subito-it/sbtuitestbrowser.git
cd sbtuitesttunnel
swift build
open sbtuitestbrowser.xcodeproj
```

Hit run and open your browser at [http://localhost:8090](http://localhost:8090), a very short test sample session will be loaded.

# Usage
To launch sbtuitestbrowser you only need to specify a base path that contains test session logs (typically xcodebuild's `-derivedDataPath`) of your ui tests sessions.

    sbtuitestbrowser basepath

This starts a web server reachable at [http://localhost:8090](http://localhost:8090) with a very simple and self explanatory interface.

## Parsing results
When launched the tool will parse all the test session found inside the _basepath_ specified at launch. As your tests sessions get executed and complete you can force the new results to be parsed by making a `GET` request to [http://localhost:8090/parse](http://localhost:8090/parse)

## xcodebuild example
To get the most out of sbtuitestbrowser it's highly recommended to specify a unique `-derivedDataPath` for every test session you run. This will allow to show a complete history of your tests which can be useful to compare tests over time

The following command will launch your tests on an iPhone 6s simulator storing the results to `~/Desktop/iPhone_6s-*CURRENT_UNIXTIMESTAMP*`:

    xcodebuild \
      -project YOURPROJECT.xcodeproj \ *or* -workspace YOURWORKSPACE.xcworkspace \
      -scheme YOURUITESTSCHEME \
      -sdk iphonesimulator \
      -destination 'platform=iOS Simulator,name=iPhone 6s,OS=10.2' \
      -derivedDataPath ~/Desktop/iPhone_6s-$(date +%s) \
      test

## Advanced - Screencasting with sbtuitestscreencaster
> for implementation simplicity the screencaster will work only on a single monitor machine

xcodebuild will by default take a screenshot of every key step in the test execution, and sbtuitestbrowser will show them in the test detail page. Most of the times this works fine however we believe that a video can help even more by providing a context of what happened before and after the test failed. We developed an additional tool, `sbtuitestscreencaster`, that makes recording your simulator ui tests session as simple as it can get.

To use the screencaster you'll need to:

1. Install ffmpeg: `brew install ffmpeg` 
2. In the *Privacy's Accessibility* settings under *Security & Settings* allow Terminal and/or sshd (if you're launching the tests over ssh) to control your machine. This is needed to execute some apple scripts that are invoked by the screencaster

<img src="https://raw.githubusercontent.com/Subito-it/sbtuitestbrowser/master/Images/security-privacy-accessibility.png" width="460" />

3. Copy `sbtuitestscreencaster` to ***/usr/local/bin***

With that in place you simply call `sbtuitestscreencaster start path_to_test_derived_data` before invoking xcodebuild and  `sbtuitestscreencaster stop` afterwards.

For example this bash script runs your UI Test launching the screencast and parses the new results:

    #!/bin/bash        
    DDATA_FOLDER=~/Desktop/iPhone_6s$(date +%s)
    sbtuitestscreencaster start $DDATA_FOLDER
    xcodebuild \
        -project YOURPROJECT.xcodeproj \ *or* -workspace YOURWORKSPACE.xcworkspace \
        -scheme YOURUITESTSCHEME \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 6s,OS=10.2' \
        -derivedDataPath $DDATA_FOLDER \
        test
    sbtuitestscreencaster stop
    wget http://localhost:8090/parse

The disk usage footprint will be ~180MB/hour depending on the size of device you're running your tests  on (iPads may take a little more space than iPhones).

## Why not simctl?
You may ask why we're not using `simctl` to record the video. Answer is that it requires a Metal capable hardware which may not always be the case for continous integration machines (we use an 2012 Mac mini).

# Caveats
Code isn't probably the cleanest I ever wrote but given the usefulness of the tool I decided to publish it nevertheless.

# Thanks
Kudos to the developers of [Perfect-HTTP](https://www.perfect.org), a wonderful web framework/server written in Swift.

# Contributions
Contributions are welcome! If you have a bug to report, feel free to help out by opening a new issue or sending a pull request.

# Authors
[Tomas Camin](https://github.com/tcamin) ([@tomascamin](https://twitter.com/tomascamin))

# License
sbtuitestbrowser is available under the Apache License, Version 2.0. See the LICENSE file for more info.








