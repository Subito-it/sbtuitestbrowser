
<img src="https://raw.githubusercontent.com/Subito-it/sbtuitestbrowser/master/Images/screenshot.png" />

If you're [running UI Tests using xcodebuild](https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/08-automation.html) you probably already know how hard it is to pin point an error when it occurs. The number of log information written in the various folder is so large that it's often easier to run the failing test again in Xcode and check from there what went wrong. This process is tedious and time consuming and often doesn't solve the problem because the test might mysteriously pass when manually run in Xcode.

sbtuitestbrowser parses xcodebuild's logs for you presenting them in a simple web interface to help visualize errors faster (some say even better than Xcode).

# Installation

```
brew install Subito-it/made/sbtuitestbrowser
```

Then see [usage](#usage).

Alternatively you can build manually using swift build.

```
git clone https://github.com/Subito-it/sbtuitestbrowser.git
cd sbtuitesttunnel
swift build
open sbtuitestbrowser.xcodeproj
```

Hit run and open your browser at [http://localhost:8090](http://localhost:8090), a very short test sample session will be loaded.

# Usage
To launch sbtuitestbrowser you only need to specify a base path that contains test session logs (typically xcodebuild's `-derivedDataPath`) of your ui tests sessions.

    sbtuitestbrowser [basepath]

This starts a web server reachable at [http://localhost:8090](http://localhost:8090) with a very simple and self explanatory interface.

## Parsing results
When launched the tool will parse all the test session found inside the _basepath_ specified at launch. As your tests sessions get executed and complete you can force the new results to be parsed by making a `GET` request to [http://localhost:8090/parse](http://localhost:8090/parse)

## Merging results
There are scenarios (e.g. when running ui tests in parallarel over multiple machines) where you want different results to be merged together. When parsing all the TestSummaries.plist sbtuitestbrowser will look and group by the `GroupingIdentifier` key, presenting results as it was a single test session.

You can easily set this key after your xcobuild test is completed as follows:

`plutil -insert GroupingIdentifier -string '<GROUPING_IDENTIFIER>' <PATHTOTHETESTSUMMARY.plist>`

## TestSummaries.plist custom keys
Besides the aforementioned `GroupingIdentifier` key there are additional custom keys that are parsed in the TestSummaries.plist.

- `RepoPath`: The path where source code of the project being tested is located.
- `BranchName`: The branch name from where tests were launched. This information will be shown in the test runs homepage.
- `CustomDescription`: A custom text that will be shown in the test runs homepage.
- `CommitHash`: The hash of the commit from where tests were launched. This information will be shown in the test runs homepage.
- `CommitMessage`: The message of the commit from where tests were launched. This information will be shown in the test runs homepage when hovering over a test run.
- `CodeCoverageFile`: The path to the code coverage file to show code coverage information of a particular test run. **Requires `RepoPath` to be set**.
- `DiagnosticReports`: The path to the folder containing crash reports (the logs found under ~/Library/Logs/DiagnosticReports) which will be automatically linked to the test that failed. For those tests a link to the crash report will be added to the test detail

### CodeCoverageFile
This is a JSON file (OUTPUT_FILE.json) that was generated using `xcrun llvm-cov export -instr-profile #{coverage_file}.profdata #{product_path} > #{output_filename}.json`

Where `product_path = "#{derived_data_base}/Build/Products/#{testing_configuration}-iphonesimulator/#{buildable_name}/#{executable_name}"`

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








