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

### beta

```sh
[bundle exec] fastlane beta
```

Deploy to beta testing (TestFlight + Internal Testing)

### deploy

```sh
[bundle exec] fastlane deploy
```

Full deployment to production stores

----


## iOS

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy to App Store Connect

### ios deploy_testflight

```sh
[bundle exec] fastlane ios deploy_testflight
```

Build and upload to TestFlight

----


## Android

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Deploy to Google Play Store

### android internal_testing

```sh
[bundle exec] fastlane android internal_testing
```

Deploy to Google Play Internal Testing

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
