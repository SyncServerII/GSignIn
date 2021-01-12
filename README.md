# XCFramework

My need was to use [GoogleSignIn](https://developers.google.com/identity/sign-in/ios/sdk/) with the Swift Package Manager. And more specifically, I wanted to create a Swift package which itself depends on GoogleSignIn.

GoogleSignIn is designed to be used either directly in an Xcode project -- i.e., by dragging the Google Sign In files into the project, or through the Cocoapods dependency manager. I have been unable to find any Google-provided means to use GoogleSignIn as a dependency for a Swift package, with its own Package.swift manifest file.

It appears the way to achieve this goal is to convert GoogleSignIn to an [XCFramework](https://developer.apple.com/videos/play/wwdc2019/416/). I am using the resulting XCFramework in my [iOSGoogle](https://github/SyncServerII/iOSGoogle.git) package which provides Google Sign In services for [SyncServerII](https://github/SyncServerII) on iOS.

This effort started its life as [SMGoogleSignIn](https://github.com/crspybits/SMGoogleSignIn.git), which was targeted at Cocoapods. The doc section at the bottom titled `SMGoogleSignIn` gives that history.

# TL;DR
If you just want to use this XCFramework and skip all the reading, add this target into your Package.swift. 

```
.binaryTarget(
    name: "GSignIn",
    url: "https://github.com/SyncServerII/GSignIn/blob/main/XCFrameworks/GSignIn.xcframework.5.0.2.zip",
    checksum: "b2b468ca98bcbe7d771726cd2a1ea6f9bee785957af8c9f4c75aa10e5c337a52"
),
```

Note that you must be using at least Swift 5.3 in your Package.swift. E.g., have this at the top of the Package.swift:

```
// swift-tools-version:5.3
```

# Generating the checksum used above

You need to run the `swift package compute-checksum` command ([see this reference](https://developer.apple.com/documentation/swift_packages/distributing_binary_frameworks_as_swift_packages) from a directory containing a Package.swift file ([see this reference](https://developer.apple.com/forums/thread/655951)). This is why the `FakePackage` directory is present. Generate a zip file with the XCFramework, copy or move it into the FakePackage directory and from the root directoy (containing this README.md) run: 

```
swift package --package-path FakeExample compute-checksum FakeExample/GSignIn.xcframework.zip
```

# GSignIn

I have renamed this repo `GSignIn` to distinguish it from `SMGoogleSignIn` (for Cocoapods) and `GoogleSignIn`-- Google's library.

## Creating the XCFramework

My creation of the XCFramework is adapted from https://medium.com/@er.mayursharma14/how-to-create-xcframework-855817f854cf

### Set some variables in a terminal window

In a terminal window, within the GSignIn repo folder, run:
```
FRAMEWORK_NAME=GSignIn
SIMULATOR_ARCHIVE_PATH=GSignIn.Simulator.xcarchive
IOS_DEVICE_ARCHIVE_PATH=GSignIn.iOS.xcarchive
```

### Create frameworks for GSignIn for iOS and the iOS Simulator

Next, in the same terminal window, run:
```
xcodebuild archive -scheme ${FRAMEWORK_NAME} -destination="iOS Simulator" -archivePath "${SIMULATOR_ARCHIVE_PATH}" -sdk iphonesimulator SKIP_INSTALL=NO SUPPORTS_MACCATALYST=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
```

and then run:
```
xcodebuild archive -scheme ${FRAMEWORK_NAME} -destination="iOS" -archivePath "${IOS_DEVICE_ARCHIVE_PATH}" -sdk iphoneos SKIP_INSTALL=NO SUPPORTS_MACCATALYST=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
```

Make sure that both of those run without errors. 

### Create the XCFramework for use in the Swift Package Manager

Next, in the same terminal window, run:

```
xcodebuild -create-xcframework -framework ${SIMULATOR_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -framework ${IOS_DEVICE_ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework -output "${FRAMEWORK_NAME}".xcframework
```

### Cleanup

Finally, run this in the same terminal window:

```
rm -rf "${SIMULATOR_ARCHIVE_PATH}"
rm -rf "${IOS_DEVICE_ARCHIVE_PATH}"
```

## Using the XCFramework

You can now now copy the folder `GSignIn.xcframework` in to your Swift package. To reference it you need to add something like the following in your `Package.swift` file:

```
.binaryTarget(
    name: "GSignIn",
    path: "Frameworks/GSignIn.xcframework"
),
```

I had put the XCFramework into a folder called `Frameworks`. See also  the usage in [iOSGoogle](https://github/SyncServerII/iOSGoogle.git).

In your code, you then add:

```
import GSignIn
```

and you can use Google's Sign In library like you normally would.

## Known current issues

I am currently unable to access the embedded .bundle that Google provides in their Google Sign In. Specifically, their `GIDSignInButton` when rendered in iOS doesn't have graphic assets. In  [iOSGoogle](https://github/SyncServerII/iOSGoogle.git) I work around this by creating my own button. See `GoogleSignInOutButton` in that package.

See also my writeup on this at https://stackoverflow.com/questions/65469685/using-google-sign-in-for-ios-with-swift-package-manager/65469686#65469686

## Development problem 1

I was having errors on 12/15/20 when building for simulator; see https://stackoverflow.com/questions/63607158. I had to make some changes to the GSignIn.xcodeproj used for this-- by adding settings into `Excluded Architecture`.

## Development problem 2

I ran into this problem building on the simulator (not an actual device) when integrating the xcframework into my iOSGoogle package:

```
CodeSign /Users/chris/Library/Developer/Xcode/DerivedData/iOSGoogle-cjpcgggznffoaybhhrtzqzkxayww/Build/Products/Debug-iphonesimulator/iOSGoogle_iOSGoogle.bundle (in target 'iOSGoogle_iOSGoogle' from project 'iOSGoogle')
    cd /Users/chris/Desktop/NewSyncServer/iOSGoogle
    export CODESIGN_ALLOCATE\=/Users/chris/Desktop/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate
    
Signing Identity:     "-"

    /usr/bin/codesign --force --sign - --timestamp\=none /Users/chris/Library/Developer/Xcode/DerivedData/iOSGoogle-cjpcgggznffoaybhhrtzqzkxayww/Build/Products/Debug-iphonesimulator/iOSGoogle_iOSGoogle.bundle

/Users/chris/Library/Developer/Xcode/DerivedData/iOSGoogle-cjpcgggznffoaybhhrtzqzkxayww/Build/Products/Debug-iphonesimulator/iOSGoogle_iOSGoogle.bundle: bundle format unrecognized, invalid, or unsuitable
Command CodeSign failed with a nonzero exit code
```

Two references on this issue:
https://stackoverflow.com/questions/58195914/xcode-11-command-codesign-failed-with-a-nonzero-exit-code

https://stackoverflow.com/questions/52421999 

The solution: Don't give a directory in your Swift package the name `Resources`. Very odd.

## Development problem 3
As I wrote up  at https://stackoverflow.com/questions/65469685 on 12/28/20 and 12/29/20, I had been getting linker warnings and errors. That solutions I wrote up on the same SO post on 1/1/21.

# SMGoogleSignIn

(For reference, from  [SMGoogleSignIn](https://github.com/crspybits/SMGoogleSignIn.git)).

Since [SyncServer](https://github.com/crspybits/SyncServer-iOSClient) is a framework, I wanted a means to provide Google Sign In for iOS clients so that they didn't have to explicitly import GoogleSignIn. That is, I wanted to do this just like the way I'm doing this with Facebook and Dropbox: Just select the subspec in your Cocoapods Podfile and you are off to the races. However, Google Sign In doesn't make this easy-- at this time (early June 2018), Google provides static libraries. Well, you say, Cocoapods can now support [static vendored_libraries](https://guides.cocoapods.org/syntax/podspec.html#static_framework). Yea! Hmmm. I tried doing this. I get a gnarly error: "unsealed contents present in the bundle root" from Xcode. I wasn't able to make progress with that issue.

Instead, I took the route of converting the Google Sign In framework to a dynamic framework using [these instructions](https://pewpewthespells.com/blog/convert_static_to_dynamic.html)

This repo is the result of that process.

## Build process: Build from `GoogleSignIn.xcodeproj`

GoogleSignIn.xcodeproj is not part of the Cocoapod, but rather enables you to build the dynamic GoogleSignIn.framework

See https://stackoverflow.com/questions/5010062/xcodebuild-simulator-or-device and https://stackoverflow.com/questions/29634466/how-to-export-fat-cocoa-touch-framework-for-simulator-and-device

### To update the version of the Google SDK and update the project

1) Download the most recent version of the Google SDK from https://developers.google.com/identity/sign-in/ios/sdk/
2) In the downloaded folder, you should see three main file/folders: GoogleSignIn.bundle, GoogleSignIn.framework, GoogleSignInDependencies.framework
3) Rename the downloaded folder to "google_signin_sdk" (it should have been named something like "google_signin_sdk_4_4_0").
4) Replace that named folder in the repo with the new "google_signin_sdk".
5) I had to rename the file within the GoogleSignIn.framework/Headers/GoogleSignIn.h  obtained from Google to GoogleSignIn.framework/Headers/GoogleSignInAll.h to work around a naming conflict.
6) Note that the names of the header files in google_signin_sdk/GoogleSignIn.framework/Headers might have changed, and you might have to adjust these in GoogleSignIn.xcodeproj
7) Make sure the headers for the library are all public:
![Public Headers](./docs/publicHeaders.png)
8) Read through the section `Link dependent frameworks to your Xcode project` in https://developers.google.com/identity/sign-in/ios/sdk/ to see if you need to add other (more) libraries. (I ran into some odd looking link issues when I didn't remember this).

```
xcodebuild -target GoogleSignIn -configuration Release -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="build" BUILD_ROOT="build" clean build
```

The following builds for arm64 and armv7

I had to add -fembed-bitcode to OTHER_CFLAGS in the project build settings because I got "ld: bitcode bundle could not be generated" when I tried to build SharedImages. I also added this to the linker flags.

And I'm now making release builds because that seems to be the way to generate bitcode. See https://stackoverflow.com/questions/31233395/ios-library-to-bitcode

```
xcodebuild -target GoogleSignIn -configuration Release -sdk iphoneos ONLY_ACTIVE_ARCH=NO BUILD_DIR="build" BUILD_ROOT="build" clean build
```

Copy the framework structure (from iphoneos build) to the universal folder-- the lipo step only builds the executable, not the framework structure. Note that `trash` is just a command to move to the directory to the Trash folder.

```
trash Framework/GoogleSignIn.framework

cp -R "build/Release-iphoneos/GoogleSignIn.framework" "Framework/GoogleSignIn.framework"
```

Note we're replacing the non-fat binary in the step above with the fat binary.

```
lipo -create -output "Framework/GoogleSignIn.framework/GoogleSignIn" "build/Release-iphonesimulator/GoogleSignIn.framework/GoogleSignIn" "build/Release-iphoneos/GoogleSignIn.framework/GoogleSignIn"
```

Note that the name of the resulting framework must be `GoogleSignIn`-- i.e., it must match the name of the .bundle file-- or the graphics and text will not load into the Google Sign In button.

## Podspec Note

One of my struggles in developing this dynamic version of Google's framework was getting the GoogleSignIn.bundle to be properly accessed by the framework. The problem was that I was getting the GIDGoogleSignIn button appearing on the UI, but the graphics and text didn't appear-- and these come from the .bundle file. To deal with this, I have derived the form of the podspec I'm using here from Google's-- https://github.com/CocoaPods/Specs/blob/master/Specs/d/4/0/GoogleSignIn/4.1.2/GoogleSignIn.podspec.json (see also "See Podspec" link in https://cocoapods.org/pods/GoogleSignIn). See also https://stackoverflow.com/questions/50750862/using-google-sign-in-frameworks-in-a-cocoapod-subspec

