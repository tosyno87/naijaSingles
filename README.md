# naijasingles

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Configuration

Sensitive Firebase configuration values are not stored in the repository.
Create a `.env` file in the project root containing the keys used in
`lib/firebase_options.dart`:

```env
ANDROID_API_KEY=<your key>
ANDROID_APP_ID=<your id>
ANDROID_MESSAGING_SENDER_ID=<sender id>
IOS_API_KEY=<your key>
IOS_APP_ID=<your id>
IOS_MESSAGING_SENDER_ID=<sender id>
IOS_BUNDLE_ID=<bundle id>
PROJECT_ID=<project id>
STORAGE_BUCKET=<bucket>
```

The `google-services.json` and `GoogleService-Info.plist` files are required at
`android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`
respectively. They should be provided at build time, for example by injecting
CI secrets:

```bash
echo "$GOOGLE_SERVICES_JSON" > android/app/google-services.json
echo "$IOS_GOOGLE_SERVICE_INFO" > ios/Runner/GoogleService-Info.plist
```

Keep these files out of version control and manage them securely in your local
environment or CI configuration.
