fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### test_suite

```sh
[bundle exec] fastlane test_suite
```

Run comprehensive test suite for African diaspora dating app

### screenshots

```sh
[bundle exec] fastlane screenshots
```

Generate screenshots for App Store

### testflight_feedback

```sh
[bundle exec] fastlane testflight_feedback
```

Fetch recent TestFlight feedback for NaijaSingles from App Store Connect

### beta

```sh
[bundle exec] fastlane beta
```

Deploy to beta testing (TestFlight + Internal Testing)

### ios_deploy_testflight

```sh
[bundle exec] fastlane ios_deploy_testflight
```

Deploy to iOS TestFlight (iPhone only)

### android_internal_testing

```sh
[bundle exec] fastlane android_internal_testing
```

Deploy to Google Play Internal Testing

### deploy

```sh
[bundle exec] fastlane deploy
```

Full deployment to production stores

### ios_deploy

```sh
[bundle exec] fastlane ios_deploy
```

Deploy to iOS App Store (iPhone only)

### android_deploy

```sh
[bundle exec] fastlane android_deploy
```

Deploy to Google Play Store

### android_only

```sh
[bundle exec] fastlane android_only
```

Deploy Android only (when iOS has CodeSign issues)

----


## iOS

### ios build_app

```sh
[bundle exec] fastlane ios build_app
```

Build iOS app for CI/CD

### ios testflight_deploy

```sh
[bundle exec] fastlane ios testflight_deploy
```

Deploy to iOS TestFlight (iPhone only)

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy to iOS App Store (iPhone only)

----


## Android

### android internal

```sh
[bundle exec] fastlane android internal
```

Deploy to Google Play Internal Testing

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Deploy to Google Play Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
